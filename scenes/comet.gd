extends RigidBody2D

var health: int
var value: int
var speed_modifier: float
var particle_modifier: Vector2
	
@onready var explosion := $Explosion
@onready var destroy_timer := $DestroyTimer

func _ready() -> void:
	destroy_timer.wait_time = explosion.lifetime

func damage(attk_dmg: int) -> bool:
	"""
	takes health away from the comet, returns true if dead/exploded, returns false otherwise.
	"""
	health -= attk_dmg
	if health <= 0:
		return true
	return false

func destroy() -> void:
	$AudioStreamPlayer.play()
	explosion.process_material.scale = particle_modifier
	explosion.emitting = true
	destroy_timer.start()
	$Sprite2D.hide()
	$CollisionPolygon2D.call_deferred("set_disabled", true)


func _on_destroy_timer_timeout() -> void:
	queue_free()
