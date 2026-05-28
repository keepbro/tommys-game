extends Node2D

const COLORS := [Color(1, 0.9, 0.2), Color(1, 0.4, 0.9), Color(0.4, 0.9, 1), Color(1, 1, 1)]
const MAX_LIFETIME := 0.7

var particles := []
var lifetime := 0.0

func _ready() -> void:
	for i in 10:
		var angle := (TAU / 10.0) * i + randf() * 0.4
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * randf_range(70, 200),
			"color": COLORS[i % COLORS.size()],
			"size": randf_range(5, 12),
		})

func _process(delta: float) -> void:
	lifetime += delta
	if lifetime >= MAX_LIFETIME:
		queue_free()
		return
	for p in particles:
		p.pos += p.vel * delta
		p.vel *= 0.82
	queue_redraw()

func _draw() -> void:
	var t := lifetime / MAX_LIFETIME
	for p in particles:
		var s: float = p.size * (1.0 - t * 0.6)
		var c: Color = p.color
		c.a = 1.0 - t
		var pos: Vector2 = p.pos
		draw_rect(Rect2(pos - Vector2(s, s) / 2.0, Vector2(s, s)), c)
