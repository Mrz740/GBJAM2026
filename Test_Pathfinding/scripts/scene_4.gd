extends Node2D

@export var tween_object: AnimatedSprite2D
@export var tween_object2: AnimatedSprite2D


func start() -> void:
	show()
	tween_object.play("default")
	tween_object2.play("default")
