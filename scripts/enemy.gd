extends CharacterBody2D

# FOUR different monsters, all drawn with code so they can wiggle!
#
#   goblin - red, runs along platforms and chases you
#   slime  - green blob, hops up and down, squishy
#   bat    - purple, FLIES through the air straight at you
#   brute  - big blue armoured guy, slow but takes 3 shots to kill

const KINDS := ["goblin", "slime", "bat", "brute"]

const STATS := {
	"goblin": {"speed": 80.0, "chase": 130.0, "health": 1, "points": 100, "sight": 320.0},
	"slime": {"speed": 55.0, "chase": 95.0, "health": 1, "points": 75, "sight": 260.0},
	"bat": {"speed": 105.0, "chase": 160.0, "health": 1, "points": 125, "sight": 480.0},
	"brute": {"speed": 45.0, "chase": 70.0, "health": 3, "points": 250, "sight": 380.0},
}

const GRAVITY := 1200.0

var kind := "goblin"
var health := 1
var direction := 1.0
var patrol_time := 2.0
var patrol_timer := 0.0
var reverse_cooldown := 0.0
var bounce_cooldown := 0.0
var player_ref: Node2D = null
var spawn_protected := true
var blink_timer := 0.0
var visible_now := false   # used for the spawn-in blinking
var walk_cycle := 0.0
var hurt_flash := 0.0
var hop_timer := 0.0
var squash := 0.0          # slimes squash when they land
var _time := 0.0

signal died(points)

@onready var edge_ray: RayCast2D = $EdgeRay

func _ready() -> void:
	add_to_group("enemies")
	health = STATS[kind]["health"]
	patrol_time = randf_range(1.5, 3.0)
	_time = randf() * 10.0  # so they don't all wobble in sync

	if kind == "brute":
		_grow(18.0, 62.0, Vector2(44, 62))

	await get_tree().process_frame
	if not is_inside_tree():
		return
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
	if not is_inside_tree():
		return  # we got shot while blinking!
	spawn_protected = false
	visible_now = true

# Give this monster its own bigger body (brutes are chunky!)
func _grow(radius: float, height: float, zone: Vector2) -> void:
	var capsule := CapsuleShape2D.new()
	capsule.radius = radius
	capsule.height = height
	$CollisionShape2D.shape = capsule
	var box := RectangleShape2D.new()
	box.size = zone
	$DamageZone/CollisionShape2D.shape = box

func _physics_process(delta: float) -> void:
	# Fell down a pit - remove it so it doesn't fall forever
	if global_position.y > 1100.0:
		queue_free()
		return

	_time += delta
	reverse_cooldown = maxf(0.0, reverse_cooldown - delta)
	bounce_cooldown = maxf(0.0, bounce_cooldown - delta)
	hurt_flash = maxf(0.0, hurt_flash - delta)
	squash = move_toward(squash, 0.0, delta * 4.0)

	# Blink while spawn protected
	if spawn_protected:
		blink_timer += delta
		if blink_timer >= 0.12:
			blink_timer = 0.0
			visible_now = not visible_now

	var stats: Dictionary = STATS[kind]
	var seen := _can_see_player(stats["sight"])

	if kind == "bat":
		_fly(delta, seen, stats)
	else:
		_walk(delta, seen, stats)

	walk_cycle += absf(velocity.x) * delta * 0.05
	var was_on_floor := is_on_floor()
	move_and_slide()
	if kind == "slime" and not was_on_floor and is_on_floor():
		squash = 1.0  # splat!
	queue_redraw()

	# Check every frame if player is touching us
	for body in $DamageZone.get_overlapping_bodies():
		if body.is_in_group("player") and bounce_cooldown <= 0.0 and not spawn_protected:
			body.take_damage()
			var bounce_dir: Vector2 = (global_position - body.global_position).normalized()
			velocity.x = bounce_dir.x * 420.0
			velocity.y = -380.0
			bounce_cooldown = 0.8

func _can_see_player(sight: float) -> bool:
	if player_ref == null or not is_instance_valid(player_ref):
		return false
	return global_position.distance_to(player_ref.global_position) < sight

# Ground monsters: goblin, slime and brute
func _walk(delta: float, seen: bool, stats: Dictionary) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if seen:
		direction = signf(player_ref.global_position.x - global_position.x)

	var speed: float = stats["chase"] if seen else stats["speed"]

	if kind == "slime":
		# Slimes can only move while hopping - boing, boing!
		hop_timer -= delta
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			if hop_timer <= 0.0:
				velocity.y = -430.0
				velocity.x = direction * speed * 1.6
				hop_timer = randf_range(0.8, 1.4) if not seen else 0.7
				squash = -0.7  # stretch upward as it leaps
	else:
		velocity.x = direction * speed

	if not seen:
		# Move edge ray to check for platform edge ahead
		edge_ray.position.x = 16.0 * direction
		# Reverse at edges or walls
		if reverse_cooldown <= 0.0 and (is_on_wall() or (is_on_floor() and not edge_ray.is_colliding())):
			direction *= -1
			patrol_timer = 0.0
			patrol_time = randf_range(1.5, 3.0)
			reverse_cooldown = 0.4
		patrol_timer += delta

# Bats ignore gravity and swoop at you
func _fly(delta: float, seen: bool, stats: Dictionary) -> void:
	var target_vel: Vector2
	if seen:
		var to_player := (player_ref.global_position - global_position).normalized()
		target_vel = to_player * stats["chase"]
		# wobbly flapping path instead of a boring straight line
		target_vel.y += sin(_time * 7.0) * 60.0
	else:
		target_vel = Vector2(direction * stats["speed"], sin(_time * 2.0) * 40.0)
		if is_on_wall() and reverse_cooldown <= 0.0:
			direction *= -1
			reverse_cooldown = 0.4
	velocity = velocity.move_toward(target_vel, 400.0 * delta)
	if velocity.x != 0.0:
		direction = signf(velocity.x)

func take_damage(amount := 1) -> void:
	health -= amount
	hurt_flash = 0.12

	if health > 0:
		# Hurt but not dead - flash and squeak
		Sfx.play("boss_hurt", 1.6)
		var Explosion := load("res://scripts/explosion.gd")
		var bits: Node2D = Explosion.new()
		bits.colors = [_main_color(), Color.WHITE]
		bits.count = 5
		bits.max_lifetime = 0.25
		bits.speed_max = 150.0
		get_tree().current_scene.add_child(bits)
		bits.global_position = global_position
		return

	# POP! Burst into bits the same colour as the monster
	var Explosion := load("res://scripts/explosion.gd")
	var burst: Node2D = Explosion.new()
	burst.colors = [_main_color(), _main_color().lightened(0.4), Color(1, 1, 0.9)]
	burst.count = 14
	burst.ring = true
	get_tree().current_scene.add_child(burst)
	burst.global_position = global_position

	Sfx.play("pop", randf_range(0.9, 1.15))
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].shake(5.0 if kind != "brute" else 9.0)

	died.emit(STATS[kind]["points"])
	queue_free()

func _main_color() -> Color:
	match kind:
		"goblin": return Color(0.85, 0.22, 0.22)
		"slime": return Color(0.35, 0.85, 0.35)
		"bat": return Color(0.6, 0.35, 0.85)
		"brute": return Color(0.35, 0.5, 0.8)
	return Color.WHITE

# ---------- Drawing ----------

func _draw() -> void:
	if not visible_now:
		return
	match kind:
		"goblin": _draw_goblin()
		"slime": _draw_slime()
		"bat": _draw_bat()
		"brute": _draw_brute()

# Where the eyes should point (they follow you around!)
func _look_dir(from: Vector2) -> Vector2:
	if player_ref and is_instance_valid(player_ref):
		return (player_ref.global_position - global_position - from).normalized()
	return Vector2(direction, 0.0)

func _shade(base: Color) -> Color:
	return Color.WHITE if hurt_flash > 0.0 else base

func _shadow(y: float, size: float) -> void:
	draw_set_transform(Vector2(0, y), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, size, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_goblin() -> void:
	var skin := _shade(Color(0.85, 0.22, 0.22))
	var dark := _shade(Color(0.62, 0.13, 0.16))
	var light := _shade(Color(1.0, 0.42, 0.36))
	var f := direction
	var swing := sin(walk_cycle * 6.0) * 6.0
	var bob := absf(sin(walk_cycle * 6.0)) * 2.0

	_shadow(21.0, 15.0)

	# Legs swing as it runs
	for side: float in [-1.0, 1.0]:
		var lift := swing * side
		draw_colored_polygon(PackedVector2Array([
			Vector2(side * 7 - 4, 6 - bob), Vector2(side * 7 + 4, 6 - bob),
			Vector2(side * 7 + 4 + lift * 0.4, 20), Vector2(side * 7 - 4 + lift * 0.4, 20)]), dark)
		draw_rect(Rect2(side * 7 - 5 + lift * 0.4, 17, 14, 4), Color(0.35, 0.2, 0.15))

	# Arms
	for side: float in [-1.0, 1.0]:
		var lift := -swing * side
		draw_colored_polygon(PackedVector2Array([
			Vector2(side * 12, -8 - bob), Vector2(side * 16, -8 - bob),
			Vector2(side * 17 + lift * 0.3, 4 + lift * 0.5), Vector2(side * 13 + lift * 0.3, 4 + lift * 0.5)]), dark)
		draw_circle(Vector2(side * 15 + lift * 0.3, 5 + lift * 0.5), 3.5, Color(0.3, 0.15, 0.12))

	# Body and belly
	draw_circle(Vector2(0, -4 - bob), 13.0, skin)
	draw_circle(Vector2(0, 0 - bob), 11.0, skin)
	_round_shade(Vector2(0, 0 - bob), 12.0)
	draw_circle(Vector2(f * 1.5, 1 - bob), 7.0, light)

	# Head with pointy ears
	var head := Vector2(f * 1.5, -18.0 - bob)
	draw_circle(head, 12.0, skin)
	_round_shade(head, 12.0, 0.18)
	draw_arc(head, 12.0, 0.0, TAU, 24, Color(0, 0, 0, 0.25), 1.2)
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-9, -3), head + Vector2(-14, -13), head + Vector2(-4, -7)]), dark)
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(9, -3), head + Vector2(14, -13), head + Vector2(4, -7)]), dark)
	draw_circle(head + Vector2(-3, -4), 5.0, Color(light.r, light.g, light.b, 0.45))

	_draw_eyes(head, 5.0, 4.2, 2.1, Color(1, 1, 0.85))
	_draw_brows(head, Color(0.3, 0.08, 0.08))

	# Grumpy mouth with two fangs
	draw_rect(Rect2(head.x - 6, head.y + 4, 12, 4), Color(0.2, 0.05, 0.06))
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-5, 4), head + Vector2(-2, 4), head + Vector2(-3.5, 9)]), Color.WHITE)
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(2, 4), head + Vector2(5, 4), head + Vector2(3.5, 9)]), Color.WHITE)

func _draw_slime() -> void:
	var goo := _shade(Color(0.35, 0.85, 0.35, 0.92))
	var goo_dark := _shade(Color(0.2, 0.6, 0.25, 0.95))
	# squash > 0 means flat (just landed), < 0 means stretched (jumping)
	var w := 1.0 + squash * 0.35
	var h := 1.0 - squash * 0.35
	var wobble := sin(_time * 8.0) * 0.04

	_shadow(21.0, 15.0 * w)

	# Wobbly blob body
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU / 20.0 * i
		var r := 17.0 + sin(a * 3.0 + _time * 6.0) * 1.5
		pts.append(Vector2(cos(a) * r * (w + wobble), sin(a) * r * h * 0.95 + 3.0))
	draw_colored_polygon(pts, goo)

	# Darker goo puddle at the bottom
	draw_set_transform(Vector2(0, 14), 0.0, Vector2(w, h * 0.5))
	draw_circle(Vector2.ZERO, 13.0, goo_dark)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Shiny highlight so it looks wet
	draw_circle(Vector2(-6 * w, -6 * h), 4.0, Color(1, 1, 1, 0.55))
	draw_circle(Vector2(-4 * w, -9 * h), 1.8, Color(1, 1, 1, 0.8))
	_round_shade(Vector2(0, 3), 16.0 * w, 0.16)
	# little goo drips running down the sides
	for i in 3:
		var dx := (-10.0 + i * 10.0) * w
		draw_circle(Vector2(dx, 12.0 + sin(_time * 3.0 + i) * 2.0), 2.5, goo_dark)

	var head := Vector2(0, -2)
	_draw_eyes(head, 6.0, 5.0, 2.4, Color.WHITE)
	# Little smiley slime mouth
	draw_arc(head + Vector2(0, 6), 5.0, 0.2, PI - 0.2, 12, Color(0.1, 0.3, 0.1), 2.0)

func _draw_bat() -> void:
	var fur := _shade(Color(0.6, 0.35, 0.85))
	var fur_dark := _shade(Color(0.38, 0.2, 0.6))
	var flap := sin(_time * 14.0)

	# Flapping wings
	for side: float in [-1.0, 1.0]:
		var tip := Vector2(side * 30.0, -6.0 + flap * 12.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(side * 6, -6), tip, Vector2(side * 24, 6 + flap * 6.0), Vector2(side * 8, 4)]), fur_dark)
		# wing bones
		draw_line(Vector2(side * 6, -6), tip, Color(0.25, 0.12, 0.4), 1.5)

	# Fuzzy body
	draw_circle(Vector2(0, -2), 11.0, fur)
	draw_circle(Vector2(0, 3), 8.0, fur)
	# Ears
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -10), Vector2(-3, -8), Vector2(-7, -22)]), fur_dark)
	draw_colored_polygon(PackedVector2Array([
		Vector2(8, -10), Vector2(3, -8), Vector2(7, -22)]), fur_dark)

	var head := Vector2(0, -4)
	_draw_eyes(head, 4.5, 3.8, 2.0, Color(1, 0.95, 0.6))
	# Tiny fangs
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-3, 5), head + Vector2(-1, 5), head + Vector2(-2, 9)]), Color.WHITE)
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(1, 5), head + Vector2(3, 5), head + Vector2(2, 9)]), Color.WHITE)

func _draw_brute() -> void:
	var armour := _shade(Color(0.35, 0.5, 0.8))
	var armour_dark := _shade(Color(0.2, 0.3, 0.55))
	var metal := _shade(Color(0.7, 0.75, 0.85))
	var f := direction
	var swing := sin(walk_cycle * 4.0) * 5.0
	var bob := absf(sin(walk_cycle * 4.0)) * 2.0
	# Cracks appear as you damage it!
	var hurt_bits := 3 - health

	_shadow(31.0, 22.0)

	# Thick stompy legs
	for side: float in [-1.0, 1.0]:
		var lift := swing * side
		draw_rect(Rect2(side * 10 - 7, 10 - bob, 14, 20 + lift * 0.3), armour_dark)
		draw_rect(Rect2(side * 10 - 9, 27, 20, 5), Color(0.15, 0.15, 0.2))

	# Big armoured chest
	draw_rect(Rect2(-20, -14 - bob, 40, 30), armour)
	draw_rect(Rect2(-20, -14 - bob, 40, 7), metal)   # shoulder plate
	# Cracks from damage
	for i in hurt_bits:
		var cx := -12.0 + i * 11.0
		draw_line(Vector2(cx, -8 - bob), Vector2(cx + 5, 8 - bob), Color(0.1, 0.1, 0.15), 2.0)

	# Massive arms
	for side: float in [-1.0, 1.0]:
		var lift := -swing * side
		draw_rect(Rect2(side * 24 - 6, -12 - bob + lift * 0.3, 12, 24), armour_dark)
		draw_circle(Vector2(side * 24, 13 - bob + lift * 0.3), 7.0, metal)

	# Helmet head with a visor slit
	var head := Vector2(f * 2.0, -26.0 - bob)
	draw_circle(head, 14.0, armour)
	draw_rect(Rect2(head.x - 12, head.y - 3, 24, 7), Color(0.1, 0.1, 0.15))
	# Glowing eyes inside the visor
	var glow := Color(1, 0.4, 0.2) if _can_see_player(STATS["brute"]["sight"]) else Color(1, 0.85, 0.3)
	draw_circle(head + Vector2(-5, 0.5), 2.4, glow)
	draw_circle(head + Vector2(5, 0.5), 2.4, glow)
	# Helmet crest
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-2, -14), head + Vector2(2, -14), head + Vector2(0, -24)]), Color(0.9, 0.3, 0.3))

func _draw_eyes(head: Vector2, spread: float, size: float, pupil: float, white: Color) -> void:
	var look := _look_dir(head)
	for side: float in [-1.0, 1.0]:
		var eye := head + Vector2(side * spread, -1.0)
		# eye socket shadow makes the eye look sunken into the head
		draw_circle(eye + Vector2(0, 0.8), size * 1.15, Color(0, 0, 0, 0.18))
		draw_circle(eye, size, white)
		draw_circle(eye + look * (size * 0.45), pupil, Color(0.1, 0.05, 0.05))
		# shiny white dot - this is the trick that makes eyes look wet and alive
		draw_circle(eye + look * (size * 0.45) + Vector2(-pupil * 0.4, -pupil * 0.4),
			pupil * 0.38, Color(1, 1, 1, 0.9))
		draw_arc(eye, size, 0.0, TAU, 16, Color(0, 0, 0, 0.35), 1.0)

# A soft dark edge along the bottom of a round shape, so it looks 3D
func _round_shade(center: Vector2, radius: float, strength := 0.22) -> void:
	draw_arc(center, radius * 0.88, 0.35, PI - 0.35, 16, Color(0, 0, 0, strength), radius * 0.25)

func _draw_brows(head: Vector2, brow: Color) -> void:
	var drop := 2.0 if _can_see_player(STATS[kind]["sight"]) else 0.0
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-10, -8 + drop), head + Vector2(-2, -5 + drop),
		head + Vector2(-2, -3 + drop), head + Vector2(-10, -6 + drop)]), brow)
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(10, -8 + drop), head + Vector2(2, -5 + drop),
		head + Vector2(2, -3 + drop), head + Vector2(10, -6 + drop)]), brow)
