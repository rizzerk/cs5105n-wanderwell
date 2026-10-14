extends Node
# Autoload as "Juice". Screen-shake and hit-stop any script can trigger:
#   Juice.shake(10.0, 0.35)   # strength in px, duration in seconds
#   Juice.hit_stop(0.12)      # freeze the game (almost) for a moment
# No level has a Camera2D (each fits one screen), so the shake offsets the viewport's
# canvas transform instead. CanvasLayers (HUD, menus) don't move, only the world.

var _shake_strength: float = 0.0
var _shake_duration: float = 0.0
var _shake_left: float = 0.0
var _hit_stop_end_ms: int = 0
var _last_usec: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep settling the shake while paused
	_last_usec = Time.get_ticks_usec()


func shake(strength: float, duration: float = 0.25) -> void:
	# a weak shake never cuts a strong one short
	var current := _shake_strength * _falloff()
	if strength < current:
		return
	_shake_strength = strength
	_shake_duration = duration
	_shake_left = duration


# Slows the whole game to time_scale for duration (real) seconds. Animations, physics and
# tweens all slow down with it, which is what makes a hit feel heavy.
# _process ends it by checking the clock every frame. (An awaited timer can fire a few ms
# before the end time and leave the game stuck in slow motion.)
func hit_stop(duration: float, time_scale: float = 0.05) -> void:
	_hit_stop_end_ms = maxi(_hit_stop_end_ms, Time.get_ticks_msec() + int(duration * 1000.0))
	Engine.time_scale = time_scale


func _process(_delta: float) -> void:
	# real time, not delta: delta shrinks during a hit-stop and the shake would freeze
	var now := Time.get_ticks_usec()
	var dt := (now - _last_usec) / 1000000.0
	_last_usec = now
	if _hit_stop_end_ms > 0 and Time.get_ticks_msec() >= _hit_stop_end_ms:
		_hit_stop_end_ms = 0
		Engine.time_scale = 1.0
	if _shake_left <= 0.0:
		return
	_shake_left -= dt
	if _shake_left <= 0.0:
		get_viewport().canvas_transform = Transform2D.IDENTITY
		return
	var amount := _shake_strength * _falloff()
	var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * amount
	get_viewport().canvas_transform = Transform2D(0.0, offset.round())  # whole pixels keep the pixel art crisp


# 1 → 0 over the shake, squared so it settles quickly instead of fading linearly
func _falloff() -> float:
	if _shake_left <= 0.0 or _shake_duration <= 0.0:
		return 0.0
	var t := _shake_left / _shake_duration
	return t * t
