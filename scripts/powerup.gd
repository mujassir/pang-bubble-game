extends Node2D
## A power-up box that drops from a popped bubble and sits on the floor for a while.

const Cfg = preload("res://scripts/config.gd")

const DOUBLE := 0  # two harpoons at once
const FREEZE := 1  # bubbles stop moving for a few seconds
const SHIELD := 2  # survive one hit
const LIFE := 3    # extra life

const LABELS := ["x2", "F", "S", "+1"]
const COLORS := [Color("ffd447"), Color("7fe3ff"), Color("7dff8a"), Color("ff7ab8")]
const SIZE := 32.0
const FLOOR_TIME := 7.0

var kind := DOUBLE
var _vy := 0.0
var _time_left := FLOOR_TIME


func setup(p_kind: int, pos: Vector2) -> void:
	kind = p_kind
	position = pos
	queue_redraw()


## Returns false once the power-up has expired.
func step(delta: float) -> bool:
	var floor_center := Cfg.FLOOR_Y - SIZE * 0.5
	if position.y < floor_center:
		_vy = minf(_vy + Cfg.GRAVITY * delta, 320.0)
		position.y = minf(position.y + _vy * delta, floor_center)
	else:
		_time_left -= delta
	visible = _time_left > 2.0 or int(_time_left * 8.0) % 2 == 0
	return _time_left > 0.0


func rect() -> Rect2:
	return Rect2(position - Vector2(SIZE, SIZE) * 0.5, Vector2(SIZE, SIZE))


func _draw() -> void:
	var r := Rect2(-SIZE * 0.5, -SIZE * 0.5, SIZE, SIZE)
	draw_rect(r, COLORS[kind])
	draw_rect(r, Color("222222"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-SIZE * 0.5, 7.0), LABELS[kind],
		HORIZONTAL_ALIGNMENT_CENTER, SIZE, 18, Color("222222"))
