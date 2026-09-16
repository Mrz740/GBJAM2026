class_name EnemyManager
extends Node2D

enum EnemyType {
	CRAB,
	PIRATE,
	SKELETON
}

@export var game_map: GameMap
@export var enemy_scene: PackedScene
@export var enemy_count: int
var current_enemy_count: int
var player_spawn_radius: int = 5

var land_tiles: Array[Vector2i] = []


func _ready() -> void:
	spawn_enemies.call_deferred()


func spawn_enemies() -> void:
	land_tiles = game_map.get_land_tiles()
	
	if land_tiles.is_empty():
		print("something really went wrong. Land tiles is empty?")
		return
	
	var random_indices: Array[int] = get_random_indices()
	
	if random_indices.is_empty():
		return
	
	current_enemy_count = 0
	
	for i in random_indices:
		var coord: Vector2i = land_tiles[i]
		
		if !is_land_tile(coord):
			print("this should never print if everything is indeed a land tile")
			continue
		
		var enemy_node: Enemy = enemy_scene.instantiate()
		enemy_node.global_position = game_map.get_cell_world(coord)
		enemy_node.setup(self, game_map, current_enemy_count, EnemyType.CRAB)
		add_child(enemy_node)
		current_enemy_count += 1


func is_land_tile(coord: Vector2i) -> bool:
	var terrain_type = game_map.get_terrain_type(coord)
	return terrain_type == GameMap.TerrainType.GRASS or terrain_type == GameMap.TerrainType.DIRT 


func get_random_indices() -> Array[int]:
	var indices: Array[int] = []
	
	for i in range(land_tiles.size()):
		#print((land_tiles[i] - game_map.local_to_map(Player.instance.global_position)).length())
		
		if (land_tiles[i] - game_map.local_to_map(Player.instance.global_position)).length() > player_spawn_radius:
			indices.append(i)
	
	if indices.is_empty():
		return []
	
	indices.shuffle()
	return indices.slice(0, enemy_count)


func get_random_tile_within_radius(pos: Vector2, radius: float) -> Vector2i:
	var center_coord: Vector2i = game_map.local_to_map(pos)
	var tiles: Array[Vector2i] = []
	
	var tile_radius: float = ceili(radius / game_map.TILE_SIZE)
	
	for x in range(center_coord.x - tile_radius, center_coord.x + tile_radius + 1):
		for y in range(center_coord.y - tile_radius, center_coord.y + tile_radius + 1):
			var coord: Vector2i = Vector2i(x, y)
			
			if is_valid_tile(coord) and !has_occupied_tile(coord):
				tiles.append(coord)
	
	if tiles.is_empty():
		return center_coord
	
	return tiles[randi_range(0, tiles.size()-1)]


func is_valid_tile(coord: Vector2i) -> bool:
	var terrain_type: GameMap.TerrainType = game_map.get_terrain_type(coord)
	return terrain_type == GameMap.TerrainType.GRASS or terrain_type == GameMap.TerrainType.DIRT


#region CHECK VALID PATH

var enemy_next_tile: Dictionary[Enemy, Vector2i] = {}
var enemy_current_tile: Dictionary[Enemy, Vector2i] = {}


func has_reserved_tile_and_can_move(enemy: Enemy, tile: Vector2i) -> bool:
	for e in enemy_next_tile:
		if not is_instance_valid(e) or not is_instance_valid(enemy_next_tile[e]):
			enemy_next_tile.erase(e)
			continue
		if enemy_next_tile[e] == tile:
			return enemy.idx <= e.idx
	return true


func has_enemy_tile_and_can_move(enemy: Enemy, tile: Vector2i) -> bool:
	for e in enemy_current_tile:
		if not is_instance_valid(e) or not is_instance_valid(enemy_current_tile[e]):
			enemy_current_tile.erase(e)
			continue
		if enemy_current_tile[e] == tile:
			return enemy.idx <= e.idx
		elif enemy_current_tile[e] == tile and e != enemy:
			return true
	return true


func update_enemy_current_tile(enemy: Enemy, tile: Vector2i) -> void:
	enemy_current_tile[enemy] = tile


func update_enemy_next_tile(enemy: Enemy, tile: Vector2i) -> void:
	enemy_next_tile[enemy] = tile


func has_occupied_tile(tile: Vector2i) -> bool:
	for e in enemy_current_tile:
		if enemy_current_tile[e] == tile:
			return true
	return false

#endregion
