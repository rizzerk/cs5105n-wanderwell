extends CharacterBody2D
# Requires: AnimatedSprite2D (player_frames.tres) and a CollisionShape2D using a RectangleShape2D.
# Input Map actions needed: move_left, move_right, jump, crouch

# --- Physics (kept from Week 2) ---
@export var speed: float = 300.0
@export var jump_velocity: float = -420.0
@export var gravity: float = 1200.0
@export var coyote_time: float = 0.12

# --- Crouch ---
@export var crouch_speed_scale: float = 0.4
@export var crouch_height: float = 36.0  # collision height while crouched (standing is set in the editor)

# --- Juice ---
@export var squash_amount: Vector2 = Vector2(1.1, 0.9)  # the land animation already squashes, so keep this mild
@export var squash_recover_speed: float = 8.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var light: Node2D = get_node_or_null("AnimatedSprite2D/PointLight2D")  # optional lantern light

var shape: RectangleShape2D
var stand_size: Vector2
var stand_pos: Vector2
var crouch_size: Vector2
var crouch_pos: Vector2

var coyote_timer: float = 0.0
var was_on_floor: bool = false
var facing: float = 1.0
var base_scale: Vector2 = Vector2.ONE
var landing: bool = false
var crouching: bool = false
var dead: bool = false
var respawn_point: Vector2


func _ready() -> void:
	add_to_group("player")
	base_scale = sprite.scale
	respawn_point = global_position

	# Own copy of the shape so crouching never changes the saved scene resource
	shape = collider.shape.duplicate() as RectangleShape2D
	assert(shape != null, "Player CollisionShape2D must use a RectangleShape2D")
	collider.shape = shape
	stand_size = shape.size
	stand_pos = collider.position
	crouch_size = Vector2(stand_size.x, crouch_height)
	# keep the feet where they are: bottom edge stays put
	crouch_pos = Vector2(stand_pos.x, stand_pos.y + stand_size.y / 2.0 - crouch_height / 2.0)

	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	if dead:
		return

	# --- Gravity ---
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	# --- Coyote time ---
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	# --- Crouch (only on the floor; stays crouched if a ceiling is above) ---
	var want_crouch := Input.is_action_pressed("crouch") and is_on_floor()
	if want_crouch and not crouching:
		_set_crouch(true)
	elif crouching and not want_crouch and _can_stand():
		_set_crouch(false)

	# --- Horizontal movement ---
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed * (crouch_speed_scale if crouching else 1.0)
	if direction != 0:
		facing = sign(direction)
		sprite.flip_h = facing < 0
		if light:
			light.position.x = abs(light.position.x) * facing  # keep the light on the lantern side

	# --- Jump ---
	if Input.is_action_just_pressed("jump") and coyote_timer > 0.0 and not crouching:
		velocity.y = jump_velocity
		coyote_timer = 0.0
		landing = false
		_play("jump_start")

	# --- Landing ---
	if is_on_floor() and not was_on_floor:
		landing = true
		_play("land")
		sprite.scale = base_scale * squash_amount
	was_on_floor = is_on_floor()

	move_and_slide()

	sprite.scale = sprite.scale.lerp(base_scale, squash_recover_speed * delta)
	_update_animation(direction)


func _set_crouch(value: bool) -> void:
	crouching = value
	shape.size = crouch_size if value else stand_size
	collider.position = crouch_pos if value else stand_pos


func _can_stand() -> bool:
	# true if moving up by the height difference hits nothing
	return not test_move(global_transform, Vector2(0.0, -(stand_size.y - crouch_size.y)))


func _update_animation(direction: float) -> void:
	if crouching and is_on_floor():
		if direction != 0.0:
			_play("crouch_walk")
		elif sprite.animation != "crouch_down" and sprite.animation != "crouch_idle":
			_play("crouch_down")
		return

	if not is_on_floor():
		landing = false
		if sprite.animation == "jump_start" and sprite.is_playing() and velocity.y < 0.0:
			return
		if velocity.y < -120.0:
			_play("jump_rise")
		elif velocity.y < 120.0:
			_play("jump_apex")
		else:
			_play("fall")
	elif landing and direction == 0.0:
		return  # let the land animation finish
	elif direction != 0.0:
		landing = false
		if sprite.animation == "run_start" and sprite.is_playing():
			return
		_play("run_start" if sprite.animation == "idle" else "run")
	else:
		_play("idle")


func _play(anim: StringName) -> void:
	if sprite.animation != anim:
		sprite.play(anim)


func _on_animation_finished() -> void:
	if sprite.animation == "land":
		landing = false
	elif sprite.animation == "crouch_down":
		sprite.play("crouch_idle")


# Called by hazards (spikes, pits)
func hurt() -> void:
	if dead:
		return
	dead = true
	velocity = Vector2.ZERO
	sprite.play("hurt")
	await sprite.animation_finished
	await get_tree().create_timer(0.15).timeout
	global_position = respawn_point
	velocity = Vector2.ZERO
	coyote_timer = 0.0
	_set_crouch(false)
	dead = false
	sprite.play("idle")


# Stretch goal: call this from a checkpoint Area2D
func set_checkpoint(pos: Vector2) -> void:
	respawn_point = pos
