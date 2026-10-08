extends CanvasLayer

@onready var panel: Control = $Control

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		print("escape pressed")
		if not panel.visible and not Hud.running:
			return  # only pause during a level, not on menus / win / game over screens
		_toggle()

func _toggle() -> void:
	panel.visible = not panel.visible
	get_tree().paused = panel.visible

func _on_resume_pressed() -> void:
	_toggle()

func _on_restart_level_pressed() -> void:
	get_tree().paused = false
	panel.visible = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	panel.visible = false
	Game.to_main_menu()

func _on_quit_pressed() -> void:
	get_tree().quit()
