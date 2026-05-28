extends CharacterBody2D

const SPEED := 80.0
const CHASE_SPEED := 130.0
const GRAVITY := 1200.0

var direction := 1.0
var patrol_time := 2.0
var patrol_timer := 0.0
var reverse_cooldown := 0.0
var bounce_cooldown := 0.0
var player_ref: Node2D = null
var spawn_protected := true
var blink_timer := 0.0

signal died(points)

@onready var edge_ray: RayCast2D = $EdgeRay

func _ready() -> void:
	add_to_group("enemies")
	patrol_time = randf_range(1.5, 3.0)
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
	# Spawn sparkle effect
	var SpawnEffect := load("res://scripts/spawn_effect.gd")
	var effect: Node2D = SpawnEffect.new()
	get_tree().current_scene.add_child(effect)
	effect.global_position = global_position
	# Blink for 1.5s then become dangerous
	await get_tree().create_timer(1.5).timeout
	spawn_protected = false
	$Sprite.visible = true

func _physics_process(delta: float) -> void:
	reverse_cooldown = maxf(0.0, reverse_cooldown - delta)
	bounce_cooldown = maxf(0.0, bounce_cooldown - delta)
	# Blink while spawn protected
	if spawn_protected:
		blink_timer += delta
		if blink_timer >= 0.12:
			blink_timer = 0.0
			$Sprite.visible = !$Sprite.visible

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Chase the player if close enough, otherwise patrol
	var chasing := false
	if player_ref and is_instance_valid(player_ref):
		var dist := global_position.distance_to(player_ref.global_position)
		if dist < 320.0:
			direction = sign(player_ref.global_position.x - global_position.x)
			velocity.x = direction * CHASE_SPEED
			chasing = true

	if not chasing:
		# Move edge ray to check for platform edge ahead
		edge_ray.position.x = 16.0 * direction
		# Reverse at edges or walls
		if reverse_cooldown <= 0.0 and (is_on_wall() or (is_on_floor() and not edge_ray.is_colliding())):
			direction *= -1
			patrol_timer = 0.0
			patrol_time = randf_range(1.5, 3.0)
			reverse_cooldown = 0.4
		patrol_timer += delta
		velocity.x = direction * SPEED

	$Sprite.scale.x = direction
	move_and_slide()

	# Check every frame if player is touching us
	for body in $DamageZone.get_overlapping_bodies():
		if body.is_in_group("player") and bounce_cooldown <= 0.0 and not spawn_protected:
			body.take_damage()
			var bounce_dir: Vector2 = (global_position - body.global_position).normalized()
			velocity.x = bounce_dir.x * 420.0
			velocity.y = -380.0
			bounce_cooldown = 0.8

func take_damage() -> void:
	died.emit(100)
	queue_free()
