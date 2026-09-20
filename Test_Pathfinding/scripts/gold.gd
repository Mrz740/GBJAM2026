class_name Gold
extends Node2D

@export var value: int = 5

var dropped_by_player: bool
var can_pick_up: bool = true


func _ready() -> void:
	if GameMap.instance:
		GameMap.instance.map_updated.connect(_on_map_updated)
	timer = 1.0


var timer: float
func _process(delta: float) -> void:
	if timer > 0.0:
		timer -= delta
		return
	can_pick_up = true


func _exit_tree():
	if GameMap.instance:
		GameMap.instance.map_updated.disconnect(_on_map_updated)


func _on_map_updated() -> void:
	var coord: Vector2i = GameMap.instance.local_to_map(global_position)
	if GameMap.instance.get_terrain_type(coord) == GameMap.TerrainType.WATER:
		queue_free()


func _on_body_entered(body):
	if body is Player:
		if !can_pick_up:
			return
		ScoreManager.add_score(value, "coins")
		# Play sound effect
		queue_free()
	
	elif body.is_in_group("enemy") and dropped_by_player:
		queue_free()


func _on_body_exited(body):
	if body is Player:
		can_pick_up = true
