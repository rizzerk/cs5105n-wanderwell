extends Node
# Autoload as "Game". Run state that outlives a single level: the level list, lives, deaths.

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

var lives: int = MAX_LIVES
var deaths: int = 0
var retry_level: String = LEVELS[0].path  # level to reload from the game over screen


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
	get_tree().change_scene_to_file(LEVELS[0].path)


# Called by the player when hurt. Returns true if that was the last life.
func lose_life() -> bool:
	lives = maxi(lives - 1, 0)
	deaths += 1
	lives_changed.emit(lives)
	return lives == 0


func game_over() -> void:
	retry_level = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file.call_deferred(GAME_OVER)


# Game over → try the same level again with a full set of lives
func retry() -> void:
	lives = MAX_LIVES
	lives_changed.emit(lives)
	get_tree().change_scene_to_file(retry_level)


func win() -> void:
	get_tree().change_scene_to_file.call_deferred(WIN_SCREEN)


func to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)
