extends Node2D

const MAX_ENEMIES := 12
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const SPAWN_POINTS := [
	Vector2(300, 500), Vector2(580, 410), Vector2(400, 320),
	Vector2(820, 360), Vector2(860, 240), Vector2(1100, 290),
	Vector2(680, 140), Vector2(1220, 150),
]

var spawn_timer := 3.0
var spawn_interval := 3.0

@onready var player: CharacterBody2D = $Player
@onready var score_label: Label = $UI/ScoreLabel
@onready var health_label: Label = $UI/HealthLabel
@onready var game_over: Label = $UI/GameOver

func _ready() -> void:
	player.health_changed.connect(_update_health)
	player.score_changed.connect(_update_score)
	player.died.connect(_on_player_died)

	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.died.connect(func(pts: int): player.add_score(pts))

	_update_health(player.health)
	_update_score(player.score)
	game_over.visible = false

	_build_level()

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
	_platform(Vector2(-20, 380), Vector2(40, 500), grey)
	_platform(Vector2(740, 350), Vector2(40, 300), grey)

func _platform(pos: Vector2, size: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	add_child(body)

	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)

	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = Vector2(-size.x / 2.0, -size.y / 2.0)
	rect.size = size
	rect.color = color
	body.add_child(rect)

func _process(delta: float) -> void:
	if not is_instance_valid(player):
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

func _update_health(h: int) -> void:
	health_label.text = "Hearts: " + "♥ ".repeat(maxi(h, 0))

func _update_score(s: int) -> void:
	score_label.text = "Score: " + str(s)

func _on_player_died() -> void:
	game_over.visible = true
	await get_tree().create_timer(2.5).timeout
	get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
