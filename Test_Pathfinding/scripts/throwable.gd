class_name Throwable
extends Node2D

@export var despawn_time: float = 5.0
@export var speed: float = 60.0

var time_alive: float
var direction: Vector2


func _ready() -> void:
	time_alive = despawn_time


func _process(delta: float) -> void:
	if time_alive > 0.0:
		global_position += direction * speed * delta
		time_alive -= delta
		return
	
	queue_free()


func throw(player_pos: Vector2, player_input: Vector2) -> void:
	if player_input:
		var predicted_pos: Vector2 = player_pos + player_input * 16.0
		direction = (predicted_pos-global_position).normalized()
	
	else:
		direction = (player_pos-global_position).normalized()


func _on_area_2d_area_entered(area):
	if area.get_parent() is Player:
		Player.instance.lose_health(1)
