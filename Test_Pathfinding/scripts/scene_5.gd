extends Node2D

@export var start_y: float = 0.0
@export var end_y: float = 10.0
@export var speed: float = 1.0
@export var tween_object: Sprite2D

var time: float = 0.0


func start() -> void:
	show()
	time = 0.0


func _process(delta: float) -> void:
	time += delta
	
	var center: float = (start_y + end_y) * 0.5
	var amplitude: float = abs((end_y - start_y) * 0.5)
	
	var y: float = center + sin(time * speed) * amplitude
	
	tween_object.position.y = floor(y)
