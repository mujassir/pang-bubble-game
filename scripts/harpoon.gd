extends Node2D
## A harpoon that shoots straight up from the floor. It pops the first
## bubble it touches and disappears when it reaches the ceiling.

const Cfg = preload("res://scripts/config.gd")
const SPEED := 950.0

var tip_y := Cfg.FLOOR_Y
var done := false


func setup(x: float) -> void:
	position = Vector2(x, 0.0)
	tip_y = Cfg.FLOOR_Y - 50.0
	queue_redraw()


func step(delta: float) -> void:
	tip_y -= SPEED * delta
	if tip_y <= Cfg.CEILING:
		tip_y = Cfg.CEILING
		done = true
	queue_redraw()


## True if the rope (from the floor up to the tip) touches the bubble.
func hits(bubble) -> bool:
	var c: Vector2 = bubble.position
	var closest_y := clampf(c.y, tip_y, Cfg.FLOOR_Y)
	return Vector2(c.x - position.x, c.y - closest_y).length() <= bubble.radius


func _draw() -> void:
	var pts := PackedVector2Array()
	var y := Cfg.FLOOR_Y
	var i := 0
	while y > tip_y + 14.0:
		pts.append(Vector2(3.0 if i % 2 == 0 else -3.0, y))
		y -= 8.0
		i += 1
	pts.append(Vector2(0.0, tip_y + 14.0))
	if pts.size() >= 2:
		draw_polyline(pts, Color("eeeeee"), 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, tip_y), Vector2(-8.0, tip_y + 16.0), Vector2(8.0, tip_y + 16.0)
	]), Color("ffd447"))
