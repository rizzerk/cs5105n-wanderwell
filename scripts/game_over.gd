extends Control
# Shown when the last lantern goes out. Retry restarts the same level with full lives.

@onready var ui_root: Control = $UI/Root
@onready var level_label: Label = $UI/Root/LevelLabel
@onready var retry_button: Button = $UI/Root/Buttons/retry
@onready var ember: PointLight2D = $Hero/Ember

var _t: float = 0.0


func _ready() -> void:
	var index := Game.level_index(Game.retry_level)
	if index >= 0:
		level_label.text = "Level %d - %s" % [index + 1, Game.LEVELS[index].name]
	retry_button.grab_focus()
	ui_root.modulate.a = 0.0
	create_tween().tween_property(ui_root, "modulate:a", 1.0, 1.0)


func _process(delta: float) -> void:
	_t += delta
	# the lantern's last ember, sputtering
	ember.energy = maxf(0.0, 0.45 + 0.25 * sin(_t * 3.1) + 0.2 * sin(_t * 11.7))


func _on_retry_pressed() -> void:
	Game.retry()

func _on_main_menu_pressed() -> void:
	Game.to_main_menu()
