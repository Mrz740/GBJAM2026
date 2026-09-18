class_name EnemyManager
extends Node2D

enum EnemyType {
	CRAB,
	PIRATE,
	SKELETON
}

@export var enemy_scene: PackedScene
@export var enemy_count: int
@export var enemy_spawn_rate: float = 10.0

var enemy_spawn_cooldown: float = 10.0
var current_enemy_count: int
var player_spawn_radius: int = 5

var land_tiles: Array[Vector2i] = []

var enemy_next_tile: Dictionary[Enemy, Vector2i] = {}
var enemy_current_tile: Dictionary[Enemy, Vector2i] = {}


func _ready() -> void:
	#spawn_enemies.call_deferred()
	current_enemy_count = 0
	enemy_spawn_cooldown = 10.0


func _process(delta: float) -> void:
	if current_enemy_count >= enemy_count:
		return
	if enemy_spawn_cooldown > 0.0:
		enemy_spawn_cooldown -= delta
		return
	enemy_spawn_cooldown = enemy_spawn_rate
	spawn_enemies(1)


func spawn_enemies(count: int) -> void:
	land_tiles = GameMap.instance.get_land_tiles()
	
	if land_tiles.is_empty():
		print("something really went wrong. Land tiles is empty?")
		return
	
	var random_indices: Array[int] = get_random_indices(count)
	
	if random_indices.is_empty():
		return
	
	for i in random_indices:
		var coord: Vector2i = land_tiles[i]
		
		if !is_land_tile(coord):
			print("this should never print if everything is indeed a land tile")
			continue
		
		var enemy_node: Enemy = enemy_scene.instantiate()
		enemy_node.global_position = GameMap.instance.get_cell_world(coord)
		
		var rng_type: int = randi_range(0, 2)
		
		enemy_node.setup(self, current_enemy_count, rng_type as EnemyType)
		add_child(enemy_node)
		current_enemy_count += 1


func is_land_tile(coord: Vector2i) -> bool:
	var terrain_type = GameMap.instance.get_terrain_type(coord)
	return terrain_type == GameMap.TerrainType.GRASS or terrain_type == GameMap.TerrainType.DIRT 


func get_random_indices(count: int) -> Array[int]:
	var indices: Array[int] = []
	
	for i in range(land_tiles.size()):
		if (land_tiles[i] - GameMap.instance.local_to_map(Player.instance.global_position)).length() > player_spawn_radius:
			
			if !GameMap.instance.has_occupied_cell(land_tiles[i]):
				indices.append(i)
	
	if indices.is_empty():
		return []
	indices.shuffle()
	return indices.slice(0, count)


func get_random_tile_within_radius(pos: Vector2, radius: float) -> Vector2i:
	var center_coord: Vector2i = GameMap.instance.local_to_map(pos)
	var tiles: Array[Vector2i] = []
	
	var tile_radius: float = ceili(radius / GameMap.instance.TILE_SIZE)
	
	for x in range(center_coord.x - tile_radius, center_coord.x + tile_radius + 1):
		for y in range(center_coord.y - tile_radius, center_coord.y + tile_radius + 1):
			var coord: Vector2i = Vector2i(x, y)
			
			if is_valid_tile(coord) and !has_occupied_tile(coord):
				tiles.append(coord)
	
	if tiles.is_empty():
		return center_coord
	
	return tiles[randi_range(0, tiles.size()-1)]


func is_valid_tile(coord: Vector2i) -> bool:
	var terrain_type: GameMap.TerrainType = GameMap.instance.get_terrain_type(coord)
	return terrain_type == GameMap.TerrainType.GRASS or terrain_type == GameMap.TerrainType.DIRT


func reduce_enemy_count() -> void:
	current_enemy_count -= 1


#region CHECK VALID PATH

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
