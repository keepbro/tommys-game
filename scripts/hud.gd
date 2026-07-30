extends Control

# Draws the bag (inventory), your weapon and ammo, power-up timers,
# the boss health bar, and pop-up messages.

const Powerup := preload("res://scripts/powerup.gd")
const SLOT_SIZE := 54.0
const SLOT_GAP := 8.0
const BAG_SLOTS := 5

var player: Node2D = null
var boss: Node2D = null

var _time := 0.0
var _messages := []   # {text, color, life}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func show_message(text: String, color: Color) -> void:
	_messages.push_front({"text": text, "color": color, "life": 1.6})
	if _messages.size() > 4:
		_messages.resize(4)

func _process(delta: float) -> void:
	_time += delta
	for m in _messages:
		m.life -= delta
	while _messages.size() > 0 and _messages[_messages.size() - 1].life <= 0.0:
		_messages.pop_back()
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var screen := get_viewport_rect().size

	_draw_bag(font, screen)
	_draw_weapon(font, screen)
	_draw_powerup_timers(font)
	_draw_boss_bar(font, screen)
	_draw_messages(font, screen)

# ---------- Your bag, bottom left. Press 1-5 to use things! ----------

func _draw_bag(font: Font, screen: Vector2) -> void:
	if player == null or not is_instance_valid(player):
		return
	var items: Array = player.inventory
	var top := screen.y - SLOT_SIZE - 18.0

	draw_string(font, Vector2(20, top - 8), "BAG", HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color(1, 1, 1, 0.55))

	for i in BAG_SLOTS:
		var x := 20.0 + i * (SLOT_SIZE + SLOT_GAP)
		var box := Rect2(x, top, SLOT_SIZE, SLOT_SIZE)
		var filled := i < items.size()

		draw_rect(box, Color(0, 0, 0, 0.45))
		draw_rect(box, Color(1, 1, 1, 0.55 if filled else 0.2), false, 2.0)

		if filled:
			# draw the same icon the pickup uses, shrunk to fit the slot
			draw_set_transform(box.get_center(), 0.0, Vector2.ONE)
			Powerup.draw_icon(self, items[i], _time, 0.85)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		# the number key that uses this slot
		draw_string(font, Vector2(x + 4, top + SLOT_SIZE - 4), str(i + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 0.6, 0.9 if filled else 0.35))

# ---------- Weapon and ammo, bottom right ----------

func _draw_weapon(font: Font, screen: Vector2) -> void:
	if player == null or not is_instance_valid(player):
		return
	var name: String = player.weapon
	var ammo: int = player.ammo
	var col: Color = player.WEAPONS[name]["color"]

	var box := Rect2(screen.x - 250, screen.y - 82, 230, 62)
	draw_rect(box, Color(0, 0, 0, 0.45))
	draw_rect(box, Color(col.r, col.g, col.b, 0.6), false, 2.0)

	draw_set_transform(Vector2(box.position.x + 42, box.get_center().y), 0.0, Vector2.ONE)
	Powerup.draw_icon(self, name, _time, 0.85)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_string(font, Vector2(box.position.x + 78, box.position.y + 26), name.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 19, col)

	var ammo_text := "∞ AMMO" if ammo < 0 else "AMMO %d" % ammo
	var ammo_col := Color(1, 1, 1, 0.85)
	if ammo >= 0 and ammo <= 10:
		# flash red when you're nearly out
		ammo_col = Color(1, 0.35, 0.3) if int(_time * 6.0) % 2 == 0 else Color(1, 0.7, 0.6)
	draw_string(font, Vector2(box.position.x + 78, box.position.y + 50), ammo_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ammo_col)

# ---------- Power-up timers, under the hearts ----------

func _draw_powerup_timers(font: Font) -> void:
	if player == null or not is_instance_valid(player):
		return
	var y := 100.0
	for key in player.powerups:
		var left: float = player.powerups[key]
		if left <= 0.0:
			continue
		var total: float = player.POWERUP_TIME[key]
		var col := Powerup._icon_color(key)

		draw_string(font, Vector2(22, y + 13), key.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)
		var bar := Rect2(120, y + 1, 130, 13)
		draw_rect(bar, Color(0, 0, 0, 0.5))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * (left / total), bar.size.y)), col)
		draw_rect(bar, Color(1, 1, 1, 0.35), false, 1.0)
		y += 20.0

# ---------- Boss health bar across the top ----------

func _draw_boss_bar(font: Font, screen: Vector2) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var frac := clampf(float(boss.health) / float(boss.max_health), 0.0, 1.0)
	var bar := Rect2(screen.x / 2.0 - 300.0, 66.0, 600.0, 26.0)

	draw_string(font, Vector2(bar.position.x, bar.position.y - 8), "BOSS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 0.4, 0.4))
	draw_rect(bar.grow(3.0), Color(0, 0, 0, 0.6))
	draw_rect(bar, Color(0.15, 0.05, 0.1))

	# green when healthy, red when nearly beaten
	var col := Color(0.9, 0.2, 0.3).lerp(Color(0.3, 0.9, 0.4), frac)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), col)
	# shiny top edge
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, 6.0)), Color(1, 1, 1, 0.25))
	draw_rect(bar, Color(1, 1, 1, 0.5), false, 2.0)

	draw_string(font, Vector2(bar.get_center().x - 20, bar.position.y + 20),
		"%d / %d" % [maxi(boss.health, 0), boss.max_health],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.9))

# ---------- Pop-up messages ----------

func _draw_messages(font: Font, screen: Vector2) -> void:
	for i in _messages.size():
		var m = _messages[i]
		var fade: float = clampf(m.life / 0.6, 0.0, 1.0)
		var rise: float = (1.6 - m.life) * 18.0
		var col: Color = m.color
		col.a = fade
		var y: float = 250.0 + i * 26.0 - rise
		var width := font.get_string_size(m.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		draw_string(font, Vector2(screen.x / 2.0 - width / 2.0, y), m.text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, col)
