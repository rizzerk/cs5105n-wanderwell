extends Control

func _on_start_pressed() -> void:
	print("start pressed")
	get_tree().change_scene_to_file("res://levels/level_1.tscn")

func _on_controls_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/controls_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
