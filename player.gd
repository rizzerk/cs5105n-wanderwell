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

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var landing_dust: CPUParticles2D = $LandingDust
@onready var lantern_light: Node2D = get_node_or_null("AnimatedSprite2D/PointLight2D")

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
	
	_build_animations()
	if lantern_light:
		anim_player.play("lantern_flicker")

func _build_animations() -> void:
	var lib := AnimationLibrary.new()

	# tiny new animation #1: squash-and-stretch on landing, via AnimationPlayer
	var squash := Animation.new()
	squash.length = 0.25
	var t := squash.add_track(Animation.TYPE_VALUE)
	squash.track_set_path(t, "AnimatedSprite2D:scale")
	squash.track_insert_key(t, 0.0, squash_amount)
	squash.track_insert_key(t, 0.25, Vector2.ONE)
	squash.value_track_set_update_mode(t, Animation.UPDATE_CONTINUOUS)
	lib.add_animation("land_squash", squash)

	# tiny new animation #2: lantern flicker, loops forever
	if lantern_light:
		var flick := Animation.new()
		flick.length = 1.4
		flick.loop_mode = Animation.LOOP_LINEAR
		var ft := flick.add_track(Animation.TYPE_VALUE)
		flick.track_set_path(ft, "AnimatedSprite2D/PointLight2D:energy")
		for i in range(5):
			flick.track_insert_key(ft, i * 1.4 / 4.0, randf_range(0.85, 1.0))
		lib.add_animation("lantern_flicker", flick)

	anim_player.add_animation_library("", lib)
	
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
		Audio.play_sfx("jump")
	
	var fall_speed := velocity.y  # her real falling speed, captured right before move_and_slide can zero it

	move_and_slide()

	# --- Landing ---
	if is_on_floor() and not was_on_floor:
		landing = true
		_play("land")
		anim_player.play("land_squash")
		Audio.play_sfx("land") 
		print("landed, fall_speed = ", fall_speed)
		if fall_speed > 200.0:
			landing_dust.restart()
			landing_dust.emitting = true
			print("dust triggered, velocity.y = ", velocity.y)
	was_on_floor = is_on_floor()


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
	var out_of_lives := Game.lose_life()
	Audio.play_sfx("hurt")
	sprite.play("hurt")
	await sprite.animation_finished
	await get_tree().create_timer(0.15).timeout
	if out_of_lives:
		Game.game_over()
		return
	global_position = respawn_point
	get_tree().call_group("enemies", "reset")  # send enemies home so they can't camp the respawn point
	velocity = Vector2.ZERO
	coyote_timer = 0.0
	_set_crouch(false)
	dead = false
	sprite.play("idle")


# Stretch goal: call this from a checkpoint Area2D
func set_checkpoint(pos: Vector2) -> void:
	respawn_point = pos
