extends Area2D

# A bullet. Different weapons make bullets with different
# speed, damage, size and colour.

const TRAIL_LENGTH := 8

var direction := Vector2.RIGHT
var speed := 900.0
var damage := 1
var pierce := false        # laser bullets go straight through monsters!
var color := Color(1.0, 0.75, 0.1)
var size := 5.0
var lifetime := 2.0

var _trail := []  # remembers where the bullet just was, to draw a streak
var _hits := 0

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	position += direction * speed * delta

	# Remember the last few spots (relative to where we are now)
	_trail.push_front(Vector2.ZERO)
	for i in _trail.size():
		_trail[i] -= direction * speed * delta
	if _trail.size() > TRAIL_LENGTH:
		_trail.resize(TRAIL_LENGTH)
	queue_redraw()

func _draw() -> void:
	# A glowing streak behind the bullet, fading out at the tail
	for i in _trail.size():
		var fade := 1.0 - float(i) / float(TRAIL_LENGTH)
		draw_circle(_trail[i], size * 1.2 * fade, Color(color.r, color.g, color.b, fade * 0.55))
	draw_circle(Vector2.ZERO, size, Color(color.r, color.g, color.b, 0.9))
	draw_circle(Vector2.ZERO, size * 0.45, Color(1, 1, 1, 0.95))

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)
		_hits += 1
		# Lasers keep going through up to 4 monsters
		if pierce and _hits < 4:
			return
	else:
		# hit a wall - make some sparks
		var Explosion := load("res://scripts/explosion.gd")
		var sparks: Node2D = Explosion.new()
		sparks.colors = [color, color.lightened(0.5)]
		sparks.count = 5
		sparks.size_max = 5.0
		sparks.speed_max = 140.0
		sparks.max_lifetime = 0.25
		get_tree().current_scene.add_child(sparks)
		sparks.global_position = global_position
	queue_free()
