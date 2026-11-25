extends Node2D
## The player. Position is the point between the feet, on the floor.

const Cfg = preload("res://scripts/config.gd")
const SPEED := 330.0
const WIDTH := 36.0
const HEIGHT := 58.0

var facing := 1.0
var shield := false
var invuln := 0.0
var dead := false
var _walk := 0.0


func reset(x: float) -> void:
	position = Vector2(x, Cfg.FLOOR_Y)
	shield = false
	invuln = 0.0
	dead = false
	facing = 1.0
	queue_redraw()


func move(axis: float, delta: float) -> void:
	position.x = clampf(position.x + axis * SPEED * delta,
		Cfg.LEFT + WIDTH * 0.5, Cfg.RIGHT - WIDTH * 0.5)
	if axis != 0.0:
		facing = signf(axis)
		_walk += delta * 14.0
	queue_redraw()


func tick(delta: float) -> void:
	invuln = maxf(invuln - delta, 0.0)
	queue_redraw()


## Slightly smaller than the drawing, to be fair to the player.
func hit_rect() -> Rect2:
	return Rect2(position.x - WIDTH * 0.5 + 6.0, position.y - HEIGHT + 8.0, WIDTH - 12.0, HEIGHT - 8.0)


func overlaps_circle(center: Vector2, r: float) -> bool:
	var rect := hit_rect()
	var closest := Vector2(clampf(center.x, rect.position.x, rect.end.x),
		clampf(center.y, rect.position.y, rect.end.y))
	return center.distance_to(closest) < r


func _draw() -> void:
	# Blink while invulnerable.
	if invuln > 0.0 and int(invuln * 10.0) % 2 == 0:
		return
	var skin := Color("ffd2a6")
	var shirt := Color("e8413c")
	var pants := Color("2d3a8c")
	if dead:
		skin = Color("9a9a9a")
		shirt = Color("6a6a6a")
		pants = Color("4a4a4a")
	var step := sin(_walk) * 4.0
	# Legs
	draw_rect(Rect2(-12.0 + step, -18.0, 9.0, 18.0), pants)
	draw_rect(Rect2(3.0 - step, -18.0, 9.0, 18.0), pants)
	# Body
	draw_rect(Rect2(-15.0, -42.0, 30.0, 26.0), shirt)
	# Arm holding the harpoon gun
	draw_rect(Rect2(facing * 10.0 - 4.0, -40.0, 8.0, 16.0), skin)
	# Head
	draw_circle(Vector2(0.0, -49.0), 11.0, skin)
	# Cap
	draw_rect(Rect2(-11.0, -60.0, 22.0, 6.0), Color("ffd447"))
	draw_rect(Rect2(facing * 4.0 - 4.0 + facing * 6.0, -56.0, 10.0, 3.0), Color("ffd447"))
	# Eye
	draw_circle(Vector2(facing * 5.0, -49.0), 2.0, Color("222222"))
	if shield:
		draw_arc(Vector2(0.0, -30.0), 40.0, 0.0, TAU, 40, Color(0.45, 0.95, 1.0, 0.85), 3.0)
