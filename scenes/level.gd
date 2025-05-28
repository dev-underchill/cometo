extends Node2D

const ENEMY_MIN_SPEED := 200
const ENEMY_MAX_SPEED := 300
const ENEMY_SPAWN_RADIUS := 900

const laser_scene := preload("res://scenes/laser.tscn")
const comet_small_scene := preload("res://scenes/small_comet.tscn")
const comet_medium_scene := preload("res://scenes/medium_comet.tscn")
const comet_large_scene := preload("res://scenes/large_comet.tscn")
const player_scene := preload("res://scenes/Player.tscn")

var player_lives := 3
var player_score := 0



@onready var enemy_timer := $Timers/EnemyTimer

func _ready():
	$CanvasLayer/Healthbar.update_healthbar(player_lives)
	$CanvasLayer/DeathUI.hide()
	$Player.respawn()

var threshold = 0.1

func should_spawn() -> bool:
	if randf() < threshold:
		return true
	return false

func get_random_enemy() -> PackedScene:
	var random := randf()
	if random < 0.5:
		return comet_small_scene
	if random < 0.8:
		return comet_medium_scene
	return comet_large_scene


func _on_player_laser_shot(spawn_position:Vector2, rotate_degrees) -> void:
	var laser = laser_scene.instantiate()
	laser.position = spawn_position
	laser.direction = $Player/Cannon.global_position - $Player.global_position
	laser.scale = Vector2(3, 3)
	laser.rotation_degrees = rotate_degrees
	laser.connect("enemy_hit", Callable(self, "_on_laser_enemy_hit"))
	$Projectiles.add_child(laser)


func spawn_enemy() -> void:
	if !should_spawn():
		return
	var enemy = get_random_enemy().instantiate()
	var center = get_viewport_rect().size / 2
	enemy.position = center + Vector2.UP.rotated(deg_to_rad(randf() * 360)) * ENEMY_SPAWN_RADIUS
	enemy.linear_velocity = (center - enemy.position).rotated(deg_to_rad(randf() * 90 - 45)).normalized() * randi_range(ENEMY_MIN_SPEED, ENEMY_MAX_SPEED) * enemy.speed_modifier
	enemy.get_node("Sprite2D").scale = Vector2(3, 3)
	enemy.get_node("CollisionPolygon2D").scale = Vector2(3, 3)
	$Enemies.add_child(enemy)



func _on_enemy_timer_timeout() -> void:
	spawn_enemy()


func _on_laser_enemy_hit(enemy: Node2D, damage: int) -> void:
	if enemy.damage(damage):
		update_score(enemy.value)
		enemy.destroy()

func update_score(points: int) -> void:
	if player_score / 200 < (player_score + points) / 200:
		threshold = clamp(threshold * 1.2, 0, 0.5) 
	player_score += points
	$CanvasLayer/Score.text = str(player_score)

func _on_player_lives_updated() -> void:
	player_lives -= 1
	$CanvasLayer/Healthbar.update_healthbar(player_lives)
	if $Player:
		$Player.die()
	if player_lives > 0:
		$Timers/PlayerRespawn.start()
	else:
		$Timers/DeathUITimer.start()


func _on_player_respawn_timeout() -> void:
	$Player.respawn()


func _on_live_zone_body_exited(body:Node2D) -> void:
	if (body.position - get_viewport_rect().get_center()).length() >= (ENEMY_SPAWN_RADIUS + 100):
		body.queue_free()


func _on_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_death_ui_timer_timeout() -> void:
	$CanvasLayer/DeathUI.show()
	$CanvasLayer/Score.hide()
	$CanvasLayer/DeathUI/Label2.text = "Final Score: %s" % [str(player_score)]


func _on_player_live_zone_body_exited(body: Node2D) -> void:
	if body.get_groups().has("Player"):
		if !get_viewport_rect().has_point($Player.position):
			$Player.lives_updated.emit()
