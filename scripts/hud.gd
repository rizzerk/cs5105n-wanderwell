extends CanvasLayer
# Autoload as "Hud". While a level is loaded: level name, lanterns (lives) and run timer,
# plus a title card when a new level starts. Hidden on menus.

@onready var level_label: Label = $TopBar/HBox/LevelLabel
@onready var lives: Control = $TopBar/HBox/Lives
@onready var time_label: Label = $TopBar/HBox/TimeLabel
@onready var title_card: Control = $TitleCard
@onready var card_number: Label = $TitleCard/VBox/Number
@onready var card_name: Label = $TitleCard/VBox/Name

var elapsed: float = 0.0
var running: bool = false  # only counts while a level is loaded
var _card_level: int = -1
var _card_tween: Tween


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	Game.lives_changed.connect(lives.set_lives)
	_on_scene_changed.call_deferred()  # covers running a level straight from the editor


func _process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	var m := int(elapsed) / 60
	var s := int(elapsed) % 60
	time_label.text = "%02d:%02d" % [m, s]


func reset_timer() -> void:
	elapsed = 0.0


func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	var index: int = Game.level_index(scene.scene_file_path) if scene else -1
	running = index >= 0
	visible = running
	if not running:
		_card_level = -1
		return
	level_label.text = "LEVEL %d/%d - %s" % [index + 1, Game.LEVELS.size(), Game.LEVELS[index].name.to_upper()]
	lives.set_lives(Game.lives, false)
	if index != _card_level:  # not on a restart of the same level
		_card_level = index
		_show_title_card(index)


func _show_title_card(index: int) -> void:
	card_number.text = "LEVEL %d" % (index + 1)
	card_name.text = Game.LEVELS[index].name
	if _card_tween:
		_card_tween.kill()
	title_card.modulate.a = 0.0
	_card_tween = create_tween()
	_card_tween.tween_property(title_card, "modulate:a", 1.0, 0.5)
	_card_tween.tween_interval(1.4)
	_card_tween.tween_property(title_card, "modulate:a", 0.0, 0.8)
