extends StaticBody2D

# A treasure chest! Shoot it 3 times and it bursts open with loot inside.
# You can also stand on top of it.

const WIDTH := 54.0
const HEIGHT := 42.0
const LOOT_TABLE := [
	"ar", "ak", "smg", "shotgun", "machinegun", "rocket", "laser",   # better weapons!
	"medkit", "medkit", "heart",
	"rapid", "triple", "speed",
]

var health := 3
var opened := false
var _lid := 0.0        # how far the lid has swung open
var _flash := 0.0
var _shake := 0.0
var _time := 0.0

func _ready() -> void:
	add_to_group("chests")
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(WIDTH, HEIGHT)
	cs.shape = shape
	cs.position = Vector2(0, -HEIGHT / 2.0)
	add_child(cs)

func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(0.0, _flash - delta * 6.0)
	_shake = maxf(0.0, _shake - delta * 8.0)
	if opened and _lid < 1.0:
		_lid = minf(1.0, _lid + delta * 3.0)
	queue_redraw()

func take_damage(amount := 1) -> void:
	if opened:
		return
	health -= amount
	_flash = 1.0
	_shake = 1.0
	Sfx.play("boss_hurt", 1.9, -6.0)
	if health <= 0:
		_open()

func _open() -> void:
	opened = true
	Sfx.play("unlock")
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].shake(6.0)

	# Sparkly burst out of the top
	var Explosion := load("res://scripts/explosion.gd")
	var burst: Node2D = Explosion.new()
	burst.colors = [Color(1, 0.9, 0.3), Color(1, 1, 0.8), Color(0.9, 0.7, 0.2)]
	burst.count = 20
	burst.speed_max = 320.0
	burst.gravity = 250.0
	burst.max_lifetime = 0.8
	get_tree().current_scene.add_child(burst)
	burst.global_position = global_position + Vector2(0, -HEIGHT)

	# Pop out 2 or 3 goodies
	var Powerup := load("res://scripts/powerup.gd")
	var how_many := randi_range(2, 3)
	for i in how_many:
		var item: Area2D = Powerup.new()
		item.kind = LOOT_TABLE[randi() % LOOT_TABLE.size()]
		get_tree().current_scene.add_child(item)
		# spread them out above the chest so you can see them all
		var spread := (float(i) - (how_many - 1) / 2.0) * 52.0
		item.global_position = global_position + Vector2(spread, -HEIGHT - 42.0)
		item._start_y = item.position.y

	if players.size() > 0:
		players[0].add_score(50)

func _draw() -> void:
	var wobble := sin(_time * 50.0) * _shake * 4.0
	var wood := Color(0.45, 0.28, 0.14)
	var wood_dark := Color(0.3, 0.18, 0.09)
	var gold := Color(0.95, 0.75, 0.25)
	if _flash > 0.0:
		wood = wood.lerp(Color.WHITE, _flash * 0.7)
		wood_dark = wood_dark.lerp(Color.WHITE, _flash * 0.5)

	var hw := WIDTH / 2.0

	# shadow underneath
	draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, hw, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Box part
	draw_rect(Rect2(-hw + wobble, -26, WIDTH, 26), wood)
	draw_rect(Rect2(-hw + wobble, -26, WIDTH, 26), wood_dark, false, 2.0)
	# wooden planks
	for i in 2:
		var x := -hw + 18.0 + i * 18.0 + wobble
		draw_line(Vector2(x, -25), Vector2(x, -1), wood_dark, 1.5)
	# gold bands
	draw_rect(Rect2(-hw + wobble, -20, WIDTH, 4), gold)
	draw_rect(Rect2(-hw + wobble, -8, WIDTH, 4), gold)

	# Lid swings open when you break it
	var lid_angle := -_lid * 1.9
	draw_set_transform(Vector2(-hw + wobble, -26), lid_angle, Vector2.ONE)
	draw_rect(Rect2(0, -16, WIDTH, 16), wood)
	draw_rect(Rect2(0, -16, WIDTH, 16), wood_dark, false, 2.0)
	draw_rect(Rect2(0, -12, WIDTH, 4), gold)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if opened:
		# glowing treasure light shining out of the open chest
		var shine := Color(1, 0.95, 0.5, 0.35 + sin(_time * 5.0) * 0.12)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-hw + 6, -26), Vector2(hw - 6, -26),
			Vector2(hw + 12, -70), Vector2(-hw - 12, -70)]), shine)
	else:
		# Gold lock with a keyhole
		draw_rect(Rect2(-8 + wobble, -20, 16, 16), gold)
		draw_circle(Vector2(wobble, -13), 3.5, Color(0.3, 0.2, 0.1))
		draw_rect(Rect2(-1.5 + wobble, -13, 3, 6), Color(0.3, 0.2, 0.1))
		# "shoot me!" hint sparkles
		var twinkle := (sin(_time * 3.0) + 1.0) / 2.0
		draw_circle(Vector2(hw - 4, -34), 2.0 + twinkle * 1.5, Color(1, 1, 0.6, 0.5 + twinkle * 0.4))
