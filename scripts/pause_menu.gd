extends Control

# The pause button (top right) and the PAUSED screen.
# This node keeps running even when the whole game is frozen, which is
# how it can un-freeze it again!

const MENU_SCENE := "res://scenes/menu.tscn"
const GameMain := preload("res://scripts/main.gd")

var _panel: Control
var _time := 0.0

func _ready() -> void:
	# PROCESS_MODE_ALWAYS = "keep working even while the game is paused"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # clicks pass through to the game

	add_child(_build_pause_button())
	_panel = _build_panel()
	_panel.visible = false
	add_child(_panel)

func _process(delta: float) -> void:
	_time += delta
	if _panel.visible:
		queue_redraw()

func _input(event: InputEvent) -> void:
	# ESC or P pauses and un-pauses
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		toggle_pause()

func toggle_pause() -> void:
	set_paused(not get_tree().paused)

func set_paused(on: bool) -> void:
	get_tree().paused = on
	_panel.visible = on
	Sfx.play("click", 1.2 if on else 0.9)
	queue_redraw()

# ---------- Buttons ----------

func _build_pause_button() -> Button:
	var b := _button("II", Vector2(1212, 14), Vector2(54, 40), Color(0.25, 0.28, 0.38),
		toggle_pause, 22)
	b.tooltip_text = "Pause (ESC or P)"
	return b

func _build_panel() -> Control:
	var panel := Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel.add_child(_button("RESUME", Vector2(490, 300), Vector2(300, 66),
		Color(0.25, 0.75, 0.35), func(): set_paused(false), 30))
	panel.add_child(_button("RESTART LEVEL", Vector2(490, 382), Vector2(300, 58),
		Color(0.30, 0.50, 0.85), _on_restart))
	panel.add_child(_button("QUIT TO TITLE", Vector2(490, 452), Vector2(300, 58),
		Color(0.75, 0.28, 0.28), _on_quit_to_title))
	return panel

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_to_title() -> void:
	get_tree().paused = false
	GameMain.level = 1
	get_tree().change_scene_to_file(MENU_SCENE)

func _button(text: String, pos: Vector2, size: Vector2, color: Color,
		action: Callable, font_size := 24) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.process_mode = Node.PROCESS_MODE_ALWAYS   # clickable while paused
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 0.75))
	b.add_theme_stylebox_override("normal", _box(color, 0.0))
	b.add_theme_stylebox_override("hover", _box(color.lightened(0.18), 3.0))
	b.add_theme_stylebox_override("pressed", _box(color.darkened(0.25), 0.0))
	b.add_theme_stylebox_override("focus", _box(color, 3.0))
	b.pressed.connect(action)
	return b

func _box(color: Color, border: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(9)
	if border > 0.0:
		sb.set_border_width_all(int(border))
		sb.border_color = Color(1, 1, 1, 0.8)
	return sb

# ---------- The PAUSED screen ----------

func _draw() -> void:
	if not _panel.visible:
		return
	var screen := get_viewport_rect().size
	var font := ThemeDB.fallback_font

	# dim the game behind so the buttons stand out
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0, 0, 0, 0.62))

	var card := Rect2(screen.x / 2.0 - 210.0, 150.0, 420.0, 380.0)
	draw_rect(card.grow(4.0), Color(0.35, 0.85, 0.5, 0.25))
	draw_rect(card, Color(0.06, 0.07, 0.16, 0.95))
	draw_rect(card, Color(1, 1, 1, 0.18), false, 2.0)
	draw_rect(Rect2(card.position, Vector2(card.size.x, 5.0)), Color(0.35, 0.85, 0.5, 0.5))

	# gently throbbing PAUSED title
	var throb := 1.0 + sin(_time * 3.0) * 0.03
	var title := "PAUSED"
	var size := int(56 * throb)
	var w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(screen.x / 2.0 - w / 2.0, 232.0), title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1, 0.9, 0.4))

	# the two pause bars, like on a remote control
	draw_rect(Rect2(screen.x / 2.0 - 26.0, 252.0, 16.0, 34.0), Color(1, 1, 1, 0.75))
	draw_rect(Rect2(screen.x / 2.0 + 10.0, 252.0, 16.0, 34.0), Color(1, 1, 1, 0.75))

	var hint := "ESC or P to carry on playing"
	var hw := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	draw_string(font, Vector2(screen.x / 2.0 - hw / 2.0, 552.0), hint,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1, 1, 1, 0.5))
