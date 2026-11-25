extends Node2D
## A bouncing bubble. Size 3 is the biggest, size 0 the smallest.
## Each size always bounces to the same height, like the classic arcade game.

const Cfg = preload("res://scripts/config.gd")

const RADII := [14.0, 24.0, 38.0, 56.0]
const BOUNCE_HEIGHT := [150.0, 230.0, 320.0, 400.0]
const COLORS := [Color("ff5d5d"), Color("ffb13b"), Color("4fc3ff"), Color("a77bff")]
const POINTS := [100, 80, 60, 40]
const BASE_SPEED := 130.0

var size := 3
var radius := 56.0
var velocity := Vector2.ZERO
var speed_scale := 1.0
var frozen := false


func setup(p_size: int, pos: Vector2, dir: float, p_speed_scale: float, vy: float = 0.0) -> void:
	size = clampi(p_size, 0, 3)
	radius = RADII[size]
	position = pos
	speed_scale = p_speed_scale
	velocity = Vector2(BASE_SPEED * speed_scale * dir, vy)
	queue_redraw()


func set_frozen(value: bool) -> void:
	frozen = value
	queue_redraw()


func step(delta: float) -> void:
	velocity.y += Cfg.GRAVITY * delta
	position += velocity * delta

	# Floor: bounce back up to this size's fixed height.
	if position.y + radius >= Cfg.FLOOR_Y:
		position.y = Cfg.FLOOR_Y - radius
		velocity.y = -sqrt(2.0 * Cfg.GRAVITY * BOUNCE_HEIGHT[size])
	# Ceiling.
	if position.y - radius <= Cfg.CEILING:
		position.y = Cfg.CEILING + radius
		velocity.y = absf(velocity.y)
	# Side walls.
	if position.x - radius <= Cfg.LEFT:
		position.x = Cfg.LEFT + radius
		velocity.x = absf(velocity.x)
	elif position.x + radius >= Cfg.RIGHT:
		position.x = Cfg.RIGHT - radius
		velocity.x = -absf(velocity.x)


func _draw() -> void:
	var c: Color = COLORS[size]
	if frozen:
		c = c.lerp(Color("d6f6ff"), 0.6)
	draw_circle(Vector2.ZERO, radius, c.darkened(0.4))
	draw_circle(Vector2.ZERO, radius - 3.0, c)
	draw_circle(Vector2(-radius * 0.35, -radius * 0.35), radius * 0.28, Color(1, 1, 1, 0.55))
	draw_circle(Vector2(radius * 0.32, radius * 0.36), radius * 0.12, Color(1, 1, 1, 0.22))
