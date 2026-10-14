extends Control

@onready var start_button: Button = $UI/Root/Buttons/start
@onready var continue_button: Button = $UI/Root/Buttons/continue
@onready var ui_root: Control = $UI/Root
@onready var lamp_light: PointLight2D = $LampLight
@onready var shade: AnimatedSprite2D = $Shade

var _t: float = 0.0
var _shade_home: Vector2


func _ready() -> void:
	_shade_home = shade.position
	shade.play("idle")
	# Continue only shows when there's a saved run; it's then the default choice
	continue_button.visible = Game.has_save()
	if Game.has_save():
		var index: int = Game.saved.level
		continue_button.text = "Continue - Level %d" % (index + 1)
		start_button.text = "New Game"
		Game.preload_level(Game.LEVELS[index].path)
		continue_button.grab_focus()  # keyboard / controller can pick a button right away
	else:
		start_button.grab_focus()
	Game.preload_level(Game.LEVELS[0].path)
	ui_root.modulate.a = 0.0
	create_tween().tween_property(ui_root, "modulate:a", 1.0, 1.2)


func _process(delta: float) -> void:
	_t += delta
	lamp_light.energy = 1.0 + 0.06 * sin(_t * 6.0) + 0.04 * sin(_t * 13.0)
	# a Shade drifting about in the dark behind her
	shade.position = _shade_home + Vector2(sin(_t * 0.35) * 70.0, sin(_t * 1.1) * 12.0)
	shade.flip_h = cos(_t * 0.35) < 0.0


func _on_continue_pressed() -> void:
	Game.continue_run()

func _on_start_pressed() -> void:
	Game.start_run()

func _on_controls_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/controls_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
