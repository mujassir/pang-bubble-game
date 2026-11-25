extends Node2D
## On-screen controls for phones and tablets.
## Left half of the screen: a floating joystick (drag left/right).
## Right half of the screen: tap to fire.

const Cfg = preload("res://scripts/config.gd")
const STICK_HOME := Vector2(170.0, 590.0)
const STICK_RADIUS := 70.0
const FIRE_POS := Vector2(1130.0, 590.0)
const FIRE_RADIUS := 72.0

var axis := 0.0
var active := false  # set by main while a level is being played

var _available := false
var _fire_queued := false
var _stick_index := -1
var _stick_origin := STICK_HOME
var _fire_index := -1


func _ready() -> void:
	_available = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")


func set_active(value: bool) -> void:
	active = value
	if not active:
		axis = 0.0
		_stick_index = -1
		_fire_index = -1
		_fire_queued = false
	queue_redraw()


func consume_fire() -> bool:
	var f := _fire_queued
	_fire_queued = false
	return f


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_available = true
		if not active:
			return
		if touch.pressed:
			if touch.position.x < Cfg.W * 0.5 and _stick_index == -1:
				_stick_index = touch.index
				_stick_origin = touch.position
			elif touch.position.x >= Cfg.W * 0.5 and _fire_index == -1:
				_fire_index = touch.index
				_fire_queued = true
		else:
			if touch.index == _stick_index:
				_stick_index = -1
				_stick_origin = STICK_HOME
				axis = 0.0
			elif touch.index == _fire_index:
				_fire_index = -1
		queue_redraw()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if not active or drag.index != _stick_index:
			return
		var dx := clampf(drag.position.x - _stick_origin.x, -STICK_RADIUS, STICK_RADIUS)
		axis = dx / STICK_RADIUS
		if absf(axis) < 0.2:
			axis = 0.0
		queue_redraw()


func _draw() -> void:
	if not (_available and active):
		return
	draw_circle(_stick_origin, STICK_RADIUS, Color(1, 1, 1, 0.10))
	draw_arc(_stick_origin, STICK_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
	draw_circle(_stick_origin + Vector2(axis * STICK_RADIUS, 0.0), 30.0, Color(1, 1, 1, 0.35))
	var fire_alpha := 0.45 if _fire_index != -1 else 0.22
	draw_circle(FIRE_POS, FIRE_RADIUS, Color(1.0, 0.3, 0.3, fire_alpha))
	draw_arc(FIRE_POS, FIRE_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
	draw_string(ThemeDB.fallback_font, FIRE_POS + Vector2(-FIRE_RADIUS, 9.0), "FIRE",
		HORIZONTAL_ALIGNMENT_CENTER, FIRE_RADIUS * 2.0, 26, Color(1, 1, 1, 0.85))
