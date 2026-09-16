extends Camera2D


func _process(_delta: float) -> void:
	var target_position: Vector2 = Player.instance.global_position
	target_position.x = clampf(target_position.x, 72, 248)
	target_position.y = clampf(target_position.y, 64, 256)
	global_position = target_position
