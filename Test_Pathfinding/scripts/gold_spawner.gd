extends Node2D

@export var game_map: GameMap
@export var gold_scene: PackedScene
@export var gold_cooldown: float = 5.0
var timer: float


func _process(delta: float) -> void:
	if timer > 0:
		timer -= delta
		return
	timer = gold_cooldown
	
	#var coord: Vector2i = game_map.get_gold_pos()
	#
	#if game_map.get_gold_pos().x < 0:
		#print("no valid coord found")
		#return
	#
	#var gold_node: Gold = gold_scene.instantiate()
	#add_child(gold_node)
	#gold_node.global_position = coord * game_map.TILE_SIZE + Vector2i.ONE * floori(game_map.TILE_SIZE * 0.5)
	#
	#game_map.update_gold_dictionary(gold_node, coord)
