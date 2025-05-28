extends CharacterBody2D

const MAX_SPEED := 400
const ACCELERATION := 1200
const FRICTION := 400
const ROTATION_SPEED := 5

var direction := Vector2.UP

signal laser_shot(spawn_position: Vector2, rotate_degrees: float)
signal lives_updated()


func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_particles()
	handle_laser()
	handle_collision()


func handle_particles() -> void:
	$GPUParticles2D.amount = int(clamp(velocity.length() / 10, 10, 20))
	$GPUParticles2D.process_material.scale_max = clamp(velocity.length() / 250, 0.8, 1)
	$GPUParticles2D.process_material.scale_min = clamp(velocity.length() / 450, 0.4, 0.7)


func handle_movement(delta) -> void:
	var rotate_degrees = Input.get_axis("steer_left", "steer_right")
	rotation_degrees += rotate_degrees * ROTATION_SPEED

	direction = Vector2.UP.rotated(deg_to_rad(rotation_degrees)).normalized()

	# movement
	var throttle := Input.is_action_pressed("front")

	if !throttle:
		if (velocity.length() < FRICTION * delta):
			velocity = Vector2.ZERO
		else:
			velocity -= velocity.normalized() * FRICTION * delta
	else:
		velocity += direction * ACCELERATION * delta
		velocity = velocity.limit_length(MAX_SPEED)

	move_and_slide()


func handle_laser() -> void:
	if Input.is_action_pressed("shoot") && $LaserTimer.is_stopped():
		var spawn_position: Vector2 = $Cannon.global_position
		laser_shot.emit(spawn_position, rotation_degrees)
		$LaserSound.play()
		$LaserTimer.start()


func handle_collision() -> void:
	if get_slide_collision_count() == 0:
		return

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("Comet"):
			lives_updated.emit()
			return


func die() -> void:
	$CollisionPolygon2D.call_deferred("set_disabled", true)
	$Sprite2D.hide()
	$GPUParticles2D.emitting = false
	$GPUParticles2D2.emitting = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	$DeathSound.play()


func respawn() -> void:
	$FlickerTimer.start()
	$InvincibilityTimer.start()
	position = get_viewport_rect().size / 2
	rotation_degrees = 0
	$Sprite2D.show()
	$GPUParticles2D.emitting = true
	await get_tree().process_frame
	set_physics_process(true)
	await get_tree().process_frame
	velocity = Vector2.ZERO
	$Sprite2D.modulate.a = 0.5


func _on_invincibility_timer_timeout() -> void:
	$CollisionPolygon2D.call_deferred("set_disabled", false)
	$Sprite2D.modulate.a = 1.0
	$FlickerTimer.stop()


func _on_flicker_timer_timeout() -> void:
	if $Sprite2D.modulate.a == 1.0:
		$Sprite2D.modulate.a = 0.5
	else:
		$Sprite2D.modulate.a = 1.0
