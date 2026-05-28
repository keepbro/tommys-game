extends Node2D

var time := 0.0

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var pulse := (sin(time * 3.0) + 1.0) / 2.0
	var col := Color(0.1, 0.9, 0.4, 0.75 + pulse * 0.25)
	var inner := Color(0.5, 1.0, 0.7, 0.3 + pulse * 0.3)
	# Portal body
	draw_rect(Rect2(-28, -60, 56, 110), col)
	draw_rect(Rect2(-16, -48, 32, 86), inner)
	# Arrow
	var white := Color(1, 1, 1, 0.9)
	draw_polygon(
		PackedVector2Array([Vector2(-10, -18), Vector2(10, 0), Vector2(-10, 18)]),
		PackedColorArray([white, white, white])
	)
	# Text
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-24, -70), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
