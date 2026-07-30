extends Node2D

# THE LEVELS! Each one is a different shape with its own colours,
# monsters, chests and boss. After the last one it starts again, harder.

static var level := 1

const MAX_ENEMIES := 12
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const CHEST := preload("res://scripts/chest.gd")
const POWERUP := preload("res://scripts/powerup.gd")
const BOSS := preload("res://scripts/boss.gd")
const HUD := preload("res://scripts/hud.gd")
const EXIT_PORTAL := preload("res://scripts/exit_portal.gd")

# Every level is a list of instructions for building it.
# Platform types: "ground" (thick floor), "plat" (ledge), "wall" (for wall jumps)
const LEVELS := [
	{
		"name": "GREEN HILLS",
		"bg": Color(0.08, 0.08, 0.18),
		"ground_color": Color(0.42, 0.32, 0.18),
		"plat_color": Color(0.25, 0.60, 0.25),
		"wall_color": Color(0.50, 0.50, 0.55),
		"start": Vector2(100, 640),
		"exit": Vector2(1450, 505),
		"boss_at": Vector2(1330, 600),
		"camera": Rect2(-200, -300, 2200, 1080),
		"kinds": ["goblin", "slime"],
		"platforms": [
			[Vector2(700, 700), Vector2(2400, 40), "ground"],
			[Vector2(300, 560), Vector2(260, 20), "plat"],
			[Vector2(580, 470), Vector2(220, 20), "plat"],
			[Vector2(400, 380), Vector2(200, 20), "plat"],
			[Vector2(820, 420), Vector2(240, 20), "plat"],
			[Vector2(860, 300), Vector2(180, 20), "plat"],
			[Vector2(1100, 350), Vector2(260, 20), "plat"],
			[Vector2(680, 200), Vector2(200, 20), "plat"],
			[Vector2(1220, 210), Vector2(220, 20), "plat"],
			[Vector2(-60, 380), Vector2(120, 780), "wall"],
			[Vector2(748, 390), Vector2(120, 600), "wall"],
			[Vector2(1450, 560), Vector2(160, 20), "plat"],
		],
		"spawns": [
			Vector2(300, 500), Vector2(580, 410), Vector2(400, 320),
			Vector2(820, 360), Vector2(860, 240), Vector2(1100, 290),
			Vector2(680, 140), Vector2(1220, 150),
		],
		"chests": [Vector2(300, 550), Vector2(1100, 340)],
		"items": [[Vector2(680, 160), "medkit"], [Vector2(860, 260), "rapid"]],
	},
	{
		"name": "SKY TOWERS",
		"bg": Color(0.10, 0.06, 0.22),
		"ground_color": Color(0.30, 0.26, 0.40),
		"plat_color": Color(0.45, 0.35, 0.75),
		"wall_color": Color(0.60, 0.55, 0.70),
		"start": Vector2(140, 660),
		"exit": Vector2(1520, 245),
		"boss_at": Vector2(1450, 640),
		"camera": Rect2(-200, -400, 2300, 1180),
		"kinds": ["goblin", "bat", "slime"],
		# MIND THE GAP! There is a big hole in the middle - don't fall in.
		"platforms": [
			[Vector2(240, 720), Vector2(760, 40), "ground"],
			[Vector2(1450, 720), Vector2(900, 40), "ground"],
			[Vector2(300, 430), Vector2(140, 20), "plat"],
			[Vector2(520, 610), Vector2(150, 20), "plat"],
			[Vector2(720, 520), Vector2(150, 20), "plat"],
			[Vector2(920, 420), Vector2(150, 20), "plat"],
			[Vector2(1120, 320), Vector2(150, 20), "plat"],
			[Vector2(620, 280), Vector2(130, 20), "plat"],
			[Vector2(880, 160), Vector2(180, 20), "plat"],
			[Vector2(1330, 500), Vector2(180, 20), "plat"],
			[Vector2(-60, 400), Vector2(120, 900), "wall"],
			[Vector2(640, 420), Vector2(40, 200), "wall"],
			[Vector2(1010, 260), Vector2(40, 280), "wall"],
			[Vector2(1520, 300), Vector2(170, 20), "plat"],
		],
		"spawns": [
			Vector2(300, 370), Vector2(520, 550), Vector2(720, 460),
			Vector2(920, 360), Vector2(1120, 260), Vector2(880, 100),
			Vector2(1330, 440), Vector2(1000, 560),
		],
		"chests": [Vector2(920, 410), Vector2(1330, 490)],
		"items": [[Vector2(620, 230), "medkit"], [Vector2(880, 110), "speed"]],
	},
	{
		"name": "ICE CAVES",
		"bg": Color(0.05, 0.14, 0.20),
		"ground_color": Color(0.30, 0.45, 0.55),
		"plat_color": Color(0.55, 0.80, 0.90),
		"wall_color": Color(0.40, 0.60, 0.72),
		"start": Vector2(120, 620),
		"exit": Vector2(1480, 345),
		"boss_at": Vector2(1250, 600),
		"camera": Rect2(-200, -300, 2200, 1080),
		"kinds": ["slime", "bat", "brute"],
		# Low ceilings and narrow ledges - tight squeeze!
		"platforms": [
			[Vector2(700, 700), Vector2(2400, 40), "ground"],
			[Vector2(260, 560), Vector2(180, 20), "plat"],
			[Vector2(470, 470), Vector2(120, 20), "plat"],
			[Vector2(660, 560), Vector2(120, 20), "plat"],
			[Vector2(850, 470), Vector2(120, 20), "plat"],
			[Vector2(1050, 560), Vector2(130, 20), "plat"],
			[Vector2(380, 300), Vector2(160, 20), "plat"],
			[Vector2(700, 240), Vector2(200, 20), "plat"],
			[Vector2(1030, 300), Vector2(160, 20), "plat"],
			[Vector2(-60, 380), Vector2(120, 780), "wall"],
			[Vector2(560, 130), Vector2(900, 60), "wall"],
			[Vector2(1180, 430), Vector2(40, 300), "wall"],
			[Vector2(1300, 560), Vector2(40, 300), "wall"],
			[Vector2(1480, 400), Vector2(180, 20), "plat"],
		],
		"spawns": [
			Vector2(260, 500), Vector2(470, 410), Vector2(660, 500),
			Vector2(850, 410), Vector2(1050, 500), Vector2(380, 240),
			Vector2(700, 180), Vector2(1030, 240),
		],
		"chests": [Vector2(700, 230), Vector2(1050, 550)],
		"items": [[Vector2(380, 250), "medkit"], [Vector2(1030, 250), "triple"]],
	},
	{
		"name": "LAVA FORTRESS",
		"bg": Color(0.18, 0.05, 0.06),
		"ground_color": Color(0.30, 0.12, 0.10),
		"plat_color": Color(0.55, 0.20, 0.15),
		"wall_color": Color(0.35, 0.30, 0.32),
		"start": Vector2(110, 640),
		"exit": Vector2(1500, 205),
		"boss_at": Vector2(1200, 620),
		"camera": Rect2(-200, -400, 2300, 1180),
		"kinds": ["goblin", "bat", "brute", "slime"],
		# The hardest one - stairs up a fortress with the boss at the bottom
		"platforms": [
			[Vector2(700, 700), Vector2(2400, 40), "ground"],
			[Vector2(280, 590), Vector2(200, 20), "plat"],
			[Vector2(540, 500), Vector2(160, 20), "plat"],
			[Vector2(300, 400), Vector2(160, 20), "plat"],
			[Vector2(560, 300), Vector2(160, 20), "plat"],
			[Vector2(820, 380), Vector2(200, 20), "plat"],
			[Vector2(1060, 470), Vector2(180, 20), "plat"],
			[Vector2(1260, 360), Vector2(160, 20), "plat"],
			[Vector2(1040, 240), Vector2(180, 20), "plat"],
			[Vector2(760, 150), Vector2(200, 20), "plat"],
			[Vector2(-60, 380), Vector2(120, 780), "wall"],
			[Vector2(680, 460), Vector2(40, 320), "wall"],
			[Vector2(940, 570), Vector2(40, 220), "wall"],
			[Vector2(1400, 300), Vector2(40, 340), "wall"],
			[Vector2(1500, 260), Vector2(180, 20), "plat"],
		],
		"spawns": [
			Vector2(280, 530), Vector2(540, 440), Vector2(300, 340),
			Vector2(560, 240), Vector2(820, 320), Vector2(1060, 410),
			Vector2(1260, 300), Vector2(1040, 180), Vector2(760, 90),
		],
		"chests": [Vector2(560, 290), Vector2(1040, 230), Vector2(1260, 350)],
		"items": [[Vector2(760, 100), "medkit"], [Vector2(300, 350), "medkit"]],
	},
]

var spawn_timer := 0.0
var spawn_interval := 3.0
var level_finished := false
var boss_beaten := false
var boss_spawned := false
var data: Dictionary = {}
var portal: Node2D = null
var boss_node: Node2D = null
var hud: Control = null

@onready var player: CharacterBody2D = $Player
@onready var score_label: Label = $UI/ScoreLabel
@onready var health_label: Label = $UI/HealthLabel
@onready var game_over: Label = $UI/GameOver
@onready var level_label: Label = $UI/LevelLabel
@onready var background: ColorRect = $Background

func _ready() -> void:
	# Pick which level shape to build (it loops round after the last one)
	data = LEVELS[(level - 1) % LEVELS.size()]

	player.health_changed.connect(_update_health)
	player.score_changed.connect(_update_score)
	player.died.connect(_on_player_died)

	_update_health(player.health)
	_update_score(player.score)
	game_over.visible = false

	# Difficulty scales with level
	spawn_interval = maxf(0.8, 3.0 - (level - 1) * 0.25)
	spawn_timer = spawn_interval
	level_label.text = "Level %d - %s" % [level, data["name"]]

	background.color = data["bg"]
	player.position = data["start"]
	_set_camera_limits(data["camera"])

	_build_level()
	_create_exit()
	_place_chests()
	_place_items()
	_create_hud()

func _create_hud() -> void:
	hud = HUD.new()
	hud.player = player
	$UI.add_child(hud)
	player.message.connect(func(text: String, col: Color): hud.show_message(text, col))

func _set_camera_limits(area: Rect2) -> void:
	var cam: Camera2D = player.get_node("Camera")
	cam.limit_left = int(area.position.x)
	cam.limit_top = int(area.position.y)
	cam.limit_right = int(area.end.x)
	cam.limit_bottom = int(area.end.y)

func _build_level() -> void:
	for p in data["platforms"]:
		var color: Color = data["ground_color"]
		if p[2] == "plat":
			color = data["plat_color"]
		elif p[2] == "wall":
			color = data["wall_color"]
		_platform(p[0], p[1], color)

func _place_chests() -> void:
	for pos in data["chests"]:
		var chest: StaticBody2D = CHEST.new()
		chest.position = pos
		add_child(chest)

func _place_items() -> void:
	for item in data["items"]:
		var pickup: Area2D = POWERUP.new()
		pickup.kind = item[1]
		pickup.position = item[0]
		add_child(pickup)

func _create_exit() -> void:
	var exit := Area2D.new()
	exit.position = data["exit"]
	add_child(exit)

	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(56, 110)
	cs.shape = shape
	exit.add_child(cs)

	portal = EXIT_PORTAL.new()
	portal.locked = true          # the boss has the key!
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

	# A lighter strip on top so platforms look solid, not flat
	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([
		Vector2(-h.x, -h.y), Vector2(h.x, -h.y),
		Vector2(h.x, -h.y + 5.0), Vector2(-h.x, -h.y + 5.0),
	])
	top.color = color.lightened(0.35)
	body.add_child(top)

func _process(delta: float) -> void:
	if not is_instance_valid(player) or level_finished:
		return

	# The boss wakes up when you get near its lair
	if not boss_spawned and player.global_position.distance_to(data["boss_at"]) < 620.0:
		_spawn_boss()

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		spawn_interval = maxf(0.8, spawn_interval - 0.1)
		spawn_timer = spawn_interval

func _spawn_enemy() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= MAX_ENEMIES:
		return
	var enemy := ENEMY_SCENE.instantiate()
	# each level has its own mix of monsters
	enemy.kind = data["kinds"][randi() % data["kinds"].size()]
	var spawns: Array = data["spawns"]
	enemy.position = spawns[randi() % spawns.size()]
	add_child(enemy)
	enemy.died.connect(func(pts: int): _on_enemy_died(pts, enemy.global_position))

func _on_enemy_died(points: int, where: Vector2) -> void:
	if is_instance_valid(player):
		player.add_score(points)
	# Sometimes a monster drops something useful
	var roll := randf()
	var drop := ""
	if roll < 0.10:
		drop = "medkit"
	elif roll < 0.16:
		drop = ["rapid", "triple", "speed"][randi() % 3]
	elif roll < 0.19:
		drop = "heart"
	if drop != "":
		var pickup: Area2D = POWERUP.new()
		pickup.kind = drop
		add_child(pickup)
		pickup.global_position = where

func _spawn_boss() -> void:
	boss_spawned = true
	boss_node = BOSS.new()
	boss_node.max_health = 12 + (level - 1) * 4
	boss_node.position = data["boss_at"]
	add_child(boss_node)
	boss_node.died.connect(_on_boss_died)
	hud.boss = boss_node
	hud.show_message("BOSS FIGHT!", Color(1, 0.3, 0.3))
	if is_instance_valid(player):
		player.shake(10.0)

func _on_boss_died(points: int) -> void:
	boss_beaten = true
	if is_instance_valid(player):
		player.add_score(points)
	portal.locked = false
	Sfx.play("unlock")
	hud.show_message("EXIT UNLOCKED! RUN FOR IT!", Color(0.4, 1, 0.6))

func _on_exit_reached(body: Node2D) -> void:
	if not body.is_in_group("player") or level_finished:
		return
	if not boss_beaten:
		# Locked! Beat the boss first.
		if hud:
			hud.show_message("BEAT THE BOSS FIRST!", Color(1, 0.5, 0.4))
		return

	level_finished = true
	level += 1
	Sfx.play("win")

	var lbl := Label.new()
	lbl.text = "LEVEL COMPLETE!"
	lbl.position = Vector2(340, 280)
	lbl.add_theme_font_size_override("font_size", 52)
	lbl.modulate = Color(0.3, 1.0, 0.5)
	$UI.add_child(lbl)

	var next := Label.new()
	next.text = "Next up: " + LEVELS[(level - 1) % LEVELS.size()]["name"]
	next.position = Vector2(380, 360)
	next.add_theme_font_size_override("font_size", 30)
	next.modulate = Color(1, 1, 0.6)
	$UI.add_child(next)

	await get_tree().create_timer(2.5).timeout
	get_tree().reload_current_scene()

func _update_health(h: int) -> void:
	health_label.text = "Hearts: " + "♥ ".repeat(maxi(h, 0))

func _update_score(s: int) -> void:
	score_label.text = "Score: " + str(s)

func _on_player_died() -> void:
	level = 1
	game_over.visible = true
	Sfx.play("lose")
	await get_tree().create_timer(2.5).timeout
	get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
