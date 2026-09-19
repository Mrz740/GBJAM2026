extends Node2D

@export var start_y: float = 0.0
@export var end_y: float = 10.0
@export var duration: float = 10.0
@export var tween_object: Sprite2D


func start() -> void:
	show()
	tween_object.position.y = start_y
	var tween: Tween = create_tween()
	tween.tween_method(_update_position, start_y, end_y, duration)


func _update_position(y: float) -> void:
	tween_object.position.y = floor(y)
