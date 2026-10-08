extends Area2D
# Attach to an Area2D with a CollisionShape2D. Set Next Level in the Inspector.
# Leave Next Level empty on the last level to show the win screen.

@export_file("*.tscn") var next_level: String = ""

@onready var light: PointLight2D = get_node_or_null("DoorLight")  # optional glow, pulses gently

var triggered: bool = false
var _t: float = 0.0
var _base_energy: float = 1.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if light:
		_base_energy = light.energy


func _process(delta: float) -> void:
	if light:
		_t += delta
		light.energy = _base_energy + 0.18 * sin(_t * 2.4) + 0.06 * sin(_t * 9.1)


func _on_body_entered(body: Node2D) -> void:
	if triggered or not body.is_in_group("player"):
		return
	triggered = true
	Audio.play_sfx("goal")
	if next_level == "":
		Game.win()
	else:
		get_tree().call_deferred("change_scene_to_file", next_level)
