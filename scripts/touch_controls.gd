extends CanvasLayer
# Autoload as "TouchControls". On-screen buttons for phones / tablets (Week 8 platform tweak).
# Each TouchScreenButton sends the same Input Map action as the keyboard, so player.gd and
# pause_menu.gd don't need to know about touch at all.
# The buttons use "TouchScreen Only" visibility: they never show on a desktop without a touchscreen.


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	_on_scene_changed.call_deferred()  # covers running a level straight from the editor


# Only during a level, like the HUD
func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	visible = scene != null and Game.level_index(scene.scene_file_path) >= 0
