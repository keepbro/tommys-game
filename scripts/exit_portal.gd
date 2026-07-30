extends Node2D

# The way out! It stays LOCKED (red, with a padlock) until you beat
# the boss, then it turns green and you can jump in.

var locked := true
var time := 0.0
var _unlock_flash := 0.0
var _was_locked := true

func _process(delta: float) -> void:
	time += delta
	if _was_locked and not locked:
		_was_locked = false
		_unlock_flash = 1.0
	_unlock_flash = maxf(0.0, _unlock_flash - delta)
	queue_redraw()

func _draw() -> void:
	var pulse := (sin(time * 3.0) + 1.0) / 2.0
	var font := ThemeDB.fallback_font

	if locked:
		# Red and shut
		var col := Color(0.7, 0.15, 0.2, 0.7 + pulse * 0.2)
		var inner := Color(0.35, 0.08, 0.12, 0.6)
		draw_rect(Rect2(-28, -60, 56, 110), col)
		draw_rect(Rect2(-16, -48, 32, 86), inner)
		# Iron bars across it
		for i in 3:
			draw_rect(Rect2(-28, -46.0 + i * 34.0, 56, 7), Color(0.55, 0.55, 0.6))
		# Padlock
		draw_arc(Vector2(0, -8), 9.0, PI, TAU, 12, Color(0.85, 0.85, 0.9), 4.0)
		draw_rect(Rect2(-11, -8, 22, 18), Color(0.9, 0.8, 0.3))
		draw_circle(Vector2(0, 0), 3.0, Color(0.3, 0.25, 0.1))
		draw_string(font, Vector2(-30, -70), "LOCKED", HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
			Color(1, 0.6, 0.6))
		return

	# Open! Green and swirly
	var col := Color(0.1, 0.9, 0.4, 0.75 + pulse * 0.25)
	var inner := Color(0.5, 1.0, 0.7, 0.3 + pulse * 0.3)
	draw_rect(Rect2(-28, -60, 56, 110), col)
	draw_rect(Rect2(-16, -48, 32, 86), inner)

	# Swirling sparkles rising up through the portal
	for i in 6:
		var t := fmod(time * 0.6 + i / 6.0, 1.0)
		var x := sin(t * TAU + i) * 14.0
		var y := 46.0 - t * 100.0
		draw_circle(Vector2(x, y), 3.0 * (1.0 - t) + 1.0, Color(0.8, 1, 0.9, 1.0 - t))

	# Arrow
	var white := Color(1, 1, 1, 0.9)
	draw_polygon(
		PackedVector2Array([Vector2(-10, -18), Vector2(10, 0), Vector2(-10, 18)]),
		PackedColorArray([white, white, white])
	)
	draw_string(font, Vector2(-24, -70), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)

	# Big flash the moment it unlocks
	if _unlock_flash > 0.0:
		draw_circle(Vector2.ZERO, 40.0 + (1.0 - _unlock_flash) * 120.0,
			Color(0.6, 1, 0.8, _unlock_flash * 0.6))
