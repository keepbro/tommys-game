extends Node2D

static var level := 1

const MAX_ENEMIES := 12
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const SPAWN_POINTS := [
	Vector2(300, 500), Vector2(580, 410), Vector2(400, 320),
	Vector2(820, 360), Vector2(860, 240), Vector2(1100, 290),
	Vector2(680, 140), Vector2(1220, 150),
]

var spawn_timer := 0.0
var spawn_interval := 3.0
var level_finished := false

@onready var player: CharacterBody2D = $Player
@onready var score_label: Label = $UI/ScoreLabel
@onready var health_label: Label = $UI/HealthLabel
@onready var game_over: Label = $UI/GameOver
@onready var level_label: Label = $UI/LevelLabel

func _ready() -> void:
	player.health_changed.connect(_update_health)
	player.score_changed.connect(_update_score)
	player.died.connect(_on_player_died)

	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.died.connect(func(pts: int): player.add_score(pts))

	_update_health(player.health)
	_update_score(player.score)
	game_over.visible = false

	# Difficulty scales with level
	spawn_interval = maxf(0.8, 3.0 - (level - 1) * 0.25)
	spawn_timer = spawn_interval
	level_label.text = "Level " + str(level)

	_build_level()
	_create_exit()

func _build_level() -> void:
	var brown := Color(0.42, 0.32, 0.18)
	var green := Color(0.25, 0.60, 0.25)
	var grey := Color(0.50, 0.50, 0.55)

	_platform(Vector2(700, 700), Vector2(2400, 40), brown)
	_platform(Vector2(300, 560), Vector2(260, 20), green)
	_platform(Vector2(580, 470), Vector2(220, 20), green)
	_platform(Vector2(400, 380), Vector2(200, 20), green)
	_platform(Vector2(820, 420), Vector2(240, 20), green)
	_platform(Vector2(860, 300), Vector2(180, 20), green)
	_platform(Vector2(1100, 350), Vector2(260, 20), green)
	_platform(Vector2(680, 200), Vector2(200, 20), green)
	_platform(Vector2(1220, 210), Vector2(220, 20), green)
	_platform(Vector2(-60, 380), Vector2(120, 780), grey)
	_platform(Vector2(748, 390), Vector2(120, 600), grey)
	# Exit platform
	_platform(Vector2(1450, 560), Vector2(160, 20), Color(0.2, 0.8, 0.3))

func _create_exit() -> void:
	var exit := Area2D.new()
	exit.position = Vector2(1450, 505)
	add_child(exit)

	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(56, 110)
	cs.shape = shape
	exit.add_child(cs)

	var ExitPortal := load("res://scripts/exit_portal.gd")
	var portal: Node2D = ExitPortal.new()
	exit.add_child(portal)

	exit.body_entered.connect(_on_exit_reached)

func _platform(pos: Vector2, size: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	add_child(body)

	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)

	var visual := Polygon2D.new()
	var h := size / 2.0
	visual.polygon = PackedVector2Array([
		Vector2(-h.x, -h.y), Vector2(h.x, -h.y),
		Vector2(h.x, h.y), Vector2(-h.x, h.y),
	])
	visual.color = color
	body.add_child(visual)

func _process(delta: float) -> void:
	if not is_instance_valid(player) or level_finished:
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		spawn_interval = maxf(0.8, spawn_interval - 0.1)
		spawn_timer = spawn_interval

func _spawn_enemy() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= MAX_ENEMIES:
		return
	var enemy := ENEMY_SCENE.instantiate()
	enemy.position = SPAWN_POINTS[randi() % SPAWN_POINTS.size()]
	add_child(enemy)
	enemy.died.connect(func(pts: int): player.add_score(pts))

func _on_exit_reached(body: Node2D) -> void:
	if not body.is_in_group("player") or level_finished:
		return
	level_finished = true
	level += 1
	var lbl := Label.new()
	lbl.text = "LEVEL COMPLETE!"
	lbl.position = Vector2(340, 280)
	lbl.add_theme_font_size_override("font_size", 52)
	lbl.modulate = Color(0.3, 1.0, 0.5)
	$UI.add_child(lbl)
	await get_tree().create_timer(2.5).timeout
	get_tree().reload_current_scene()

func _update_health(h: int) -> void:
	health_label.text = "Hearts: " + "♥ ".repeat(maxi(h, 0))

func _update_score(s: int) -> void:
	score_label.text = "Score: " + str(s)

func _on_player_died() -> void:
	level = 1
	game_over.visible = true
	await get_tree().create_timer(2.5).timeout
	get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
