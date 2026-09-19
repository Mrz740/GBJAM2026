extends Node2D

@export var tween_object: AnimatedSprite2D


func start() -> void:
	show()
	tween_object.play("default")
