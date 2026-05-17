extends CharacterBody2D

const SPEED := 320.0
const JUMP_FORCE := -520.0
const DOUBLE_JUMP_FORCE := -480.0
const GRAVITY := 1300.0
const DASH_SPEED := 750.0
const DASH_TIME := 0.15
const WALL_SLIDE_SPEED := 60.0
const WALL_JUMP_PUSH := 340.0

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

var bullet_scene := preload("res://scenes/bullet.tscn")

signal health_changed(h: int)
signal score_changed(s: int)
signal died

@onready var gun_pivot: Node2D = $GunPivot
@onready var muzzle: Marker2D = $GunPivot/Muzzle
@onready var sprite: ColorRect = $Sprite
@onready var coyote_timer: Timer = $CoyoteTimer

func _ready() -> void:
	add_to_group("player")
	coyote_timer.timeout.connect(func(): coyote_ok = false)

func _physics_process(delta: float) -> void:
	if position.y > 950:
		health = 0
		health_changed.emit(0)
		died.emit()
		queue_free()
		return

	shoot_cooldown = maxf(0.0, shoot_cooldown - delta)
	wall_jump_cooldown = maxf(0.0, wall_jump_cooldown - delta)
	invincible_timer = maxf(0.0, invincible_timer - delta)
	dash_timer = maxf(0.0, dash_timer - delta)

	var mouse := get_global_mouse_position()
	gun_pivot.look_at(mouse)
	facing = -1.0 if mouse.x < global_position.x else 1.0
	sprite.scale.x = facing

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

	if is_dashing:
		velocity.x = dash_dir * DASH_SPEED
		velocity.y = 0.0
	elif wall_jump_cooldown <= 0.0:
		var dir := Input.get_axis("ui_left", "ui_right")
		velocity.x = move_toward(velocity.x, dir * SPEED, SPEED * 12.0 * delta)

	if dash_timer <= 0.0:
		is_dashing = false

	if Input.is_action_just_pressed("jump"):
		if coyote_ok:
			velocity.y = JUMP_FORCE
			coyote_ok = false
		elif on_wall_only and wall_jump_cooldown <= 0.0:
			velocity.y = JUMP_FORCE
			velocity.x = get_wall_normal().x * WALL_JUMP_PUSH
			wall_jump_cooldown = 0.25
			can_double_jump = true
		elif can_double_jump:
			velocity.y = DOUBLE_JUMP_FORCE
			can_double_jump = false

	if Input.is_action_just_pressed("dash") and not is_dashing:
		is_dashing = true
		dash_timer = DASH_TIME
		var dir := Input.get_axis("ui_left", "ui_right")
		dash_dir = dir if dir != 0.0 else facing

	if Input.is_action_pressed("shoot") and shoot_cooldown == 0.0:
		_shoot()

	move_and_slide()

func _shoot() -> void:
	shoot_cooldown = 0.18
	var b := bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = muzzle.global_position
	b.direction = (get_global_mouse_position() - muzzle.global_position).normalized()

func take_damage() -> void:
	if invincible_timer > 0.0:
		return
	health -= 1
	invincible_timer = 1.0
	health_changed.emit(health)
	if health <= 0:
		died.emit()
		queue_free()

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)
