extends Control
# Row of little lanterns in the HUD: lit ones are lives left. The one just lost flickers out.

const SPACING := 22.0
const ICON_SCALE := 1.4

var lives: int = Game.MAX_LIVES
var _fading: int = -1  # index of the lantern currently going out
var _fade: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(Game.MAX_LIVES * SPACING * ICON_SCALE, 23.0 * ICON_SCALE)


func set_lives(value: int, animate: bool = true) -> void:
	if animate and value < lives:
		_fading = value
		_fade = 1.0
		var t := create_tween()
		t.tween_property(self, "_fade", 0.0, 0.9)
		t.tween_callback(func() -> void: _fading = -1)
	lives = value
	queue_redraw()


func _process(_delta: float) -> void:
	if _fading >= 0:
		queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(ICON_SCALE, ICON_SCALE))
	for i in Game.MAX_LIVES:
		var glow := 0.0
		if i < lives:
			glow = 1.0
		elif i == _fading:
			glow = _fade * (0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.045))
		_draw_lantern(Vector2(i * SPACING, 0.0), glow)


func _draw_lantern(o: Vector2, glow: float) -> void:
	var metal := Color(0.5, 0.45, 0.72).lerp(Color(0.72, 0.62, 0.55), glow)
	if glow > 0.0:
		draw_circle(o + Vector2(8, 13), 12.0, Color(1, 0.7, 0.35, 0.25 * glow))
	draw_rect(Rect2(o + Vector2(6, 0), Vector2(4, 2)), metal)    # handle
	draw_rect(Rect2(o + Vector2(3, 2), Vector2(10, 3)), metal)   # cap
	draw_rect(Rect2(o + Vector2(3, 5), Vector2(10, 14)), metal)  # frame
	draw_rect(Rect2(o + Vector2(5, 7), Vector2(6, 10)), Color(0.1, 0.08, 0.18).lerp(Color(1, 0.84, 0.48), glow))  # glass
	draw_rect(Rect2(o + Vector2(2, 19), Vector2(12, 3)), metal)  # base
