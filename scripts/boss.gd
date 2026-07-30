extends CharacterBody2D

# THE BOSS! A big angry monster. Beat it to unlock the exit.

const GRAVITY := 1200.0
const WALK_SPEED := 95.0
const ANGRY_SPEED := 165.0
const JUMP_FORCE := -700.0
const BODY_W := 84.0
const BODY_H := 108.0

signal health_changed(current: int, maximum: int)
signal died(points: int)

var max_health := 16
var health := 16
var facing := -1.0

var _player: Node2D = null
var _shoot_timer := 1.8
var _jump_timer := 3.0
var _flash := 0.0
var _time := 0.0
var _was_in_air := false
var _entering := true

func _ready() -> void:
	add_to_group("boss")
	health = max_health

	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(BODY_W, BODY_H)
	cs.shape = shape
	add_child(cs)

	Sfx.play("boss_warn")
	# Big dramatic entrance - can't be hurt for a moment
	await get_tree().create_timer(1.2).timeout
	_entering = false
	health_changed.emit(health, max_health)

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]

func angry() -> bool:
	# Below half health the boss gets FASTER and shoots more
	return health <= max_health / 2

func _physics_process(delta: float) -> void:
	_time += delta
	_flash = maxf(0.0, _flash - delta)
	queue_redraw()

	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 1400.0)
		_was_in_air = true
	elif _was_in_air:
		_was_in_air = false
		_land_smash()

	if _entering or not is_instance_valid(_player):
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		move_and_slide()
		return

	# Stomp toward the player
	var to_player := _player.global_position.x - global_position.x
	if absf(to_player) > 60.0:
		facing = signf(to_player)
		var spd := ANGRY_SPEED if angry() else WALK_SPEED
		velocity.x = move_toward(velocity.x, facing * spd, 900.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)

	# Jump now and then, or if the player is up high
	_jump_timer -= delta
	if _jump_timer <= 0.0 and is_on_floor():
		var player_above := _player.global_position.y < global_position.y - 90.0
		if player_above or randf() < 0.6:
			velocity.y = JUMP_FORCE
			Sfx.play("jump", 0.5)
		_jump_timer = randf_range(2.0, 3.5) if not angry() else randf_range(1.2, 2.2)

	# Shoot spreads of fireballs
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot()
		_shoot_timer = 1.2 if angry() else 2.1

	move_and_slide()

func _shoot() -> void:
	var BossBullet := load("res://scripts/boss_bullet.gd")
	var aim := (_player.global_position - global_position).normalized()
	var spread := [-0.28, 0.0, 0.28] if angry() else [-0.18, 0.18]
	for offset in spread:
		var b: Area2D = BossBullet.new()
		b.direction = aim.rotated(offset)
		get_tree().current_scene.add_child(b)
		b.global_position = global_position + aim * 55.0
	Sfx.play("shoot", 0.45)

func _land_smash() -> void:
	# Landing makes a shockwave that hurts if you're standing too close
	var Explosion := load("res://scripts/explosion.gd")
	var burst: Node2D = Explosion.new()
	burst.colors = [Color(0.6, 0.4, 0.3), Color(0.9, 0.8, 0.6)]
	burst.count = 10
	burst.ring = true
	burst.speed_max = 260.0
	get_tree().current_scene.add_child(burst)
	burst.global_position = global_position + Vector2(0, BODY_H / 2.0)

	if is_instance_valid(_player):
		_player.shake(9.0)
		if global_position.distance_to(_player.global_position) < 150.0 and _player.is_on_floor():
			_player.take_damage()

func take_damage(amount := 1) -> void:
	if _entering:
		return
	health -= amount
	_flash = 0.12
	health_changed.emit(health, max_health)

	if health > 0:
		Sfx.play("boss_hurt")
		var Explosion := load("res://scripts/explosion.gd")
		var burst: Node2D = Explosion.new()
		burst.colors = [Color(0.9, 0.2, 0.4), Color(1, 0.7, 0.3)]
		burst.count = 6
		burst.max_lifetime = 0.3
		burst.speed_max = 200.0
		get_tree().current_scene.add_child(burst)
		burst.global_position = global_position
		return

	_explode()

func _explode() -> void:
	Sfx.play("boss_die")
	var Explosion := load("res://scripts/explosion.gd")
	for i in 4:
		var burst: Node2D = Explosion.new()
		burst.colors = [Color(1, 0.7, 0.1), Color(1, 0.3, 0.1), Color(1, 1, 0.8)]
		burst.count = 18
		burst.speed_max = 500.0
		burst.size_max = 20.0
		burst.max_lifetime = 0.9
		burst.ring = i == 0
		get_tree().current_scene.add_child(burst)
		burst.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-50, 50))
	if is_instance_valid(_player):
		_player.shake(26.0)
	died.emit(1000)
	queue_free()

func _draw() -> void:
	var body_col := Color(0.55, 0.15, 0.65)
	var horn_col := Color(0.95, 0.85, 0.35)
	if angry():
		body_col = Color(0.75, 0.12, 0.35)
	if _flash > 0.0:
		body_col = Color.WHITE
	if _entering:
		# flicker while arriving
		body_col.a = 0.4 + (sin(_time * 30.0) + 1.0) * 0.3

	var hw := BODY_W / 2.0
	var hh := BODY_H / 2.0
	var squash := sin(_time * 4.0) * 3.0

	# Horns
	draw_colored_polygon(PackedVector2Array([
		Vector2(-hw + 6, -hh + 6), Vector2(-hw + 26, -hh + 8), Vector2(-hw + 12, -hh - 22)]), horn_col)
	draw_colored_polygon(PackedVector2Array([
		Vector2(hw - 6, -hh + 6), Vector2(hw - 26, -hh + 8), Vector2(hw - 12, -hh - 22)]), horn_col)

	# Body
	draw_rect(Rect2(-hw, -hh + squash, BODY_W, BODY_H - squash), body_col)

	# Eyes (looking the way it walks)
	var eye_shift := facing * 4.0
	var eye_col := Color(1, 1, 0.3) if not angry() else Color(1, 0.3, 0.3)
	draw_circle(Vector2(-19 + eye_shift, -22), 11.0, Color(1, 1, 1, 0.95))
	draw_circle(Vector2(19 + eye_shift, -22), 11.0, Color(1, 1, 1, 0.95))
	draw_circle(Vector2(-19 + eye_shift * 2.0, -22), 5.5, eye_col)
	draw_circle(Vector2(19 + eye_shift * 2.0, -22), 5.5, eye_col)

	# Angry eyebrows
	var brow := Color(0.1, 0.05, 0.1)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-31, -40), Vector2(-8, -32), Vector2(-8, -27), Vector2(-31, -33)]), brow)
	draw_colored_polygon(PackedVector2Array([
		Vector2(31, -40), Vector2(8, -32), Vector2(8, -27), Vector2(31, -33)]), brow)

	# Big toothy mouth
	draw_rect(Rect2(-26, 4, 52, 18), Color(0.1, 0.05, 0.1))
	for i in 5:
		var x := -24.0 + i * 11.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, 4), Vector2(x + 9, 4), Vector2(x + 4.5, 15)]), Color.WHITE)
