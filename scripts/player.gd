extends CharacterBody2D

const SPEED := 320.0
const JUMP_FORCE := -520.0
const DOUBLE_JUMP_FORCE := -480.0
const GRAVITY := 1300.0
const DASH_SPEED := 750.0
const DASH_TIME := 0.15
const WALL_SLIDE_SPEED := 60.0
const WALL_JUMP_PUSH := 340.0
const MAX_HEALTH := 5
const BAG_SLOTS := 5

# Power-up settings: how long each one lasts
const POWERUP_TIME := {"rapid": 8.0, "triple": 10.0, "speed": 8.0}
const SPEED_BOOST := 1.6
const RAPID_MULTIPLIER := 0.35   # rapid fire makes any gun shoot this much faster

# All the guns! ammo of -1 means it never runs out.
const WEAPONS := {
	"pistol": {
		"cooldown": 0.18, "bullets": 1, "spread": 0.0, "damage": 1, "speed": 900.0,
		"ammo": -1, "pierce": false, "color": Color(1.0, 0.75, 0.1), "size": 5.0,
		"kick": 25.0, "shake": 2.5, "pitch": 1.0, "gun_size": Vector2(22, 6),
		"gun_color": Color(0.7, 0.7, 0.7),
	},
	"shotgun": {
		"cooldown": 0.55, "bullets": 5, "spread": 0.34, "damage": 1, "speed": 820.0,
		"ammo": 20, "pierce": false, "color": Color(1.0, 0.6, 0.2), "size": 5.0,
		"kick": 120.0, "shake": 9.0, "pitch": 0.55, "gun_size": Vector2(26, 9),
		"gun_color": Color(0.55, 0.35, 0.18),
	},
	"machinegun": {
		"cooldown": 0.07, "bullets": 1, "spread": 0.09, "damage": 1, "speed": 1050.0,
		"ammo": 90, "pierce": false, "color": Color(0.95, 0.9, 0.6), "size": 4.0,
		"kick": 12.0, "shake": 2.0, "pitch": 1.35, "gun_size": Vector2(30, 7),
		"gun_color": Color(0.45, 0.47, 0.55),
	},
	"smg": {
		# tiny and SUPER fast, but sprays all over the place
		"cooldown": 0.055, "bullets": 1, "spread": 0.13, "damage": 1, "speed": 950.0,
		"ammo": 110, "pierce": false, "color": Color(1.0, 0.95, 0.7), "size": 4.0,
		"kick": 9.0, "shake": 1.8, "pitch": 1.7, "gun_size": Vector2(20, 8),
		"gun_color": Color(0.2, 0.22, 0.26),
	},
	"ar": {
		# super accurate, very fast, lots of ammo
		"cooldown": 0.085, "bullets": 1, "spread": 0.025, "damage": 1, "speed": 1200.0,
		"ammo": 120, "pierce": false, "color": Color(0.85, 0.95, 1.0), "size": 4.5,
		"kick": 14.0, "shake": 2.2, "pitch": 1.5, "gun_size": Vector2(34, 7),
		"gun_color": Color(0.25, 0.28, 0.3),
	},
	"ak": {
		# hits harder than the AR but kicks around more
		"cooldown": 0.11, "bullets": 1, "spread": 0.075, "damage": 2, "speed": 1100.0,
		"ammo": 80, "pierce": false, "color": Color(1.0, 0.8, 0.35), "size": 5.5,
		"kick": 26.0, "shake": 3.4, "pitch": 1.15, "gun_size": Vector2(34, 8),
		"gun_color": Color(0.5, 0.32, 0.16),
	},
	"rocket": {
		"cooldown": 0.9, "bullets": 1, "spread": 0.0, "damage": 3, "speed": 620.0,
		"ammo": 8, "pierce": false, "color": Color(1.0, 0.4, 0.2), "size": 7.0,
		"kick": 160.0, "shake": 8.0, "pitch": 0.4, "gun_size": Vector2(30, 11),
		"gun_color": Color(0.3, 0.4, 0.3), "is_rocket": true,
	},
	"laser": {
		"cooldown": 0.32, "bullets": 1, "spread": 0.0, "damage": 3, "speed": 1600.0,
		"ammo": 25, "pierce": true, "color": Color(0.4, 1.0, 0.9), "size": 6.0,
		"kick": 15.0, "shake": 4.0, "pitch": 1.8, "gun_size": Vector2(28, 8),
		"gun_color": Color(0.3, 0.55, 0.6),
	},
}

# Which keys this player uses.
#   "solo" - the normal one-player game (WASD or arrows, mouse to aim)
#   "p1"   - versus player 1: A/D, W to jump, mouse to aim
#   "p2"   - versus player 2: arrow keys, and aims at the other player
const CONTROLS := {
	"solo": {"left": "ui_left", "right": "ui_right", "jump": "jump",
		"dash": "dash", "shoot": "shoot"},
	"p1": {"left": "p1_left", "right": "p1_right", "jump": "p1_jump",
		"dash": "p1_dash", "shoot": "p1_shoot"},
	"p2": {"left": "p2_left", "right": "p2_right", "jump": "p2_jump",
		"dash": "p2_dash", "shoot": "p2_shoot"},
}

var controls := "solo"
var instant_powerups := false   # in versus there's no bag, items work straight away
var player_name := "PLAYER"

var _aim := Vector2.RIGHT       # the point in the world we're aiming at
var can_double_jump := true
var is_dashing := false
var dash_timer := 0.0
var dash_dir := 1.0
var wall_jump_cooldown := 0.0
var shoot_cooldown := 0.0
var health := 3
var score := 0
var invincible_timer := 0.0
var facing := 1.0
var coyote_ok := false

# Which power-ups are switched on, and how much time is left on each
var powerups := {"rapid": 0.0, "triple": 0.0, "speed": 0.0}

# Your bag! Press 1-5 to use what's inside.
var inventory: Array[String] = []

var weapon := "pistol"
var ammo := -1

var _shake_amount := 0.0
var _walk_cycle := 0.0
var _hurt_blink := false
var _body_alpha := 1.0
var _time := 0.0

var bullet_scene := preload("res://scenes/bullet.tscn")

signal health_changed(h: int)
signal score_changed(s: int)
signal powerups_changed(active: Dictionary)
signal inventory_changed(items: Array)
signal weapon_changed(name: String, ammo: int)
signal message(text: String, color: Color)
signal died

@onready var gun_pivot: Node2D = $GunPivot
@onready var gun_rect: ColorRect = $GunPivot/Gun
@onready var muzzle: Marker2D = $GunPivot/Muzzle
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var camera: Camera2D = $Camera

func _ready() -> void:
	add_to_group("player")
	coyote_timer.timeout.connect(func(): coyote_ok = false)
	_wear_team_colours()
	_equip("pistol")

# Put on the armour of whichever team was chosen on the TEAM screen
func _wear_team_colours() -> void:
	var team: Dictionary = load("res://scripts/teams.gd").get_team(Sfx.team)
	ARMOUR = team["armour"]
	ARMOUR_LIGHT = team["light"]
	ARMOUR_DARK = team["dark"]
	CLOTH = team["cape"]

# Wobble the camera! Called when things explode or you get hurt.
func shake(amount: float) -> void:
	_shake_amount = maxf(_shake_amount, amount)

func _process(delta: float) -> void:
	_time += delta

	# Camera shake calms back down over time. In versus both players share
	# one camera, so we shake whichever camera is actually being used.
	var cam := get_viewport().get_camera_2d()
	if cam:
		if _shake_amount > 0.05:
			cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_amount
			_shake_amount = move_toward(_shake_amount, 0.0, delta * 55.0)
		else:
			cam.offset = cam.offset.move_toward(Vector2.ZERO, delta * 200.0)

	# Flash white and flicker while you can't be hurt
	_hurt_blink = false
	_body_alpha = 1.0
	if invincible_timer > 0.0:
		if int(invincible_timer * 14.0) % 2 == 0:
			_hurt_blink = true
		else:
			_body_alpha = 0.4
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	# Number keys 1-5 use whatever is in that bag slot
	for i in BAG_SLOTS:
		if event.is_action_pressed("slot_%d" % (i + 1)):
			use_item(i)

func _physics_process(delta: float) -> void:
	if position.y > 950:
		health = 0
		health_changed.emit(0)
		Sfx.play("hurt", 0.7)
		died.emit()
		queue_free()
		return

	var keys: Dictionary = CONTROLS[controls]
	shoot_cooldown = maxf(0.0, shoot_cooldown - delta)
	wall_jump_cooldown = maxf(0.0, wall_jump_cooldown - delta)
	invincible_timer = maxf(0.0, invincible_timer - delta)
	dash_timer = maxf(0.0, dash_timer - delta)
	_tick_powerups(delta)

	_aim = _aim_point()
	gun_pivot.look_at(_aim)
	facing = -1.0 if _aim.x < global_position.x else 1.0
	# legs run faster the faster you go
	_walk_cycle += absf(velocity.x) * delta * 0.045

	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 1200.0)

	if is_on_floor():
		coyote_ok = true
		can_double_jump = true
		coyote_timer.stop()
		coyote_timer.start()

	var on_wall_only := is_on_wall_only()
	if on_wall_only and velocity.y > WALL_SLIDE_SPEED:
		velocity.y = WALL_SLIDE_SPEED

	var move_speed := SPEED * (SPEED_BOOST if powerups["speed"] > 0.0 else 1.0)

	if is_dashing:
		velocity.x = dash_dir * DASH_SPEED
		velocity.y = 0.0
	elif wall_jump_cooldown <= 0.0:
		var dir := Input.get_axis(keys["left"], keys["right"])
		velocity.x = move_toward(velocity.x, dir * move_speed, move_speed * 12.0 * delta)

	if dash_timer <= 0.0:
		is_dashing = false

	if Input.is_action_just_pressed(keys["jump"]):
		if coyote_ok:
			velocity.y = JUMP_FORCE
			coyote_ok = false
			Sfx.play("jump")
		elif on_wall_only and wall_jump_cooldown <= 0.0:
			velocity.y = JUMP_FORCE
			velocity.x = get_wall_normal().x * WALL_JUMP_PUSH
			wall_jump_cooldown = 0.25
			can_double_jump = true
			Sfx.play("jump", 1.2)
		elif can_double_jump:
			velocity.y = DOUBLE_JUMP_FORCE
			can_double_jump = false
			Sfx.play("double_jump")
			_puff(Color(0.6, 0.8, 1.0))

	if Input.is_action_just_pressed(keys["dash"]) and not is_dashing:
		is_dashing = true
		dash_timer = DASH_TIME
		var dir := Input.get_axis(keys["left"], keys["right"])
		dash_dir = dir if dir != 0.0 else facing
		Sfx.play("dash")
		shake(3.0)
		_puff(Color(1, 1, 1))

	if Input.is_action_pressed(keys["shoot"]) and shoot_cooldown == 0.0:
		_shoot()

	move_and_slide()

# Where this player is aiming. Player 1 uses the mouse; player 2 has no
# mouse, so their gun tracks the other player automatically.
func _aim_point() -> Vector2:
	if controls != "p2":
		return get_global_mouse_position()
	var foe := _find_foe()
	if foe:
		return foe.global_position
	return global_position + Vector2(facing * 200.0, 0.0)

func _find_foe() -> Node2D:
	for other in get_tree().get_nodes_in_group("player"):
		if other != self and is_instance_valid(other):
			return other
	return null

func _tick_powerups(delta: float) -> void:
	var changed := false
	for key in powerups:
		if powerups[key] > 0.0:
			powerups[key] = maxf(0.0, powerups[key] - delta)
			if powerups[key] == 0.0:
				changed = true
	if changed:
		powerups_changed.emit(powerups)

# ---------- Picking things up ----------

# Returns false if we couldn't take it (bag full), so the item stays put.
func collect_powerup(kind: String) -> bool:
	if kind == "heart":
		health = mini(health + 1, MAX_HEALTH)
		health_changed.emit(health)
		message.emit("+1 HEART", Color(1, 0.4, 0.5))
	elif WEAPONS.has(kind):
		_equip(kind)
		message.emit(kind.to_upper() + "!", WEAPONS[kind]["color"])
	elif instant_powerups:
		# versus mode has no bag - grab it and it works straight away
		if kind == "medkit":
			health = mini(health + 2, MAX_HEALTH)
			health_changed.emit(health)
		else:
			powerups[kind] = POWERUP_TIME[kind]
			powerups_changed.emit(powerups)
		message.emit(kind.to_upper() + "!", Color(0.8, 1.0, 0.6))
	else:
		if inventory.size() >= BAG_SLOTS:
			message.emit("BAG FULL!", Color(1, 0.6, 0.2))
			return false
		inventory.append(kind)
		inventory_changed.emit(inventory)
		message.emit("PICKED UP " + kind.to_upper(), Color(0.8, 0.9, 1))
	shake(4.0)
	return true

# Use whatever is in bag slot number `index`
func use_item(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	var item: String = inventory[index]

	if item == "medkit":
		if health >= MAX_HEALTH:
			message.emit("ALREADY FULL HEALTH", Color(0.8, 0.8, 0.8))
			return
		health = mini(health + 2, MAX_HEALTH)
		health_changed.emit(health)
		message.emit("HEALED +2", Color(0.4, 1, 0.5))
		_puff(Color(0.4, 1, 0.5))
	else:
		powerups[item] = POWERUP_TIME[item]
		powerups_changed.emit(powerups)
		message.emit(item.to_upper() + " ON!", Color(1, 0.9, 0.4))

	inventory.remove_at(index)
	inventory_changed.emit(inventory)
	Sfx.play("powerup", 1.2)

func _equip(name: String) -> void:
	weapon = name
	ammo = WEAPONS[name]["ammo"]
	var stats: Dictionary = WEAPONS[name]
	gun_rect.size = stats["gun_size"]
	gun_rect.position = Vector2(0, -stats["gun_size"].y / 2.0)
	gun_rect.color = stats["gun_color"]
	weapon_changed.emit(weapon, ammo)

# ---------- Shooting ----------

func _shoot() -> void:
	var stats: Dictionary = WEAPONS[weapon]
	var cooldown: float = stats["cooldown"]
	if powerups["rapid"] > 0.0:
		cooldown *= RAPID_MULTIPLIER
	shoot_cooldown = cooldown

	var aim := (_aim - muzzle.global_position).normalized()

	# Work out all the angles we're firing at
	var angles: Array[float] = []
	var count: int = stats["bullets"]
	var spread: float = stats["spread"]
	for i in count:
		var t := 0.0 if count == 1 else float(i) / float(count - 1) - 0.5
		angles.append(t * spread * 2.0 + randf_range(-spread, spread) * 0.15)
	# Triple shot power-up adds two extra angled shots to ANY weapon
	if powerups["triple"] > 0.0:
		angles.append_array([-0.22, 0.22])

	for a in angles:
		if stats.get("is_rocket", false):
			var Rocket := load("res://scripts/rocket.gd")
			var r: Area2D = Rocket.new()
			r.direction = aim.rotated(a)
			r.shooter = self
			get_tree().current_scene.add_child(r)
			r.global_position = muzzle.global_position
		else:
			var b := bullet_scene.instantiate()
			b.direction = aim.rotated(a)
			b.shooter = self
			b.speed = stats["speed"]
			b.damage = stats["damage"]
			b.pierce = stats["pierce"]
			b.color = stats["color"]
			b.size = stats["size"]
			get_tree().current_scene.add_child(b)
			b.global_position = muzzle.global_position

	# Muzzle flash
	var flash: Node2D = load("res://scripts/explosion.gd").new()
	flash.colors = [stats["color"], Color.WHITE]
	flash.count = 4
	flash.speed_max = 120.0
	flash.size_max = 7.0
	flash.gravity = 0.0
	flash.max_lifetime = 0.15
	get_tree().current_scene.add_child(flash)
	flash.global_position = muzzle.global_position

	Sfx.play("shoot", stats["pitch"] * randf_range(0.95, 1.08), -4.0)
	shake(stats["shake"])
	velocity -= aim * stats["kick"]   # guns kick you backwards!

	# Use up a bullet. Run out and you drop back to the trusty pistol.
	if ammo > 0:
		ammo -= 1
		weapon_changed.emit(weapon, ammo)
		if ammo == 0:
			message.emit("OUT OF AMMO", Color(1, 0.5, 0.5))
			_equip("pistol")

func _puff(color: Color) -> void:
	var Explosion := load("res://scripts/explosion.gd")
	var burst: Node2D = Explosion.new()
	burst.colors = [color, Color.WHITE]
	burst.count = 7
	burst.speed_max = 160.0
	burst.size_max = 8.0
	burst.gravity = 60.0
	burst.max_lifetime = 0.35
	get_tree().current_scene.add_child(burst)
	burst.global_position = global_position

func take_damage(amount := 1) -> void:
	if invincible_timer > 0.0:
		return
	health -= amount
	invincible_timer = 1.0
	health_changed.emit(health)
	Sfx.play("hurt")
	shake(12.0)
	if health <= 0:
		died.emit()
		queue_free()

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

# ---------- Drawing the hero ----------
# A human knight in green armour, drawn with code so he can
# run, jump, dash and wall-slide with proper poses.

const TRIM := Color(0.90, 0.80, 0.35)      # gold trim
const SKIN := Color(0.96, 0.78, 0.62)
const VISOR := Color(0.35, 0.95, 1.00)     # glowing blue visor

# These come from whichever team you picked on the TEAM screen
var ARMOUR := Color(0.20, 0.62, 0.32)
var ARMOUR_LIGHT := Color(0.38, 0.85, 0.48)
var ARMOUR_DARK := Color(0.10, 0.36, 0.20)
var CLOTH := Color(0.55, 0.18, 0.22)       # his cape

func _draw() -> void:
	# Flip everything to face the way he's aiming
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))

	var running := absf(velocity.x) > 20.0 and is_on_floor()
	var swing := sin(_walk_cycle * 6.0) * (9.0 if running else 0.0)
	var bob := absf(sin(_walk_cycle * 6.0)) * 1.6 if running else 0.0
	var airborne := not is_on_floor()

	# Idle breathing so he's never totally still
	var breathe := sin(_time * 2.5) * 0.7 if not running and not airborne else 0.0
	var lean := clampf(velocity.x * facing * 0.012, -3.5, 3.5)

	_draw_shadow()
	_draw_cape(swing, lean)
	_draw_legs(swing, bob, airborne)
	_draw_torso(bob, breathe, lean)
	_draw_arms(swing, bob, lean, airborne)
	_draw_head(bob, breathe, lean)

	if is_dashing:
		_draw_dash_streaks()
	if is_on_wall_only() and velocity.y > 0.0:
		_draw_wall_sparks()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Colours get brighter when hurt, greener when speed-boosted
func _tint(base: Color) -> Color:
	var c := base
	if _hurt_blink:
		c = Color.WHITE
	elif powerups["speed"] > 0.0:
		c = c.lerp(Color(0.5, 1.0, 0.6), 0.35)
	c.a = base.a * _body_alpha
	return c

func _draw_shadow() -> void:
	draw_set_transform(Vector2(0, 24), 0.0, Vector2(facing, 0.28))
	draw_circle(Vector2.ZERO, 13.0, Color(0, 0, 0, 0.32))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))

func _draw_cape(swing: float, lean: float) -> void:
	# The cape flutters more the faster he moves
	var flap := sin(_time * 9.0) * 3.0 + swing * 0.6 - velocity.x * facing * 0.02
	var cape := _tint(CLOTH)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -10 + lean), Vector2(6, -10 + lean),
		Vector2(9 - flap * 0.6, 8), Vector2(2 - flap, 18 + flap * 0.3),
		Vector2(-9 - flap * 1.2, 14 + flap * 0.4),
	]), cape)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -10 + lean), Vector2(2, -10 + lean),
		Vector2(-2 - flap * 0.8, 6), Vector2(-9 - flap * 1.2, 14 + flap * 0.4),
	]), _tint(CLOTH.darkened(0.3)))

func _draw_legs(swing: float, bob: float, airborne: bool) -> void:
	var boot := _tint(Color(0.28, 0.22, 0.18))
	var leg := _tint(ARMOUR_DARK)
	var knee := _tint(ARMOUR)

	for side: float in [-1.0, 1.0]:
		var kick := swing * side
		if airborne:
			# tuck the front leg up when jumping
			kick = 7.0 * side if velocity.y < 0.0 else 4.0 * side
		var hip := Vector2(side * 5.0, 8.0 - bob)
		var foot := Vector2(side * 5.0 + kick * 0.55, 23.0 - absf(kick) * 0.12)

		# thigh + shin
		draw_line(hip, hip.lerp(foot, 0.55), leg, 8.0)
		draw_line(hip.lerp(foot, 0.55), foot, leg, 6.5)
		# knee guard
		draw_circle(hip.lerp(foot, 0.55), 3.4, knee)
		# boot
		draw_rect(Rect2(foot.x - 5.0, foot.y - 1.5, 11.0, 5.0), boot)
		draw_rect(Rect2(foot.x - 5.0, foot.y - 1.5, 11.0, 2.0), _tint(TRIM.darkened(0.35)))

func _draw_torso(bob: float, breathe: float, lean: float) -> void:
	var top := -9.0 - bob + breathe * 0.3
	var plate := _tint(ARMOUR)

	# chest plate (narrower at the waist, like a real breastplate)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11 + lean, top), Vector2(11 + lean, top),
		Vector2(9, 9.0 - bob), Vector2(-9, 9.0 - bob),
	]), plate)
	# lighter panel down the middle so it looks curved
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3 + lean, top), Vector2(5 + lean, top),
		Vector2(4, 8.0 - bob), Vector2(-2, 8.0 - bob),
	]), _tint(ARMOUR_LIGHT))
	# gold belt
	draw_rect(Rect2(-9.5, 6.0 - bob, 19.0, 4.0), _tint(TRIM))
	draw_rect(Rect2(-2.0, 5.5 - bob, 4.5, 5.0), _tint(TRIM.lightened(0.3)))
	# shading along the bottom edge
	draw_line(Vector2(-9, 4.0 - bob), Vector2(9, 4.0 - bob), Color(0, 0, 0, 0.15 * _body_alpha), 3.0)

func _draw_arms(swing: float, bob: float, lean: float, airborne: bool) -> void:
	var arm := _tint(ARMOUR_DARK)
	var pauldron := _tint(ARMOUR_LIGHT)
	var glove := _tint(Color(0.22, 0.20, 0.24))

	# Back arm swings when running
	var back_swing := -swing * 0.5
	if airborne:
		back_swing = -6.0
	var back_shoulder := Vector2(-9 + lean, -6.0 - bob)
	var back_hand := back_shoulder + Vector2(-3.0 + back_swing * 0.4, 12.0)
	draw_line(back_shoulder, back_hand, arm.darkened(0.25), 6.0)
	draw_circle(back_hand, 3.2, glove.darkened(0.2))
	draw_circle(back_shoulder, 5.5, pauldron.darkened(0.25))

	# Front arm reaches out to hold the gun (the gun node sits at y = -4)
	var shoulder := Vector2(8 + lean, -6.0 - bob)
	var grip := Vector2(13.0, -4.0)
	draw_line(shoulder, grip, arm, 6.5)
	draw_circle(grip, 3.4, glove)
	# shoulder pad with a gold rivet
	draw_circle(shoulder, 6.5, pauldron)
	draw_arc(shoulder, 6.5, PI, TAU, 12, _tint(TRIM), 2.0)

func _draw_head(bob: float, breathe: float, lean: float) -> void:
	var y := -19.0 - bob + breathe * 0.4
	var head := Vector2(1.0 + lean * 1.2, y)
	var helm := _tint(ARMOUR)

	# neck
	draw_rect(Rect2(-3.5 + lean, y + 6.0, 7.0, 5.0), _tint(SKIN.darkened(0.25)))
	# face
	draw_circle(head, 8.0, _tint(SKIN))
	# chin strap shadow
	draw_arc(head, 8.0, 0.3, PI - 0.3, 12, Color(0, 0, 0, 0.18 * _body_alpha), 2.0)
	# eyes
	draw_circle(head + Vector2(2.0, 0.5), 1.6, Color(0.1, 0.1, 0.15, _body_alpha))
	draw_circle(head + Vector2(-2.6, 0.5), 1.3, Color(0.1, 0.1, 0.15, _body_alpha))
	# little determined mouth
	draw_line(head + Vector2(-1.0, 4.2), head + Vector2(3.5, 4.2),
		Color(0.6, 0.35, 0.3, _body_alpha), 1.4)

	# HELMET - an OPEN-FACE dome so you can still see him in there
	# half a circle for the dome, closed straight across the brow
	var dome := PackedVector2Array()
	for i in 15:
		var a := PI + PI * (float(i) / 14.0)
		dome.append(head + Vector2(cos(a) * 10.2, sin(a) * 10.6) + Vector2(0, -1.0))
	draw_colored_polygon(dome, helm)
	# gold trim along the brow
	draw_line(head + Vector2(-10.2, -1.0), head + Vector2(10.2, -1.0), _tint(TRIM), 2.8)
	# glowing gem on the front of the helmet
	draw_circle(head + Vector2(3.0, -5.5), 2.3, _tint(VISOR))
	draw_circle(head + Vector2(3.0, -5.5), 1.0, Color(1, 1, 1, 0.9 * _body_alpha))
	# cheek guards framing his face
	for cheek: float in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([
			head + Vector2(cheek * 9.4, -3.0), head + Vector2(cheek * 6.0, -3.0),
			head + Vector2(cheek * 6.6, 4.5), head + Vector2(cheek * 9.0, 2.5),
		]), _tint(ARMOUR_DARK))
	# the crest / mohawk on top
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-4.5, -9.0), head + Vector2(3.0, -10.0),
		head + Vector2(1.5, -16.0), head + Vector2(-4.0, -13.5),
	]), _tint(CLOTH))
	# shiny highlight on the metal
	draw_circle(head + Vector2(-3.5, -6.0), 2.4, Color(1, 1, 1, 0.3 * _body_alpha))

func _draw_dash_streaks() -> void:
	# speed lines trailing behind while dashing
	for i in 4:
		var x := -18.0 - i * 9.0
		var a := (1.0 - i / 4.0) * 0.5
		draw_line(Vector2(x * dash_dir * facing, -8.0 + i * 6.0),
			Vector2((x - 14.0) * dash_dir * facing, -8.0 + i * 6.0),
			Color(0.7, 1.0, 0.9, a), 2.5)

func _draw_wall_sparks() -> void:
	# sparks fly off his armour when he slides down a wall
	var wall_side := -signf(get_wall_normal().x) * facing
	for i in 3:
		var y := 4.0 + i * 7.0 + sin(_time * 22.0 + i) * 3.0
		draw_circle(Vector2(wall_side * 12.0, y), randf_range(1.2, 2.6),
			Color(1.0, 0.85, 0.4, 0.8))
