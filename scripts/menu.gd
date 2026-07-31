extends Control

# The front screen of the game! It shows a loading bar first, then
# the title with three buttons: PLAY, TEAM and SETTINGS.

const GAME_SCENE := preload("res://scenes/main.tscn")
const GameMain := preload("res://scripts/main.gd")
const Teams := preload("res://scripts/teams.gd")
const LOAD_TIME := 1.6         # how long the loading bar takes to fill

enum Screen { LOADING, TITLE, TEAM, SETTINGS }

var screen := Screen.LOADING
var _time := 0.0
var _load_progress := 0.0
var _stars := []

var _title_panel: Control
var _team_panel: Control
var _settings_panel: Control
var _team_buttons := {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Safety net: if the game was left frozen, un-freeze it. A paused game
	# ignores button clicks, which would make the menu look broken!
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	# twinkly background stars
	for i in 70:
		_stars.append({
			"pos": Vector2(randf() * 1280.0, randf() * 720.0),
			"size": randf_range(1.0, 2.8),
			"speed": randf_range(6.0, 26.0),
			"twinkle": randf() * TAU,
		})

	_title_panel = _build_title_screen()
	_team_panel = _build_team_screen()
	_settings_panel = _build_settings_screen()
	for panel in [_title_panel, _team_panel, _settings_panel]:
		panel.visible = false
		add_child(panel)

func _process(delta: float) -> void:
	_time += delta

	# drift the stars sideways
	for s in _stars:
		s.pos.x -= s.speed * delta
		if s.pos.x < -4.0:
			s.pos.x = 1284.0
			s.pos.y = randf() * 720.0

	if screen == Screen.LOADING:
		_load_progress = minf(1.0, _load_progress + delta / LOAD_TIME)
		if _load_progress >= 1.0:
			_show(Screen.TITLE)
			_focus_first_button(_title_panel)   # so ENTER works right away

	queue_redraw()

func _show(which: int) -> void:
	screen = which
	_title_panel.visible = which == Screen.TITLE
	_team_panel.visible = which == Screen.TEAM
	_settings_panel.visible = which == Screen.SETTINGS
	queue_redraw()   # repaint the background straight away, no flicker

func _input(event: InputEvent) -> void:
	# ENTER or SPACE on the title always starts the game, even if a
	# mouse click somehow misses the button
	if screen == Screen.TITLE and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		Sfx.play("click")
		_on_play()
		return

	if not event.is_action_pressed("ui_cancel"):
		return
	if screen == Screen.TEAM or screen == Screen.SETTINGS:
		_show(Screen.TITLE)          # ESC goes back to the title
		_focus_first_button(_title_panel)
	elif screen == Screen.TITLE:
		get_tree().quit()            # ESC on the title quits the game

func _focus_first_button(panel: Control) -> void:
	for b in panel.get_children():
		if b is Button:
			b.grab_focus()
			return

# ---------- The three screens ----------

func _build_title_screen() -> Control:
	var panel := Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel.add_child(_button("PLAY", Vector2(490, 330), Vector2(300, 74),
		Color(0.25, 0.75, 0.35), _on_play, 34))
	panel.add_child(_rainbow_button("TEAM", Vector2(490, 420), Vector2(300, 62),
		func(): _show(Screen.TEAM)))
	panel.add_child(_button("SETTINGS", Vector2(490, 496), Vector2(300, 62),
		Color(0.55, 0.40, 0.80), func(): _show(Screen.SETTINGS)))
	panel.add_child(_button("QUIT", Vector2(490, 572), Vector2(300, 62),
		Color(0.75, 0.28, 0.28), _on_quit))
	return panel

func _build_team_screen() -> Control:
	var panel := Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel.add_child(_label("CHOOSE YOUR TEAM", Vector2(0, 118), 44, Color(1, 0.9, 0.4)))

	# One button per team, side by side
	for i in Teams.LIST.size():
		var id: String = Teams.LIST[i]
		var team: Dictionary = Teams.DATA[id]
		var b := _button(team["name"], Vector2(326 + i * 158, 196), Vector2(144, 62),
			team["armour"], func(): _pick_team(id), 24)
		b.add_theme_constant_override("outline_size", 8)
		b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		_team_buttons[id] = b
		panel.add_child(b)

	panel.add_child(_label("Made by Tommy, Dad & Claude  -  Godot 4",
		Vector2(0, 542), 16, Color(1, 1, 1, 0.45)))
	panel.add_child(_button("BACK", Vector2(540, 578), Vector2(200, 56),
		Color(0.45, 0.45, 0.5), func(): _show(Screen.TITLE)))
	_mark_chosen_team()
	return panel

func _pick_team(id: String) -> void:
	Sfx.set_team(id)
	_mark_chosen_team()
	queue_redraw()

# Puts a white glowing border round whichever team is chosen
func _mark_chosen_team() -> void:
	for id in _team_buttons:
		var team: Dictionary = Teams.DATA[id]
		var chosen: bool = id == Sfx.team
		var b: Button = _team_buttons[id]
		b.add_theme_stylebox_override("normal",
			_box(team["armour"], 4.0 if chosen else 0.0))
		b.size.y = 74.0 if chosen else 62.0
		b.position.y = 190.0 if chosen else 196.0

func _build_settings_screen() -> Control:
	var panel := Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel.add_child(_label("SETTINGS", Vector2(0, 120), 52, Color(1, 0.9, 0.4)))

	# MUSIC volume
	panel.add_child(_label("MUSIC", Vector2(-330, 235), 26, Color(1, 1, 1, 0.9)))
	var music_value := _value_label(Vector2(880, 236), Sfx.music_volume)
	var music := _slider(Vector2(540, 240), Sfx.music_volume)
	music.value_changed.connect(func(v: float):
		Sfx.set_music_volume(v / 100.0)
		music_value.text = "%d%%" % int(v))
	panel.add_child(music)
	panel.add_child(music_value)

	# SOUND EFFECTS volume
	panel.add_child(_label("SOUND", Vector2(-330, 325), 26, Color(1, 1, 1, 0.9)))
	var sfx_value := _value_label(Vector2(880, 326), Sfx.sfx_volume)
	var sfx := _slider(Vector2(540, 330), Sfx.sfx_volume)
	sfx.value_changed.connect(func(v: float):
		Sfx.set_sfx_volume(v / 100.0)
		sfx_value.text = "%d%%" % int(v)
		Sfx.play("click"))            # so you can hear how loud it is
	panel.add_child(sfx)
	panel.add_child(sfx_value)

	# FULL SCREEN on/off
	panel.add_child(_label("FULL SCREEN", Vector2(-330, 415), 26, Color(1, 1, 1, 0.9)))
	var full := _button("", Vector2(540, 408), Vector2(150, 46), Color(0.3, 0.6, 0.4),
		func(): pass, 24)
	full.toggle_mode = true
	full.button_pressed = Sfx._is_fullscreen()
	full.text = "ON" if full.button_pressed else "OFF"
	full.toggled.connect(func(on: bool):
		full.text = "ON" if on else "OFF"
		Sfx.set_fullscreen(on))
	panel.add_child(full)

	panel.add_child(_label("Your settings are saved automatically.",
		Vector2(0, 500), 17, Color(1, 1, 1, 0.5)))
	panel.add_child(_button("BACK", Vector2(540, 578), Vector2(200, 56),
		Color(0.45, 0.45, 0.5), func(): _show(Screen.TITLE)))
	return panel

func _on_play() -> void:
	# The level is baked in with `preload`, so it is already in memory here -
	# nothing can fail to load at the moment you press PLAY.
	var err := get_tree().change_scene_to_packed(GAME_SCENE)
	GameMain.level = 1              # always start a fresh game from level 1
	if err != OK:
		push_error("Could not start the game! error code %d" % err)

func _on_quit() -> void:
	# let the click bleep finish before the window closes
	await get_tree().create_timer(0.12).timeout
	get_tree().quit()

# ---------- Little builders ----------

func _button(text: String, pos: Vector2, size: Vector2, color: Color,
		action: Callable, font_size := 26) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 0.75))
	b.add_theme_stylebox_override("normal", _box(color, 0.0))
	b.add_theme_stylebox_override("hover", _box(color.lightened(0.18), 3.0))
	b.add_theme_stylebox_override("pressed", _box(color.darkened(0.25), 0.0))
	b.add_theme_stylebox_override("focus", _box(color, 3.0))
	b.pressed.connect(func():
		Sfx.play("click")
		action.call())
	return b

# ---------- The four-colour TEAM button ----------

const TEAM_COLORS := [
	Color(0.88, 0.20, 0.22),   # red
	Color(0.20, 0.45, 0.92),   # blue
	Color(0.22, 0.75, 0.32),   # green
	Color(0.97, 0.82, 0.15),   # yellow
]

func _rainbow_button(text: String, pos: Vector2, size: Vector2, action: Callable) -> Button:
	var b := _button(text, pos, size, Color.WHITE, action)
	# four stripes instead of one flat colour
	b.add_theme_stylebox_override("normal", _rainbow_box(0.0, false))
	b.add_theme_stylebox_override("hover", _rainbow_box(0.22, true))
	b.add_theme_stylebox_override("pressed", _rainbow_box(-0.25, false))
	b.add_theme_stylebox_override("focus", _rainbow_box(0.0, true))
	# black outline round the letters so they show up on the yellow stripe
	b.add_theme_constant_override("outline_size", 8)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	return b

func _rainbow_box(shade: float, border: bool) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = _rainbow_texture(shade, border)
	return sb

# Paints a little picture with the four colours side by side, which then
# gets stretched across the button
func _rainbow_texture(shade: float, border: bool) -> ImageTexture:
	var w := 240
	var h := 62
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for x in w:
		var band: int = mini(x * TEAM_COLORS.size() / w, TEAM_COLORS.size() - 1)
		var c: Color = TEAM_COLORS[band]
		if shade > 0.0:
			c = c.lightened(shade)
		elif shade < 0.0:
			c = c.darkened(-shade)
		for y in h:
			var on_edge := border and (x < 3 or x >= w - 3 or y < 3 or y >= h - 3)
			img.set_pixel(x, y, Color(1, 1, 1, 0.9) if on_edge else c)
	return ImageTexture.create_from_image(img)

func _box(color: Color, border: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(10)
	if border > 0.0:
		sb.set_border_width_all(int(border))
		sb.border_color = Color(1, 1, 1, 0.8)
	return sb

# A label centred across the screen (x is an offset from the middle)
func _label(text: String, offset: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = Vector2(offset.x, offset.y)
	l.size = Vector2(1280, font_size + 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _value_label(pos: Vector2, value: float) -> Label:
	var l := Label.new()
	l.text = "%d%%" % int(value * 100.0)
	l.position = pos
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _slider(pos: Vector2, value: float) -> HSlider:
	var s := HSlider.new()
	s.position = pos
	s.size = Vector2(300, 30)
	s.min_value = 0.0
	s.max_value = 100.0
	s.step = 5.0
	s.value = value * 100.0
	# make the bar fat and colourful instead of a thin grey line
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.10, 0.12, 0.20)
	track.set_corner_radius_all(7)
	track.content_margin_top = 7.0
	track.content_margin_bottom = 7.0
	var filled := StyleBoxFlat.new()
	filled.bg_color = Color(0.30, 0.85, 0.45)
	filled.set_corner_radius_all(7)
	filled.content_margin_top = 7.0
	filled.content_margin_bottom = 7.0
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", filled)
	s.add_theme_stylebox_override("grabber_area_highlight", filled)
	return s

# ---------- Background art ----------

func _draw() -> void:
	var font := ThemeDB.fallback_font

	# night sky, darker at the bottom
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.05, 0.05, 0.14))
	draw_rect(Rect2(0, 420, 1280, 300), Color(0.03, 0.03, 0.09))

	for s in _stars:
		var tw: float = 0.5 + (sin(_time * 2.0 + s.twinkle) + 1.0) * 0.25
		draw_circle(s.pos, s.size, Color(1, 1, 1, tw * 0.7))

	if screen == Screen.LOADING:
		_draw_loading(font)
		return

	if screen == Screen.TITLE:
		_draw_title(font)
	else:
		_draw_panel(font)

func _draw_loading(font: Font) -> void:
	draw_string(font, Vector2(490, 330), "LOADING...", HORIZONTAL_ALIGNMENT_LEFT, -1, 34,
		Color(1, 1, 1, 0.9))
	var bar := Rect2(440, 360, 400, 26)
	draw_rect(bar, Color(0, 0, 0, 0.6))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _load_progress, bar.size.y)),
		Color(0.3, 0.9, 0.5))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _load_progress, 7.0)),
		Color(1, 1, 1, 0.3))
	draw_rect(bar, Color(1, 1, 1, 0.5), false, 2.0)
	draw_string(font, Vector2(440, 412), "building sounds out of maths...",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1, 1, 1, 0.45))

# A dark card behind the TEAM and SETTINGS text so it's easy to read
func _draw_panel(font: Font) -> void:
	var card := Rect2(300, 92, 680, 560)
	draw_rect(card.grow(4.0), Color(0.35, 0.85, 0.5, 0.25))
	draw_rect(card, Color(0.06, 0.07, 0.16, 0.94))
	draw_rect(card, Color(1, 1, 1, 0.18), false, 2.0)
	# a soft glow strip along the top of the card
	draw_rect(Rect2(card.position, Vector2(card.size.x, 5.0)), Color(0.35, 0.85, 0.5, 0.5))
	draw_string(font, Vector2(20, 700), "ESC to go back", HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
		Color(1, 1, 1, 0.35))

	if screen == Screen.TEAM:
		_draw_team_preview(font)

# Shows your knight wearing the team you picked
func _draw_team_preview(font: Font) -> void:
	var team: Dictionary = Teams.get_team(Sfx.team)

	# a glow behind him in the team colour
	var glow: Color = team["armour"]
	glow.a = 0.13 + (sin(_time * 2.5) + 1.0) * 0.05
	draw_circle(Vector2(640, 380), 108.0, glow)

	_draw_hero(Vector2(640, 400 + sin(_time * 2.2) * 4.0), team, 3.1)

	var line: String = "YOUR TEAM:  " + str(team["name"])
	var w := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
	draw_string(font, Vector2(640.0 - w / 2.0, 478.0), line,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 28, team["light"])

	var motto: String = team["motto"]
	var mw := font.get_string_size(motto, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	draw_string(font, Vector2(640.0 - mw / 2.0, 510.0), motto,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.75))

func _draw_title(font: Font) -> void:
	# The big bouncing SHOOTO logo
	var bounce := sin(_time * 2.0) * 6.0
	var title := "SHOOTO"
	var size := 96
	var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := Vector2(640.0 - width / 2.0, 190.0 + bounce)

	# chunky shadow layers so it looks 3D
	draw_string(font, at + Vector2(6, 7), title, HORIZONTAL_ALIGNMENT_LEFT, -1, size,
		Color(0.10, 0.30, 0.15))
	draw_string(font, at + Vector2(3, 4), title, HORIZONTAL_ALIGNMENT_LEFT, -1, size,
		Color(0.15, 0.45, 0.22))
	draw_string(font, at, title, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.35, 0.95, 0.5))

	var sub := "A parkour shooter by Tommy"
	var sw := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	draw_string(font, Vector2(640.0 - sw / 2.0, 240.0 + bounce), sub,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 1, 0.75))

	# the hero peeking in from the side
	_draw_hero(Vector2(215, 470 + sin(_time * 2.4) * 5.0), Teams.get_team(Sfx.team))
	# and a goblin eyeing him up from the other side
	_draw_goblin(Vector2(1065, 478 + sin(_time * 2.4 + 1.5) * 5.0))

	draw_string(font, Vector2(20, 700), "ESC to quit", HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
		Color(1, 1, 1, 0.35))

# Small versions of the characters, just for decoration.
# The hero is painted in whichever team's colours you pass in.
func _draw_hero(at: Vector2, team: Dictionary, s := 2.2) -> void:
	var armour: Color = team["armour"]
	var dark: Color = team["dark"]
	var cape: Color = team["cape"]

	draw_set_transform(at, 0.0, Vector2(s, s))
	# cape
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -10), Vector2(6, -10), Vector2(9, 8), Vector2(-9, 14)]), cape)
	# legs and body
	draw_rect(Rect2(-8, 8, 6, 14), dark)
	draw_rect(Rect2(2, 8, 6, 14), dark)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11, -9), Vector2(11, -9), Vector2(9, 9), Vector2(-9, 9)]), armour)
	draw_rect(Rect2(-9, 5, 18, 4), Color(0.90, 0.80, 0.35))
	# head with helmet
	draw_circle(Vector2(1, -19), 8.0, Color(0.96, 0.78, 0.62))
	var dome := PackedVector2Array()
	for i in 13:
		var a := PI + PI * (float(i) / 12.0)
		dome.append(Vector2(1, -20) + Vector2(cos(a) * 10.0, sin(a) * 10.4))
	draw_colored_polygon(dome, armour)
	draw_line(Vector2(-9, -20), Vector2(11, -20), Color(0.90, 0.80, 0.35), 2.6)
	draw_circle(Vector2(4, -24), 2.2, Color(0.35, 0.95, 1.0))
	draw_circle(Vector2(3, -18), 1.5, Color(0.1, 0.1, 0.15))
	draw_circle(Vector2(-2, -18), 1.3, Color(0.1, 0.1, 0.15))
	# his gun
	draw_rect(Rect2(9, -6, 20, 6), Color(0.7, 0.7, 0.75))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_goblin(at: Vector2) -> void:
	var s := 2.2
	draw_set_transform(at, 0.0, Vector2(-s, s))
	var skin := Color(0.85, 0.22, 0.22)
	var dark := Color(0.62, 0.13, 0.16)
	draw_rect(Rect2(-9, 6, 7, 14), dark)
	draw_rect(Rect2(2, 6, 7, 14), dark)
	draw_circle(Vector2(0, -2), 13.0, skin)
	var head := Vector2(2, -17)
	draw_circle(head, 12.0, skin)
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-9, -3), head + Vector2(-14, -13), head + Vector2(-4, -7)]), dark)
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(9, -3), head + Vector2(14, -13), head + Vector2(4, -7)]), dark)
	for side: float in [-1.0, 1.0]:
		var eye := head + Vector2(side * 5.0, -1.0)
		draw_circle(eye, 4.2, Color(1, 1, 0.85))
		draw_circle(eye + Vector2(-1.5, 0), 2.1, Color(0.9, 0.1, 0.1))
	draw_rect(Rect2(head.x - 6, head.y + 4, 12, 4), Color(0.2, 0.05, 0.06))
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-5, 4), head + Vector2(-2, 4), head + Vector2(-3.5, 9)]), Color.WHITE)
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(2, 4), head + Vector2(5, 4), head + Vector2(3.5, 9)]), Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
