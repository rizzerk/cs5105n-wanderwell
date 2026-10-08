extends CharacterBody2D
# Shade enemy — floating patrol/chase/attack FSM.
# Does not use gravity or collide with the floor: it floats, so movement is
# just "move toward a target position" in both patrol and chase states.
#
# ---------------------------------------------------------------------------
# This script is a FINITE STATE MACHINE (FSM). The Shade is always in exactly
# one "state", and each state has its own small function that decides how to
# move this frame. Changing state = changing behaviour.
#
#                 player enters VisionArea
#     PATROL  ─────────────────────────────►  CHASE
#       ▲  ▲                                   │  ▲
#       │  └──── lose-sight timer runs out ────┘  │ player leaves AttackArea
#       │                                       ▼  │ (but is still "seen")
#       │                                     ATTACK
#       │                                        │
#       └──── hurt animation finishes ◄── HURT   │ (HURT can be entered from
#                                                  any state by calling hurt())
#
# Two kinds of code drive it:
#   1. _physics_process() runs every physics frame (60x per second). It asks
#      "what state am I in?" and runs that state's function.
#   2. SIGNAL CALLBACKS (_on_vision_entered, _on_attack_entered, ...) run only
#      when Godot detects something touching an Area2D. They're "events", and
#      they mostly just record information or flip the state.
#
# Collision setup (in Shade.tscn): the Shade's body is on collision LAYER 4.
# The player only collides with layer 1, so the player can actually pass
# through the Shade's body — damage comes from AttackArea, not from bumping.
# The Shade's MASK is 1, so it DOES bump into the tilemap walls (layer 1):
# that's why solid stone blocks it but it can rise up through one-way platforms
# (one-way tiles only block things moving downward onto them).
# ---------------------------------------------------------------------------

# An enum is a named list of constants: State.PATROL is really 0, CHASE is 1,
# and so on. Using names instead of numbers makes the code readable.
enum State { PATROL, CHASE, ATTACK, HURT }

@export var patrol_a: NodePath
@export var patrol_b: NodePath
@export var patrol_speed: float = 60.0    # pixels per second while wandering
@export var chase_speed: float = 110.0    # pixels per second while hunting (the player runs at 300)
@export var attack_cooldown: float = 1.0  # seconds between hits while the player stays in range
@export var lose_sight_time: float = 2.5   # seconds without seeing the player before giving up chase
@export var contact_damage: bool = true    # turn off to make a harmless Shade (e.g. for a menu/test)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_area: Area2D = $VisionArea
@onready var attack_area: Area2D = $AttackArea

var state: State = State.PATROL   # current FSM state
var player: Node2D = null         # who we're chasing; null = nobody spotted
var patrol_target: Vector2        # the point we're currently floating toward
var _patrol_points: Array[Vector2] = []  # world positions copied from the two markers
var _patrol_index: int = 0               # which of _patrol_points is the current target
var _lose_sight_timer: float = 0.0       # counts DOWN while chasing; at 0 we give up
var _attack_timer: float = 0.0           # counts DOWN; we can only hit again when it's <= 0
var _players_in_attack_range: Array[Node2D] = []  # everything in the player group inside AttackArea
var _home: Vector2                       # spawn position, used by reset() after the player respawns


# _ready() runs once, when the node (and all its children) have entered the scene.
func _ready() -> void:
	# Groups are tags. The player calls get_tree().call_group("enemies", "reset")
	# on respawn, which calls reset() on EVERY node tagged "enemies" at once —
	# the player never needs to know how many Shades exist.
	add_to_group("enemies")
	_home = global_position

	# Connect signals: "when VisionArea reports a body entered, call my
	# _on_vision_entered function". Area2D emits body_entered / body_exited
	# automatically whenever a physics body starts or stops overlapping it.
	vision_area.body_entered.connect(_on_vision_entered)
	vision_area.body_exited.connect(_on_vision_exited)
	attack_area.body_entered.connect(_on_attack_entered)
	attack_area.body_exited.connect(_on_attack_exited)

	if patrol_a != NodePath() and patrol_b != NodePath():
		# Copy the markers' positions ONCE. store Vector2s, not the nodes, so
		# the route is fixed even if a marker is moved or deleted later.
		_patrol_points = [get_node(patrol_a).global_position, get_node(patrol_b).global_position]
		patrol_target = _patrol_points[0]
	else:
		# no patrol points assigned — just hold position and wait to spot the player
		_patrol_points = [global_position]
		patrol_target = global_position

	_play("idle")


# Physics frame: runs at a fixed 60 Hz, separate from drawing. Movement code
# belongs here (not in _process) so speed is consistent on any computer.
# delta = seconds since the last physics frame (about 0.0167).
func _physics_process(delta: float) -> void:
	# Tick the attack cooldown down in every state, so it keeps counting even
	# while we're chasing between hits.
	if _attack_timer > 0.0:
		_attack_timer -= delta

	# "match" is GDScript's switch statement: run the branch for the current state.
	# Each state function only SETS velocity — it doesn't move anything itself.
	match state:
		State.PATROL:
			_process_patrol(delta)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HURT:
			pass  # velocity already zeroed by hurt(), just wait out the animation

	move_and_slide()


# PATROL: float back and forth between the two patrol points.
# (delta isn't used here; it's kept so all three state functions look alike.)
func _process_patrol(delta: float) -> void:
	# Only one point (no markers set) -> nowhere to go, so just hover.
	if _patrol_points.size() < 2:
		velocity = Vector2.ZERO
		_play("idle")
		return

	# Vector math: (target - me) gives an arrow pointing from me to the target.
	var to_target := patrol_target - global_position
	# Close enough (within 4 px)? Switch to the other point. We don't test for
	# exactly 0 because at 60 px/s we step ~1 px a frame and could overshoot forever.
	if to_target.length() < 4.0:
		# % (modulo) wraps the index: 0 → 1 → 0 → 1 ... (would also work for 3+ points)
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()
		patrol_target = _patrol_points[_patrol_index]
		to_target = patrol_target - global_position

	# normalized() keeps the direction but makes the length 1, so multiplying by
	# patrol_speed gives the same speed no matter how far away the target is.
	velocity = to_target.normalized() * patrol_speed
	_face_direction(velocity.x)
	_play("patrol")


# CHASE: fly straight at the player until we're close enough to attack,
# or until the lose-sight timer runs out.
func _process_chase(delta: float) -> void:
	# Safety check: if we somehow lost the reference, give up.
	if player == null:
		_enter_patrol()
		return

	# Count down how long we're willing to keep chasing.
	_lose_sight_timer -= delta
	if _lose_sight_timer <= 0.0:
		_enter_patrol()
		return

	# Something is in melee range → switch to attacking.
	if not _players_in_attack_range.is_empty():
		_enter_attack()
		return

	# Same "arrow toward target" idea as patrol, aimed at the player's CENTER.
	# There's no pathfinding: the Shade flies in a straight line and simply
	# slides along any wall in the way, which is why stone walls protect you.
	var to_player := player.global_position - global_position
	velocity = to_player.normalized() * chase_speed
	_face_direction(velocity.x)
	_play("alert")


# ATTACK: hover in place and hit whoever is inside AttackArea, once per cooldown.
# (delta isn't used here either; the cooldown is ticked in _physics_process.)
func _process_attack(delta: float) -> void:
	velocity = Vector2.ZERO

	if _players_in_attack_range.is_empty():
		# target stepped out of range — go back to chasing if still visible, else patrol
		if player != null:
			state = State.CHASE
		else:
			_enter_patrol()
		return

	_play("attack")
	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown  # start the cooldown BEFORE hitting, so we hit once
		for body in _players_in_attack_range:
			# has_method() is "duck typing": anything with a hurt() function can be
			# damaged, without this script needing to know about the Player class.
			if contact_damage and body.has_method("hurt"):
				body.hurt()


# Small "enter state" helpers. Putting state changes in one place means any
# cleanup (like forgetting the player) can't be forgotten elsewhere.
func _enter_patrol() -> void:
	state = State.PATROL
	player = null  # forget the target; it must re-enter VisionArea to be chased again


func _enter_attack() -> void:
	state = State.ATTACK
	_attack_timer = 0.0  # deal damage immediately on entering range


# Flip the sprite to face the way we're moving. The > 1.0 "dead zone" stops it
# flickering left/right when moving almost straight up or down.
func _face_direction(dx: float) -> void:
	if absf(dx) > 1.0:
		sprite.flip_h = dx < 0.0


func _play(anim: String) -> void:
	if sprite.animation != anim:
		sprite.play(anim)


func _on_vision_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		_lose_sight_timer = lose_sight_time  
		# Only start chasing from PATROL: don't interrupt an ATTACK or a HURT.
		# Vision is a plain circle, so walls don't block it — the Shade "sees"
		# through stone; it just can't fly through it.
		if state == State.PATROL:
			state = State.CHASE


func _on_vision_exited(body: Node2D) -> void:
	if body == player:
		# don't drop the chase instantly — _lose_sight_timer handles the delay
		pass


# keep a LIST instead of a single "player_in_range" bool so it still works
# if more than one damageable body is in range at the same time.
func _on_attack_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_players_in_attack_range.append(body)


func _on_attack_exited(body: Node2D) -> void:
	# erase() is safe even if the body isn't in the list (e.g. a wall tile).
	# This also fires when the player is teleported away on respawn.
	_players_in_attack_range.erase(body)


# Called on every enemy (group "enemies") when the player respawns.
# Puts the Shade back exactly as it was at level start, so it can't be waiting
# right next to the respawn point ("spawn camping").
func reset() -> void:
	global_position = _home
	velocity = Vector2.ZERO
	state = State.PATROL
	player = null
	_players_in_attack_range.clear()
	_attack_timer = 0.0
	_patrol_index = 0
	patrol_target = _patrol_points[0]
	_play("idle")


func hurt() -> void:
	# optional: call this from a hazard/player-attack if the enemy can be damaged
	# Nothing in the game calls this yet — the player has no attack.
	state = State.HURT
	velocity = Vector2.ZERO
	_play("hurt")
	# "await" pauses THIS function (not the game) until the signal fires, then
	# continues on the next line. _physics_process keeps running meanwhile,
	# which is why the HURT branch there just does nothing and waits.
	# This relies on "hurt" NOT looping: animation_finished never fires for a
	# looping animation, and the Shade would stay stuck in HURT forever.
	await sprite.animation_finished
	_enter_patrol()
