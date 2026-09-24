extends Area2D
# Attach to an Area2D with a CollisionShape2D. Set Next Level in the Inspector.

@export_file("*.tscn") var next_level: String = ""

var triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if triggered or not body.is_in_group("player"):
		return
	triggered = true
	if next_level == "":
		print("You win!")  # last level: show a win screen here
	else:
		get_tree().call_deferred("change_scene_to_file", next_level)
