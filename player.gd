extends CharacterBody2D

# --- Tweakable physics values ---
@export var speed: float = 300.0
@export var jump_velocity: float = -420.0
@export var gravity: float = 1200.0
@export var coyote_time: float = 0.12       # seconds you can still jump after leaving a ledge

# --- Juice tuning ---
@export var squash_amount: Vector2 = Vector2(1.25, 0.75)  # x-stretch, y-squash on landing
@export var squash_recover_speed: float = 8.0

@onready var sprite: Node2D = $Sprite2D  # swap for AnimatedSprite2D if you use one

var coyote_timer: float = 0.0
var was_on_floor: bool = false
var base_scale: Vector2 = Vector2.ONE  # whatever scale you set on the Sprite2D in the editor

func _ready() -> void:
	base_scale = sprite.scale  # remember your authored size, don't assume (1,1)

func _physics_process(delta: float) -> void:
	# --- Gravity ---
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	# --- Coyote time bookkeeping ---
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	# --- Horizontal movement (core mechanic) ---
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed

	# --- Jump ---
	if Input.is_action_just_pressed("jump") and coyote_timer > 0.0:
		velocity.y = jump_velocity
		coyote_timer = 0.0  # prevent double-jumping off the same coyote window

	# --- Landing juice: squash-and-stretch ---
	if is_on_floor() and not was_on_floor:
		_play_land_squash()
	was_on_floor = is_on_floor()

	move_and_slide()

	# Smoothly recover sprite scale back to YOUR base scale, not (1,1)
	sprite.scale = sprite.scale.lerp(base_scale, squash_recover_speed * delta)

	# Simple facing flip — preserve magnitude of base_scale, just flip the sign
	if direction != 0:
		sprite.scale.x = abs(sprite.scale.x) * sign(direction)

func _play_land_squash() -> void:
	sprite.scale = base_scale * squash_amount
