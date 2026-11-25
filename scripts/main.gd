extends Node2D
## Game manager: menu, 50 levels, scoring, lives, power-ups, HUD and saving.
## All graphics are drawn in code and sounds are tiny generated WAV files,
## so the game uses no third-party assets.

const Cfg = preload("res://scripts/config.gd")
const BubbleScript = preload("res://scripts/bubble.gd")
const HarpoonScript = preload("res://scripts/harpoon.gd")
const PlayerScript = preload("res://scripts/player.gd")
const PowerUpScript = preload("res://scripts/powerup.gd")
const TouchScript = preload("res://scripts/touch_controls.gd")

const MAX_LEVEL := 50
const START_LIVES := 3
const SAVE_PATH := "user://save.cfg"
const DROP_CHANCE := 0.14
const FREEZE_TIME := 5.0
## Spawn slots, kept away from the player's start position in the middle.
const SPAWN_X := [300.0, 980.0, 160.0, 1120.0, 450.0, 830.0]
const WORLDS := [
	{"name": "Sky", "top": Color("1d2b64"), "bottom": Color("6a8dd8")},
	{"name": "Jungle", "top": Color("0f3d2e"), "bottom": Color("4fb37a")},
	{"name": "Desert", "top": Color("5a1e0f"), "bottom": Color("e08a3c")},
	{"name": "Night", "top": Color("12123a"), "bottom": Color("8a5ad8")},
	{"name": "Candy", "top": Color("3a0f2a"), "bottom": Color("e05a8a")},
]

enum State { MENU, INTRO, PLAYING, DYING, CLEAR, GAME_OVER, WIN }

var state := State.MENU
var state_timer := 0.0
var level := 1
var lives := START_LIVES
var score := 0
var high_score := 0
var best_level := 1
var time_left := 0.0
var max_harpoons := 1
var freeze_timer := 0.0

var bubbles: Array = []
var harpoons: Array = []
var powerups: Array = []
var player
var touch

var _world: Node2D
var _hud: CanvasLayer
var _score_label: Label
var _level_label: Label
var _lives_label: Label
var _time_label: Label
var _status_label: Label
var _center_label: Label
var _sub_label: Label
var _sounds := {}


func _ready() -> void:
	randomize()
	_setup_input()
	_load_save()
	_load_sounds()

	_world = Node2D.new()
	add_child(_world)
	player = PlayerScript.new()
	_world.add_child(player)

	_hud = CanvasLayer.new()
	add_child(_hud)
	_score_label = _make_label(Vector2(36, 26), 26, HORIZONTAL_ALIGNMENT_LEFT, 400)
	_level_label = _make_label(Vector2(0, 26), 26, HORIZONTAL_ALIGNMENT_CENTER, Cfg.W)
	_time_label = _make_label(Vector2(Cfg.W - 436, 26), 26, HORIZONTAL_ALIGNMENT_RIGHT, 400)
	_lives_label = _make_label(Vector2(36, 672), 26, HORIZONTAL_ALIGNMENT_LEFT, 400)
	_status_label = _make_label(Vector2(0, 672), 26, HORIZONTAL_ALIGNMENT_CENTER, Cfg.W)
	_center_label = _make_label(Vector2(0, 250), 72, HORIZONTAL_ALIGNMENT_CENTER, Cfg.W)
	_sub_label = _make_label(Vector2(0, 350), 30, HORIZONTAL_ALIGNMENT_CENTER, Cfg.W)

	touch = TouchScript.new()
	_hud.add_child(touch)

	_show_menu()


# ---------------------------------------------------------------- setup

func _setup_input() -> void:
	_add_action("move_left", [KEY_LEFT, KEY_A])
	_add_action("move_right", [KEY_RIGHT, KEY_D])
	_add_action("fire", [KEY_SPACE, KEY_UP, KEY_W, KEY_ENTER])


func _add_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _make_label(pos: Vector2, font_size: int, align: HorizontalAlignment, width: float) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(width, font_size + 20)
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	_hud.add_child(l)
	return l


func _load_sounds() -> void:
	for sound_name in ["shoot", "pop", "powerup", "hit", "clear"]:
		var path := "res://sounds/%s.wav" % sound_name
		if not ResourceLoader.exists(path):
			continue
		var p := AudioStreamPlayer.new()
		p.stream = load(path)
		p.max_polyphony = 4
		add_child(p)
		_sounds[sound_name] = p


func _play(sound_name: String) -> void:
	if _sounds.has(sound_name):
		_sounds[sound_name].play()


func _load_save() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		best_level = clampi(int(cf.get_value("progress", "best_level", 1)), 1, MAX_LEVEL)
		high_score = int(cf.get_value("progress", "high_score", 0))


func _save() -> void:
	high_score = maxi(high_score, score)
	var cf := ConfigFile.new()
	cf.set_value("progress", "best_level", best_level)
	cf.set_value("progress", "high_score", high_score)
	cf.save(SAVE_PATH)


# ---------------------------------------------------------------- states

func _show_menu() -> void:
	state = State.MENU
	state_timer = 0.3
	level = best_level
	_clear_entities()
	player.visible = false
	touch.set_active(false)
	# A few demo bubbles bouncing in the background.
	for i in 3:
		_spawn_bubble(3 - i, Vector2(SPAWN_X[i], 200.0), -1.0 if i % 2 == 0 else 1.0, 1.0)
	_center_label.text = "PANG BUBBLE"
	var start_text := "Press SPACE or tap to start"
	if best_level > 1:
		start_text = "Press SPACE or tap to continue from level %d" % best_level
	_sub_label.text = "%s\nHigh score: %d" % [start_text, high_score]
	queue_redraw()


func _start_game() -> void:
	lives = START_LIVES
	score = 0
	level = best_level
	_begin_intro()


func _begin_intro() -> void:
	_start_level()
	state = State.INTRO
	state_timer = 1.6
	_center_label.text = "LEVEL %d" % level
	_sub_label.text = "World %d: %s   -   Ready!" % [_world_index() + 1, WORLDS[_world_index()]["name"]]


func _start_level() -> void:
	_clear_entities()
	max_harpoons = 1
	freeze_timer = 0.0
	player.visible = true
	player.reset(Cfg.W * 0.5)
	touch.set_active(false)

	# Difficulty grows with the level number.
	var top_size := clampi(1 + (level + 1) / 3, 1, 3)
	var count := mini(1 + (level - 1) / 10, 5)
	var speed := 1.0 + (level - 1) * 0.012
	var sizes: Array = []
	for i in count:
		sizes.append(top_size)
	if level % 2 == 0 and top_size > 1:
		sizes.append(top_size - 1)

	var pops := 0
	for i in sizes.size():
		var s: int = sizes[i]
		var x: float = SPAWN_X[i % SPAWN_X.size()]
		var dir := -1.0 if x < Cfg.W * 0.5 else 1.0
		_spawn_bubble(s, Vector2(x, 190.0 + randf() * 60.0), dir, speed)
		pops += (1 << (s + 1)) - 1
	time_left = 25.0 + pops * 2.5
	queue_redraw()


func _die(reason: String) -> void:
	state = State.DYING
	state_timer = 1.8
	lives -= 1
	player.dead = true
	touch.set_active(false)
	_play("hit")
	_center_label.text = reason
	_sub_label.text = "Lives left: %d" % lives if lives > 0 else ""


func _level_clear() -> void:
	state = State.CLEAR
	state_timer = 2.2
	touch.set_active(false)
	var bonus := int(time_left) * 10
	score += bonus
	_center_label.text = "LEVEL CLEAR!"
	_sub_label.text = "Time bonus +%d" % bonus
	_play("clear")
	for h in harpoons:
		h.queue_free()
	harpoons.clear()
	for p in powerups:
		p.queue_free()
	powerups.clear()
	best_level = maxi(best_level, mini(level + 1, MAX_LEVEL))
	_save()


func _game_over() -> void:
	state = State.GAME_OVER
	state_timer = 1.0
	_save()
	_center_label.text = "GAME OVER"
	_sub_label.text = "Score: %d   High score: %d\nPress SPACE or tap" % [score, high_score]


func _win() -> void:
	state = State.WIN
	state_timer = 1.0
	best_level = 1
	_save()
	_center_label.text = "YOU WIN!"
	_sub_label.text = "All %d levels cleared!   Score: %d\nPress SPACE or tap" % [MAX_LEVEL, score]


# ---------------------------------------------------------------- loop

func _input(event: InputEvent) -> void:
	if state != State.MENU and state != State.GAME_OVER and state != State.WIN:
		return
	if state_timer > 0.0 or event.is_echo() or not event.is_pressed():
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:
		if state == State.MENU:
			_start_game()
		else:
			_show_menu()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	state_timer -= delta
	match state:
		State.MENU:
			for b in bubbles:
				b.step(delta)
		State.INTRO:
			if state_timer <= 0.0:
				state = State.PLAYING
				_center_label.text = ""
				_sub_label.text = ""
				touch.set_active(true)
		State.PLAYING:
			_update_play(delta)
		State.DYING:
			if state_timer <= 0.0:
				if lives > 0:
					_begin_intro()
				else:
					_game_over()
		State.CLEAR:
			if state_timer <= 0.0:
				level += 1
				if level > MAX_LEVEL:
					_win()
				else:
					_begin_intro()
	_update_hud()


func _update_play(delta: float) -> void:
	# Move
	var axis := Input.get_axis("move_left", "move_right")
	if touch.axis != 0.0:
		axis = touch.axis
	player.move(axis, delta)
	player.tick(delta)

	# Fire
	var fire := Input.is_action_just_pressed("fire")
	if touch.consume_fire():
		fire = true
	if fire and harpoons.size() < max_harpoons:
		var h = HarpoonScript.new()
		h.setup(player.position.x)
		_world.add_child(h)
		harpoons.append(h)
		_play("shoot")

	# Update everything
	for h in harpoons:
		h.step(delta)
	if freeze_timer > 0.0:
		freeze_timer -= delta
		if freeze_timer <= 0.0:
			for b in bubbles:
				b.set_frozen(false)
	else:
		for b in bubbles:
			b.step(delta)
	for p in powerups.duplicate():
		if not p.step(delta):
			_remove(powerups, p)

	# Harpoons vs bubbles
	for h in harpoons.duplicate():
		for b in bubbles.duplicate():
			if h.hits(b):
				_pop(b)
				h.done = true
				break
		if h.done:
			_remove(harpoons, h)

	# Bubbles vs player
	if player.invuln <= 0.0:
		for b in bubbles:
			if player.overlaps_circle(b.position, b.radius * 0.92):
				if player.shield:
					player.shield = false
					player.invuln = 1.5
					_play("hit")
				else:
					_die("OUCH!")
					return
				break

	# Power-up pickup
	var pr: Rect2 = player.hit_rect()
	for p in powerups.duplicate():
		if pr.intersects(p.rect()):
			_collect(p)

	# Timer and win check
	time_left -= delta
	if bubbles.is_empty():
		_level_clear()
	elif time_left <= 0.0:
		time_left = 0.0
		_die("TIME UP!")


# ---------------------------------------------------------------- entities

func _spawn_bubble(s: int, pos: Vector2, dir: float, speed: float, vy: float = 0.0):
	var b = BubbleScript.new()
	b.setup(s, pos, dir, speed, vy)
	_world.add_child(b)
	bubbles.append(b)
	return b


func _pop(b) -> void:
	score += BubbleScript.POINTS[b.size]
	_play("pop")
	var pos: Vector2 = b.position
	if b.size > 0:
		for dir in [-1.0, 1.0]:
			var child = _spawn_bubble(b.size - 1, pos + Vector2(dir * 8.0, 0.0), dir, b.speed_scale, -330.0)
			if freeze_timer > 0.0:
				child.set_frozen(true)
	if randf() < DROP_CHANCE:
		_spawn_powerup(pos)
	_remove(bubbles, b)


func _spawn_powerup(pos: Vector2) -> void:
	var r := randf()
	var kind := PowerUpScript.DOUBLE
	if r >= 0.93:
		kind = PowerUpScript.LIFE
	elif r >= 0.65:
		kind = PowerUpScript.SHIELD
	elif r >= 0.35:
		kind = PowerUpScript.FREEZE
	var p = PowerUpScript.new()
	p.setup(kind, pos)
	_world.add_child(p)
	powerups.append(p)


func _collect(p) -> void:
	var kind: int = p.kind
	if kind == PowerUpScript.DOUBLE:
		max_harpoons = 2
	elif kind == PowerUpScript.FREEZE:
		freeze_timer = FREEZE_TIME
		for b in bubbles:
			b.set_frozen(true)
	elif kind == PowerUpScript.SHIELD:
		player.shield = true
	elif kind == PowerUpScript.LIFE:
		lives += 1
	score += 50
	_play("powerup")
	_remove(powerups, p)


func _remove(list: Array, node) -> void:
	list.erase(node)
	node.queue_free()


func _clear_entities() -> void:
	for list in [bubbles, harpoons, powerups]:
		for n in list:
			n.queue_free()
		list.clear()


# ---------------------------------------------------------------- drawing

func _world_index() -> int:
	return clampi((level - 1) / 10, 0, WORLDS.size() - 1)


func _update_hud() -> void:
	var playing := state != State.MENU
	_score_label.text = "SCORE %d" % score if playing else "HIGH SCORE %d" % high_score
	_level_label.text = "LEVEL %d / %d" % [level, MAX_LEVEL] if playing else ""
	_time_label.text = "TIME %d" % ceili(time_left) if playing else ""
	_lives_label.text = "LIVES %d" % lives if playing else ""
	var status := PackedStringArray()
	if playing:
		if max_harpoons > 1:
			status.append("DOUBLE")
		if player.shield:
			status.append("SHIELD")
		if freeze_timer > 0.0:
			status.append("FREEZE %d" % ceili(freeze_timer))
	_status_label.text = "   ".join(status)


func _draw() -> void:
	var world: Dictionary = WORLDS[_world_index()]
	var top: Color = world["top"]
	var bottom: Color = world["bottom"]
	# Sky gradient
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(Cfg.W, 0), Vector2(Cfg.W, Cfg.H), Vector2(0, Cfg.H)]),
		PackedColorArray([top, top, bottom, bottom]))
	# Soft hills
	for i in 6:
		var x := 110.0 + i * 220.0
		draw_circle(Vector2(x, Cfg.FLOOR_Y + 60.0), 150.0 + (i % 3) * 30.0, Color(bottom.darkened(0.3), 0.6))
	# Walls, ceiling and floor
	var brick := Color("6b4a2f")
	draw_rect(Rect2(0, 0, Cfg.W, Cfg.CEILING), brick)
	draw_rect(Rect2(0, 0, Cfg.LEFT, Cfg.H), brick)
	draw_rect(Rect2(Cfg.RIGHT, 0, Cfg.W - Cfg.RIGHT, Cfg.H), brick)
	draw_rect(Rect2(0, Cfg.FLOOR_Y, Cfg.W, Cfg.H - Cfg.FLOOR_Y), brick)
	for x in range(0, int(Cfg.W), 40):
		draw_line(Vector2(x, Cfg.FLOOR_Y), Vector2(x, Cfg.H), brick.darkened(0.3), 2.0)
	draw_line(Vector2(0, Cfg.FLOOR_Y), Vector2(Cfg.W, Cfg.FLOOR_Y), brick.lightened(0.3), 3.0)
