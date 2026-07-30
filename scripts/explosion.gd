extends Node2D

# A burst of flying squares. Used when things blow up!
# Change these before adding it to the scene to make big or small booms.

var colors := [Color(1, 0.8, 0.1), Color(1, 0.4, 0.1), Color(1, 1, 0.7)]
var count := 14
var speed_min := 120.0
var speed_max := 380.0
var size_min := 5.0
var size_max := 14.0
var max_lifetime := 0.6
var gravity := 500.0
var ring := false  # draw an expanding shockwave ring too?

var _bits := []
var _life := 0.0

func _ready() -> void:
	for i in count:
		var angle := randf() * TAU
		_bits.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * randf_range(speed_min, speed_max),
			"color": colors[randi() % colors.size()],
			"size": randf_range(size_min, size_max),
			"spin": randf_range(-8.0, 8.0),
			"rot": randf() * TAU,
		})

func _process(delta: float) -> void:
	_life += delta
	if _life >= max_lifetime:
		queue_free()
		return
	for b in _bits:
		b.pos += b.vel * delta
		b.vel.y += gravity * delta
		b.vel *= 0.94
		b.rot += b.spin * delta
	queue_redraw()

func _draw() -> void:
	var t := _life / max_lifetime

	if ring:
		var r: float = 20.0 + t * 130.0
		var ring_col := Color(1, 1, 1, (1.0 - t) * 0.7)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, ring_col, 5.0 * (1.0 - t))

	for b in _bits:
		var s: float = b.size * (1.0 - t * 0.7)
		var c: Color = b.color
		c.a = 1.0 - t
		# spin each little square as it flies
		var pts := PackedVector2Array()
		for corner in [Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)]:
			pts.append(b.pos + (corner / 2.0).rotated(b.rot))
		draw_colored_polygon(pts, c)
