extends Control
# Shown after the last level's door. Run stats come from Hud (time) and Game (deaths, lives).

@onready var ui_root: Control = $UI/Root
@onready var time_value: Label = $UI/Root/Stats/Grid/TimeValue
@onready var deaths_value: Label = $UI/Root/Stats/Grid/DeathsValue
@onready var lives_value: Label = $UI/Root/Stats/Grid/LivesValue
@onready var play_again: Button = $UI/Root/Buttons/play_again
@onready var sun: PointLight2D = $ExitLight

var _t: float = 0.0


func _ready() -> void:
	var total := int(Hud.elapsed)
	time_value.text = "%02d:%02d" % [total / 60, total % 60]
	deaths_value.text = str(Game.deaths)
	lives_value.text = "%d / %d" % [Game.lives, Game.MAX_LIVES]
	play_again.grab_focus()
	ui_root.modulate.a = 0.0
	var t := create_tween()
	t.tween_interval(0.4)
	t.tween_property(ui_root, "modulate:a", 1.0, 1.0)


func _process(delta: float) -> void:
	_t += delta
	sun.energy = 1.2 + 0.1 * sin(_t * 1.7)


func _on_play_again_pressed() -> void:
	Game.start_run()

func _on_main_menu_pressed() -> void:
	Game.to_main_menu()
