extends CharacterBody2D

@export var SPEED: float = 45.0

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("LEFT", "RIGHT", "UP", "DOWN")
	velocity = direction * SPEED
	move_and_slide()
