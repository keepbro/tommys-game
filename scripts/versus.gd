extends Node2D

# VERSUS MODE! Two players, one keyboard, one screen - shoot each other.
# The whole arena fits on one screen so nobody can run away and hide.
#
#   PLAYER 1 (you):  A / D move, W or SPACE jump, SHIFT dash,
#                    MOUSE aim, LEFT CLICK shoot
#   PLAYER 2 (them): LEFT / RIGHT move, UP jump, CTRL dash,
#                    ENTER shoot (their gun aims at you by itself)

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const POWERUP := preload("res://scripts/powerup.gd")
const Teams := preload("res://scripts/teams.gd")
const MENU_SCENE := "res://scenes/menu.tscn"

const START_HEALTH := 5
const DROP_TIME := 6.0        # a new weapon or medkit appears this often

# A symmetrical arena - both players get exactly the same platforms
const PLATFORMS := [
	[Vector2(640, 700), Vector2(1300, 40)],    # the floor
	[Vector2(250, 545), Vector2(260, 20)],
	[Vector2(1030, 545), Vector2(260, 20)],
	[Vector2(640, 470), Vector2(280, 20)],
	[Vector2(140, 380), Vector2(200, 20)],
	[Vector2(1140, 380), Vector2(200, 20)],
	[Vector2(640, 265), Vector2(240, 20)],
	[Vector2(400, 180), Vector2(160, 20)],
	[Vector2(880, 180), Vector2(160, 20)],
]

const DROP_SPOTS := [
	Vector2(640, 420), Vector2(250, 495), Vector2(1030, 495),
	Vector2(640, 215), Vector2(140, 330), Vector2(1140, 330),
	Vector2(400, 130), Vector2(880, 130),
]

const DROPS := ["ak", "ar", "smg", "shotgun", "machinegun", "rocket", "laser",
	"medkit", "speed", "rapid", "triple"]

var p1: CharacterBody2D
var p2: CharacterBody2D
var winner := ""
var _drop_timer := 3.0
var _time := 0.0
var _hud: Control

func _ready() -> void:
	get_tree().paused = false
	_build_arena()
	_spawn_players()

	# ONE camera showing the whole arena, so both players stay on screen
	var cam := Camera2D.new()
	cam.position = Vector2(640, 360)
	add_child(cam)
	cam.make_current()

	_hud = VersusHud.new()
	_hud.match_node = self
	var layer := CanvasLayer.new()
	add_child(layer)
	layer.add_child(_hud)

func _build_arena() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(-100, -100)
	bg.size = Vector2(1480, 920)
	bg.color = Color(0.07, 0.06, 0.14)
	bg.z_index = -10
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for p in PLATFORMS:
		_platform(p[0], p[1], Color(0.32, 0.34, 0.48))

	# invisible walls all the way round - including the bottom, because
	# in versus there is nowhere to fall to
	_wall(Vector2(-40, 360), Vector2(80, 1000))
	_wall(Vector2(1320, 360), Vector2(80, 1000))
	_wall(Vector2(640, -40), Vector2(1440, 80))
	_wall(Vector2(640, 800), Vector2(1440, 80))

func _platform(pos: Vector2, size: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	add_child(body)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)

	var h := size / 2.0
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	visual.color = color
	body.add_child(visual)
	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([
		Vector2(-h.x, -h.y), Vector2(h.x, -h.y),
		Vector2(h.x, -h.y + 5.0), Vector2(-h.x, -h.y + 5.0)])
	top.color = color.lightened(0.35)
	body.add_child(top)

func _wall(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	add_child(body)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)

func _spawn_players() -> void:
	# Player 1 wears your chosen team. Player 2 gets a different colour
	# so you can always tell who is who.
	var team1: String = Sfx.team
	var team2: String = "red" if team1 != "red" else "blue"

	p1 = _make_player("p1", Vector2(170, 620), team1, Sfx.username)
	p2 = _make_player("p2", Vector2(1110, 620), team2, Sfx.opponent_name())

func _make_player(scheme: String, at: Vector2, team_id: String, who: String) -> CharacterBody2D:
	var pl := PLAYER_SCENE.instantiate()
	pl.controls = scheme
	pl.instant_powerups = true
	pl.player_name = who
	pl.position = at
	add_child(pl)

	pl.health = START_HEALTH
	pl.get_node("Camera").enabled = false     # the arena camera does the job
	var team: Dictionary = Teams.get_team(team_id)
	pl.ARMOUR = team["armour"]
	pl.ARMOUR_LIGHT = team["light"]
	pl.ARMOUR_DARK = team["dark"]
	pl.CLOTH = team["cape"]
	pl.set_meta("team_color", team["armour"])
	pl.died.connect(func(): _on_player_died(pl))
	return pl

func _process(delta: float) -> void:
	_time += delta
	if winner != "":
		return

	_drop_timer -= delta
	if _drop_timer <= 0.0:
		_drop_timer = DROP_TIME
		_drop_something()

func _drop_something() -> void:
	var item: Area2D = POWERUP.new()
	item.kind = DROPS[randi() % DROPS.size()]
	item.position = DROP_SPOTS[randi() % DROP_SPOTS.size()]
	add_child.call_deferred(item)
	Sfx.play("unlock", 1.4, -6.0)

func _on_player_died(loser: Node) -> void:
	if winner != "":
		return
	winner = p2.player_name if loser == p1 else p1.player_name
	Sfx.play("win")
	_hud.show_winner(winner, (p2 if loser == p1 else p1).get_meta("team_color"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MENU_SCENE)
	# ENTER restarts once somebody has won
	if winner != "" and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()

# ---------- The versus scoreboard ----------

class VersusHud extends Control:
	var match_node: Node2D
	var _winner := ""
	var _winner_color := Color.WHITE
	var _time := 0.0
	# We remember each player's last state, because once somebody is beaten
	# their knight is removed from the level and we can't ask it anything.
	var _p1 := {"name": "P1", "color": Color.WHITE, "hearts": 5, "gun": ""}
	var _p2 := {"name": "P2", "color": Color.WHITE, "hearts": 5, "gun": ""}

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func show_winner(name: String, color: Color) -> void:
		_winner = name
		_winner_color = color

	func _process(delta: float) -> void:
		_time += delta
		if is_instance_valid(match_node.p1):
			_remember(match_node.p1, _p1)
		else:
			_p1["hearts"] = 0
		if is_instance_valid(match_node.p2):
			_remember(match_node.p2, _p2)
		else:
			_p2["hearts"] = 0
		queue_redraw()

	func _remember(pl: Node, info: Dictionary) -> void:
		info["name"] = pl.player_name
		info["color"] = pl.get_meta("team_color")
		info["hearts"] = maxi(pl.health, 0)
		var gun: String = str(pl.weapon).to_upper()
		if pl.ammo >= 0:
			gun += "  %d" % pl.ammo
		info["gun"] = gun

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		_draw_player_bar(font, _p1, Vector2(24, 24), false)
		_draw_player_bar(font, _p2, Vector2(1256, 24), true)

		if _winner == "":
			draw_string(font, Vector2(600, 706), "ESC to quit",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.35))
			return

		# somebody won!
		draw_rect(Rect2(0, 250, 1280, 220), Color(0, 0, 0, 0.72))
		var text := _winner + " WINS!"
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x
		var bounce := sin(_time * 4.0) * 5.0
		draw_string(font, Vector2(640.0 - w / 2.0, 350.0 + bounce), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 64, _winner_color.lightened(0.3))
		var again := "ENTER to play again        ESC for the title screen"
		var aw := font.get_string_size(again, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		draw_string(font, Vector2(640.0 - aw / 2.0, 420.0), again,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.85))

	func _draw_player_bar(font: Font, info: Dictionary, at: Vector2, right_side: bool) -> void:
		var color: Color = info["color"]
		var name: String = info["name"]
		var hearts: int = info["hearts"]

		var name_w := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		var x := at.x - name_w if right_side else at.x
		draw_string(font, Vector2(x, at.y + 22), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, color)

		# a row of hearts underneath
		for i in 5:
			var hx := (at.x - 26.0 - i * 30.0) if right_side else (at.x + i * 30.0)
			var full := i < hearts
			var c := Color(1, 0.3, 0.4) if full else Color(1, 1, 1, 0.18)
			draw_circle(Vector2(hx + 7, at.y + 46), 6.0, c)
			draw_circle(Vector2(hx + 17, at.y + 46), 6.0, c)
			draw_colored_polygon(PackedVector2Array([
				Vector2(hx, at.y + 48), Vector2(hx + 24, at.y + 48),
				Vector2(hx + 12, at.y + 64)]), c)

		# what gun they're holding
		var gun: String = info["gun"]
		var gw := font.get_string_size(gun, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		var gx := at.x - gw if right_side else at.x
		draw_string(font, Vector2(gx, at.y + 88), gun, HORIZONTAL_ALIGNMENT_LEFT, -1, 17,
			Color(1, 1, 1, 0.75))
