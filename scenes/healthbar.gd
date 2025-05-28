extends Node2D

const HEART_SCALE := 2.5
const INTERVAL := 6

func update_healthbar(health: int):
	for child in get_children():
		if child is Sprite2D:
			remove_child(child)
			child.queue_free()
	
	var x := 0.0
	for i in range(health):
		var sprite := Sprite2D.new()
		sprite.texture = load("res://graphics/heart.png")
		sprite.scale = Vector2(HEART_SCALE, HEART_SCALE)
		sprite.position = Vector2(x, 0)
		add_child(sprite)
		
		x += sprite.texture.get_width() * HEART_SCALE + INTERVAL
		
