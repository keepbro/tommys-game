extends Area2D

# Everything you can pick up! Set `kind` before adding it to the scene.
#
#   heart      - heals you straight away
#   medkit     - goes in your bag, press its number key to heal 2 hearts
#   rapid / triple / speed - power-ups that go in your bag too
#   shotgun / machinegun / rocket / laser - BETTER WEAPONS

const HEALS := ["heart", "medkit"]
const WEAPONS := ["smg", "ar", "ak", "shotgun", "machinegun", "rocket", "laser"]
const BAG_ITEMS := ["medkit", "rapid", "triple", "speed"]

var kind := "heart"
var _time := 0.0
var _start_y := 0.0

func _ready() -> void:
	add_to_group("powerups")
	_start_y = position.y
	body_entered.connect(_on_body_entered)

	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(38, 38)
	cs.shape = shape
	add_child(cs)

func _process(delta: float) -> void:
	_time += delta
	# bob up and down so it looks floaty
	position.y = _start_y + sin(_time * 3.0) * 7.0
	queue_redraw()

func color() -> Color:
	return _icon_color(kind)

func label() -> String:
	match kind:
		"heart": return "+1 HEART"
		"medkit": return "MEDKIT"
		"rapid": return "RAPID FIRE"
		"triple": return "TRIPLE SHOT"
		"speed": return "SUPER SPEED"
		"smg": return "SMG"
		"ar": return "AR"
		"ak": return "AK"
		"shotgun": return "SHOTGUN"
		"machinegun": return "MACHINE GUN"
		"rocket": return "ROCKET LAUNCHER"
		"laser": return "LASER"
	return ""

func _draw() -> void:
	draw_icon(self, kind, _time, 1.0)

# Static so the inventory bar can draw the very same icons in the UI!
static func draw_icon(c: CanvasItem, k: String, time: float, scale: float) -> void:
	var col := _icon_color(k)
	var glow := col
	glow.a = 0.22 + (sin(time * 4.0) + 1.0) * 0.1
	c.draw_circle(Vector2.ZERO, 26.0 * scale, glow)

	match k:
		"heart":
			c.draw_circle(Vector2(-6, -4) * scale, 8.0 * scale, col)
			c.draw_circle(Vector2(6, -4) * scale, 8.0 * scale, col)
			c.draw_colored_polygon(_poly([
				Vector2(-13, -1), Vector2(13, -1), Vector2(0, 15)], scale), col)
		"medkit":
			# white box with a red cross
			c.draw_rect(Rect2(Vector2(-15, -12) * scale, Vector2(30, 24) * scale), col)
			c.draw_rect(Rect2(Vector2(-15, -12) * scale, Vector2(30, 24) * scale),
				Color(0.6, 0.6, 0.65), false, 2.0 * scale)
			var red := Color(0.9, 0.15, 0.2)
			c.draw_rect(Rect2(Vector2(-3, -8) * scale, Vector2(6, 16) * scale), red)
			c.draw_rect(Rect2(Vector2(-9, -3) * scale, Vector2(18, 6) * scale), red)
			# little handle on top
			c.draw_rect(Rect2(Vector2(-5, -16) * scale, Vector2(10, 4) * scale), Color(0.5, 0.5, 0.55))
		"rapid":
			c.draw_colored_polygon(_poly([
				Vector2(3, -15), Vector2(-9, 2), Vector2(-1, 2),
				Vector2(-3, 15), Vector2(9, -3), Vector2(1, -3)], scale), col)
		"triple":
			for i in 3:
				c.draw_rect(Rect2(Vector2(-9, -12.0 + i * 10.0) * scale, Vector2(18, 5) * scale), col)
		"speed":
			var pts := PackedVector2Array()
			for i in 10:
				var r := 15.0 if i % 2 == 0 else 6.5
				var a := time * 1.5 + TAU / 10.0 * i
				pts.append(Vector2(cos(a), sin(a)) * r * scale)
			c.draw_colored_polygon(pts, col)
		"smg":
			# short and stubby with a curved magazine
			c.draw_rect(Rect2(Vector2(-10, -5) * scale, Vector2(22, 9) * scale), col.darkened(0.55))
			c.draw_rect(Rect2(Vector2(10, -2) * scale, Vector2(9, 4) * scale), Color(0.35, 0.35, 0.4))
			c.draw_colored_polygon(_poly([
				Vector2(-3, 4), Vector2(4, 4), Vector2(6, 15), Vector2(-1, 15)], scale),
				Color(0.3, 0.3, 0.35))
			c.draw_rect(Rect2(Vector2(-12, -9) * scale, Vector2(4, 6) * scale), Color(0.3, 0.3, 0.35))
		"ar":
			# long black rifle with a carry handle and sight
			c.draw_rect(Rect2(Vector2(-18, -4) * scale, Vector2(36, 8) * scale), Color(0.22, 0.24, 0.27))
			c.draw_rect(Rect2(Vector2(14, -2) * scale, Vector2(10, 4) * scale), Color(0.15, 0.16, 0.18))
			c.draw_rect(Rect2(Vector2(-6, -10) * scale, Vector2(14, 5) * scale), Color(0.3, 0.32, 0.36))
			c.draw_colored_polygon(_poly([
				Vector2(-2, 4), Vector2(5, 4), Vector2(4, 14), Vector2(-3, 14)], scale),
				Color(0.2, 0.22, 0.25))
			c.draw_rect(Rect2(Vector2(-24, -5) * scale, Vector2(7, 8) * scale), Color(0.2, 0.22, 0.25))
			c.draw_circle(Vector2(8, -12) * scale, 2.0 * scale, col)  # sight glint
		"ak":
			# wooden furniture and the famous banana magazine
			c.draw_rect(Rect2(Vector2(-18, -4) * scale, Vector2(34, 8) * scale), Color(0.5, 0.32, 0.16))
			c.draw_rect(Rect2(Vector2(12, -2.5) * scale, Vector2(12, 5) * scale), Color(0.25, 0.25, 0.28))
			# curved magazine
			var mag := PackedVector2Array()
			for i in 7:
				var t := float(i) / 6.0
				mag.append(Vector2(-4 + t * 5.0 + sin(t * 1.6) * 4.0, 4 + t * 14.0) * scale)
			for i in range(6, -1, -1):
				var t := float(i) / 6.0
				mag.append(Vector2(-11 + t * 5.0 + sin(t * 1.6) * 4.0, 4 + t * 14.0) * scale)
			c.draw_colored_polygon(mag, Color(0.35, 0.28, 0.2))
			c.draw_rect(Rect2(Vector2(-25, -6) * scale, Vector2(8, 9) * scale), Color(0.42, 0.26, 0.13))
			c.draw_rect(Rect2(Vector2(-2, -9) * scale, Vector2(12, 4) * scale), col)  # gas tube shine
		"shotgun":
			# fat double barrel
			c.draw_rect(Rect2(Vector2(-16, -7) * scale, Vector2(26, 5) * scale), col)
			c.draw_rect(Rect2(Vector2(-16, -1) * scale, Vector2(26, 5) * scale), col)
			c.draw_colored_polygon(_poly([
				Vector2(-16, -8), Vector2(-9, -8), Vector2(-13, 13), Vector2(-19, 13)], scale),
				Color(0.45, 0.28, 0.15))
		"machinegun":
			c.draw_rect(Rect2(Vector2(-16, -5) * scale, Vector2(30, 9) * scale), col)
			c.draw_rect(Rect2(Vector2(-4, 3) * scale, Vector2(8, 11) * scale), Color(0.3, 0.3, 0.35))
			# ammo drum
			c.draw_circle(Vector2(-9, 8) * scale, 6.0 * scale, Color(0.4, 0.42, 0.5))
		"rocket":
			c.draw_rect(Rect2(Vector2(-16, -5) * scale, Vector2(28, 10) * scale), Color(0.35, 0.4, 0.35))
			# the rocket poking out the front
			c.draw_colored_polygon(_poly([
				Vector2(12, -6), Vector2(20, 0), Vector2(12, 6)], scale), col)
			c.draw_rect(Rect2(Vector2(-18, -8) * scale, Vector2(5, 16) * scale), Color(0.25, 0.3, 0.25))
		"laser":
			c.draw_rect(Rect2(Vector2(-16, -5) * scale, Vector2(26, 10) * scale), Color(0.3, 0.35, 0.4))
			c.draw_circle(Vector2(12, 0) * scale, 6.0 * scale, col)
			c.draw_circle(Vector2(12, 0) * scale, 3.0 * scale, Color.WHITE)
			for i in 3:
				var x := 16.0 + i * 5.0
				c.draw_rect(Rect2(Vector2(x, -1.5) * scale, Vector2(3, 3) * scale), col)

static func _poly(points: Array, scale: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(p * scale)
	return out

static func _icon_color(k: String) -> Color:
	match k:
		"heart": return Color(1.0, 0.3, 0.4)
		"medkit": return Color(1.0, 0.95, 0.95)
		"rapid": return Color(1.0, 0.85, 0.2)
		"triple": return Color(0.4, 0.8, 1.0)
		"speed": return Color(0.5, 1.0, 0.4)
		"smg": return Color(1.0, 0.95, 0.7)
		"ar": return Color(0.85, 0.95, 1.0)
		"ak": return Color(1.0, 0.8, 0.35)
		"shotgun": return Color(1.0, 0.55, 0.15)
		"machinegun": return Color(0.75, 0.8, 0.9)
		"rocket": return Color(1.0, 0.3, 0.2)
		"laser": return Color(0.4, 1.0, 0.9)
	return Color.WHITE

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not body.collect_powerup(kind):
		return  # bag was full - leave it here for later

	var Explosion := load("res://scripts/explosion.gd")
	var burst: Node2D = Explosion.new()
	burst.colors = [color(), Color.WHITE]
	burst.count = 12
	burst.gravity = 100.0
	burst.max_lifetime = 0.5
	get_tree().current_scene.add_child(burst)
	burst.global_position = global_position

	Sfx.play("powerup")
	queue_free()
