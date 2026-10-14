extends Node
# Autoload as "Game". Run state that outlives a single level: the level list, lives, deaths.
# Also saves the run to disk (Continue on the main menu) and preloads the next level.

signal lives_changed(lives: int)

const MAX_LIVES := 5
const LEVELS := [
	{"path": "res://levels/level_1.tscn", "name": "First Light"},
	{"path": "res://levels/level_2.tscn", "name": "Spike Hollow"},
	{"path": "res://levels/level_3.tscn", "name": "Crystal Drop"},
	{"path": "res://levels/level_4.tscn", "name": "The Climb"},
	{"path": "res://levels/level_5.tscn", "name": "Switchback"},
	{"path": "res://levels/level_6.tscn", "name": "Something Below"},
	{"path": "res://levels/level_7.tscn", "name": "The Shade Warren"},
]
const MAIN_MENU := "res://scenes/main_menu.tscn"
const WIN_SCREEN := "res://scenes/win_screen.tscn"
const GAME_OVER := "res://scenes/game_over.tscn"
const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1

var lives: int = MAX_LIVES
var deaths: int = 0
var retry_level: String = LEVELS[0].path  # level to reload from the game over screen
var saved: Dictionary = {}  # the run on disk, {} if there isn't one (see load_save)


func _ready() -> void:
	load_save()
	get_tree().scene_changed.connect(_on_scene_changed)


# Closing the window (or Cmd+Q) still saves the time played on the current level
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_progress()


# Index into LEVELS for a scene path, or -1 if it isn't a level (menus, win screen...)
func level_index(path: String) -> int:
	for i in LEVELS.size():
		if LEVELS[i].path == path:
			return i
	return -1


func start_run() -> void:
	lives = MAX_LIVES
	deaths = 0
	Hud.reset_timer()
	lives_changed.emit(lives)
	change_level(LEVELS[0].path)


# Main menu → Continue: restore the saved run at the start of its level
func continue_run() -> void:
	if not has_save():
		return
	lives = saved.lives
	deaths = saved.deaths
	Hud.elapsed = saved.time
	lives_changed.emit(lives)
	change_level(LEVELS[saved.level].path)


# Called by the player when hurt. Returns true if that was the last life.
func lose_life() -> bool:
	lives = maxi(lives - 1, 0)
	deaths += 1
	lives_changed.emit(lives)
	if lives > 0:
		save_progress()  # quitting mid-level can't be used to get lives back
	return lives == 0


func game_over() -> void:
	retry_level = get_tree().current_scene.scene_file_path
	# Retry gives full lives, so Continue after quitting here does the same
	_write_save(level_index(retry_level), MAX_LIVES)
	get_tree().change_scene_to_file.call_deferred(GAME_OVER)


# Game over → try the same level again with a full set of lives
func retry() -> void:
	lives = MAX_LIVES
	lives_changed.emit(lives)
	change_level(retry_level)


func win() -> void:
	delete_save()  # the run is finished, nothing left to continue
	get_tree().change_scene_to_file.call_deferred(WIN_SCREEN)


func to_main_menu() -> void:
	save_progress()
	get_tree().change_scene_to_file(MAIN_MENU)


func quit() -> void:
	save_progress()
	get_tree().quit()


# --- Level loading ---------------------------------------------------------------------
# Profiling showed the only real frame spikes were level changes: change_scene_to_file
# loads the level on the main thread (up to ~80 ms, about 5 dropped frames at 60 Hz).
# So the next level is loaded on a background thread while the current one is played,
# and the switch only has to instance it.

func preload_level(path: String) -> void:
	path = _to_res_path(path)
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		ResourceLoader.load_threaded_request(path)


func change_level(path: String) -> void:
	path = _to_res_path(path)
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		get_tree().change_scene_to_file.call_deferred(path)  # wasn't preloaded
		return
	# blocks only if the background load hasn't finished yet
	var packed := ResourceLoader.load_threaded_get(path) as PackedScene
	get_tree().change_scene_to_packed.call_deferred(packed)


# goal.gd stores next_level as a uid:// string, LEVELS uses res:// paths
func _to_res_path(path: String) -> String:
	return ResourceUID.ensure_path(path) if path.begins_with("uid://") else path


func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	var index := level_index(scene.scene_file_path) if scene else -1
	if index < 0:
		return
	save_progress()
	Hud.show_saved()
	if index + 1 < LEVELS.size():
		preload_level(LEVELS[index + 1].path)


# --- Save / load -----------------------------------------------------------------------
# One JSON file in user:// (on macOS: ~/Library/Application Support/Godot/app_userdata/Wanderwell/).
# It holds the run in progress: which level, lives, deaths and time so far.
# Continue restarts that level from its start marker.

func has_save() -> bool:
	return not saved.is_empty()


# Saves the current run if a level is loaded (does nothing on menus)
func save_progress() -> void:
	var scene := get_tree().current_scene
	var index := level_index(scene.scene_file_path) if scene else -1
	if index >= 0:
		_write_save(index, lives)


func _write_save(index: int, save_lives: int) -> void:
	saved = {
		"version": SAVE_VERSION,
		"level": index,
		"lives": save_lives,
		"deaths": deaths,
		"time": Hud.elapsed,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(saved, "\t"))


func load_save() -> void:
	saved = {}
	if not FileAccess.file_exists(SAVE_PATH):
		return  # first launch, or the last run was finished
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	# a hand-edited or broken file is ignored instead of crashing the menu
	if typeof(data) != TYPE_DICTIONARY or int(data.get("version", 0)) != SAVE_VERSION:
		push_warning("Ignoring unreadable save file")
		return
	var index := int(data.get("level", -1))
	if index < 0 or index >= LEVELS.size():
		return
	saved = {
		"level": index,
		"lives": clampi(int(data.get("lives", MAX_LIVES)), 1, MAX_LIVES),
		"deaths": maxi(int(data.get("deaths", 0)), 0),
		"time": maxf(float(data.get("time", 0.0)), 0.0),
	}


func delete_save() -> void:
	saved = {}
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
