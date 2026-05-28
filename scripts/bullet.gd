extends Area2D

var direction := Vector2.RIGHT
const SPEED := 900.0
var lifetime := 2.0

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	position += direction * SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
	if body.is_in_group("enemies"):
		body.take_damage()
	queue_free()
