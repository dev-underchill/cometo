extends Area2D

const SPEED := 800
const DAMAGE := 10
var direction: Vector2

signal enemy_hit(enemy: Node2D, damage: int)

func _process(delta):
	position += direction.normalized() * SPEED * delta
	


func _on_body_entered(body:Node2D) -> void:
	if body.get_groups().has("Comet"):
		enemy_hit.emit(body, DAMAGE)
		queue_free()

	
