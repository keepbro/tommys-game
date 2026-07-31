extends Area2D

# The purple fireballs the boss shoots at you. Dodge them!

const SPEED := 300.0

var direction := Vector2.RIGHT
var lifetime := 4.0
var _time := 0.0

# shape built before joining the game - see the note in powerup.gd
func _init() -> void:
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	cs.shape = shape
	add_child(cs)

func _ready() -> void:
	add_to_group("boss_bullets")
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	position += direction * SPEED * delta
	queue_redraw()

func _draw() -> void:
	var pulse := (sin(_time * 18.0) + 1.0) / 2.0
	draw_circle(Vector2.ZERO, 15.0 + pulse * 3.0, Color(0.8, 0.2, 1.0, 0.35))
	draw_circle(Vector2.ZERO, 9.0, Color(0.7, 0.3, 1.0))
	draw_circle(Vector2.ZERO, 4.5, Color(1.0, 0.85, 1.0))

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") or body.is_in_group("boss"):
		return
	if body.is_in_group("player"):
		body.take_damage()
	# hits the player OR a wall - either way it pops
	var Explosion := load("res://scripts/explosion.gd")
	var burst: Node2D = Explosion.new()
	burst.colors = [Color(0.8, 0.3, 1.0), Color(1, 0.8, 1)]
	burst.count = 8
	burst.max_lifetime = 0.35
	burst.speed_max = 180.0
	get_tree().current_scene.add_child(burst)
	burst.global_position = global_position
	queue_free()
