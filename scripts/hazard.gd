extends Area2D
# Attach to an Area2D with a CollisionShape2D. Use for spikes and for a kill zone under pits.

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.hurt()
