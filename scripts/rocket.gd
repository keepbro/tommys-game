extends Area2D

# A rocket! Flies a bit slower than a bullet but makes a BIG explosion
# that hurts every monster nearby.

const SPEED := 620.0
const BLAST_RADIUS := 140.0
const BLAST_DAMAGE := 3

var direction := Vector2.RIGHT
var shooter: Node = null   # who fired it
var lifetime := 3.0
var _time := 0.0
var _smoke := 0.0

# shape built before joining the game - see the note in powerup.gd
func _init() -> void:
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	cs.shape = shape
	add_child(cs)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()

func _process(delta: float) -> void:
	_time += delta
	lifetime -= delta
	if lifetime <= 0.0:
		_boom()
		return
	position += direction * SPEED * delta

	# Puff out smoke as it flies
	_smoke -= delta
	if _smoke <= 0.0:
		_smoke = 0.02
		var Explosion := load("res://scripts/explosion.gd")
		var puff: Node2D = Explosion.new()
		puff.colors = [Color(0.8, 0.8, 0.85), Color(1, 0.8, 0.4)]
		puff.count = 2
		puff.size_max = 6.0
		puff.speed_max = 40.0
		puff.gravity = -30.0
		puff.max_lifetime = 0.4
		get_tree().current_scene.add_child(puff)
		puff.global_position = global_position - direction * 14.0
	queue_redraw()

func _draw() -> void:
	# body of the rocket (drawn pointing right, the node is rotated)
	draw_rect(Rect2(-12, -4, 20, 8), Color(0.85, 0.85, 0.9))
	draw_colored_polygon(PackedVector2Array([
		Vector2(8, -5), Vector2(17, 0), Vector2(8, 5)]), Color(1, 0.3, 0.2))
	# fins
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -4), Vector2(-16, -9), Vector2(-8, -4)]), Color(1, 0.3, 0.2))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, 4), Vector2(-16, 9), Vector2(-8, 4)]), Color(1, 0.3, 0.2))
	# flickering flame out the back
	var flame := 10.0 + sin(_time * 40.0) * 5.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -4), Vector2(-12 - flame, 0), Vector2(-12, 4)]), Color(1, 0.75, 0.2, 0.9))

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	_boom()

func _boom() -> void:
	var Explosion := load("res://scripts/explosion.gd")
	var burst: Node2D = Explosion.new()
	burst.colors = [Color(1, 0.8, 0.2), Color(1, 0.4, 0.1), Color(0.4, 0.4, 0.4)]
	burst.count = 24
	burst.speed_max = 480.0
	burst.size_max = 18.0
	burst.max_lifetime = 0.7
	burst.ring = true
	get_tree().current_scene.add_child(burst)
	burst.global_position = global_position

	Sfx.play("boss_die", 1.5, -3.0)

	# Hurt EVERYTHING close by
	for target in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("boss") \
			+ get_tree().get_nodes_in_group("chests"):
		if is_instance_valid(target) and global_position.distance_to(target.global_position) < BLAST_RADIUS:
			target.take_damage(BLAST_DAMAGE)

	# In versus the blast catches the OTHER player too (never the firer)
	for pl in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(pl):
			pl.shake(14.0)
			if pl != shooter and global_position.distance_to(pl.global_position) < BLAST_RADIUS:
				pl.take_damage()

	queue_free()
