extends Node2D
# Big character for the menu screens. Plays an idle loop and every few seconds does a
# little hop. Needs a child AnimatedSprite2D named "Sprite" using player_frames.tres.

@export var rest_animation: StringName = &"idle"
@export var hop_every: float = 6.5  # 0 = never hop
@export var hop_height: float = 70.0

@onready var sprite: AnimatedSprite2D = $Sprite

var _base_y: float


func _ready() -> void:
	_base_y = position.y
	sprite.play(rest_animation)
	if hop_every > 0.0:
		var timer := Timer.new()
		timer.wait_time = hop_every
		timer.autostart = true
		timer.timeout.connect(_hop)
		add_child(timer)


func _hop() -> void:
	sprite.play("jump_start")
	await sprite.animation_finished
	sprite.play("jump_rise")
	var t := create_tween()
	t.tween_property(self, "position:y", _base_y - hop_height, 0.32).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(sprite.play.bind(&"jump_apex"))
	t.tween_interval(0.08)
	t.tween_callback(sprite.play.bind(&"fall"))
	t.tween_property(self, "position:y", _base_y, 0.28).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await t.finished
	sprite.play("land")
	await sprite.animation_finished
	sprite.play(rest_animation)
