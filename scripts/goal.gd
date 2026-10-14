extends Area2D
# Attach to an Area2D with a CollisionShape2D. Set Next Level in the Inspector.
# Leave Next Level empty on the last level to show the win screen.

@export_file("*.tscn") var next_level: String = ""

@onready var light: PointLight2D = get_node_or_null("DoorLight")  # optional glow, pulses gently
@onready var door: Sprite2D = get_node_or_null("goal")

var triggered: bool = false
var _t: float = 0.0
var _base_energy: float = 1.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if light:
		_base_energy = light.energy


func _process(delta: float) -> void:
	if light and not triggered:  # the flare tween owns the light once the door is reached
		_t += delta
		light.energy = _base_energy + 0.18 * sin(_t * 2.4) + 0.06 * sin(_t * 9.1)


func _on_body_entered(body: Node2D) -> void:
	if triggered or not body.is_in_group("player"):
		return
	triggered = true
	Audio.play_sfx("goal")
	_flare()
	await get_tree().create_timer(0.35).timeout  # let the flare read before the level changes
	if next_level == "":
		Game.win()
	else:
		Game.change_level(next_level)


# Door reached: the light blooms and the door pops, so arriving feels like a reward
func _flare() -> void:
	var t := create_tween().set_parallel()
	if light:
		t.tween_property(light, "energy", light.energy * 3.0, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		t.tween_property(light, "texture_scale", light.texture_scale * 1.8, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if door:
		var base := door.scale
		t.tween_property(door, "scale", base * 1.25, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.chain().tween_property(door, "scale", base, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
