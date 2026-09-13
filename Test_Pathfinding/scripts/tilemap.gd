@tool
class_name GameMap
extends TileMapLayer

@export var noise: Noise
@export var falloff_texture: Texture2D
@export var falloff_strength: float = 0.09

@export_tool_button("Generate Map", "Callable") var _generate_world = generate_world

var astar: AStarGrid2D = AStarGrid2D.new()
var map_rect: Rect2i = Rect2i()
var tile_size: Vector2i

# coords can be checked in the tileset
var land_atlas: Vector2i = Vector2i(1,1)
var water_atlas: Vector2i = Vector2i(4,1)
var dirt_atlas: Vector2i = Vector2i(6, 0)

var enemy_next_tile: Dictionary[Enemy, Vector2i] = {}
var enemy_current_tile: Dictionary[Enemy, Vector2i] = {}

var noise_val_arr : Array[float] = []

var gold_positions: Dictionary[Vector2i, Gold] = {}

var directions_all: Array[Vector2i] = [
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i(-1, -1),
	Vector2i(1, 1),
	Vector2i(-1, 1),
	Vector2i(1, -1),
]

var directions_short: Array[Vector2i] = [
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.UP,
	Vector2i.DOWN,
]


func _ready() -> void:
	setup_astar()


#region ASTAR AND MAP

func setup_astar() -> void:
	var tilemap_size: Vector2i = get_used_rect().end - get_used_rect().position
	
	map_rect = Rect2i(Vector2i.ZERO, tilemap_size)
	tile_size = get_tile_set().tile_size
	
	#generate_world()
	
	astar.region = map_rect
	astar.cell_size = tile_size
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	for i in tilemap_size.x:
		for j in tilemap_size.y:
			
			var coords: Vector2i = Vector2i(i, j)
			var tile_data: TileData = get_cell_tile_data(coords)
			
			if tile_data and tile_data.get_custom_data("type") == "wall":
				astar.set_point_solid(coords)
			else:
				gold_positions[coords] = null


func generate_world() -> void:
	var falloff_img: Image = falloff_texture.get_image()
	
	var tilemap_size: Vector2i = get_used_rect().end - get_used_rect().position
	
	for x in range(tilemap_size.x):
		for y in range(tilemap_size.y):
			
			var noise_val: float = noise.get_noise_2d(x,y)
			noise_val_arr.append(noise_val)
			
			var falloff: float = falloff_img.get_pixel(x, y).r * falloff_strength
			
			noise_val -= falloff
			
			if noise_val >= 0.0:
				set_cell(Vector2(x,y), 0, land_atlas)
			else:
				set_cell(Vector2(x,y), 0, water_atlas)

#endregion


#region DIG MAP

func dig(pos: Vector2) -> void:
	var coord: Vector2i = local_to_map(pos)
	set_cell(coord, 0, dirt_atlas)
	
	if _can_destroy_map(coord):
		_destroy_map()


func _can_destroy_map(start: Vector2i) -> bool:
	for direction in directions_all:
		var opposite: Vector2i = -direction
		var end_a: Vector2i = _find_line_end(start, direction)
		
		if _is_blocking_tile(end_a):
			for direction2 in directions_all:
				opposite = -direction2
				var end_b: Vector2i = _find_line_end(start, opposite)
				if _is_blocking_tile(end_b):
					return true
	return false


func _find_line_end(start: Vector2i, direction: Vector2i) -> Vector2i:
	var current: Vector2i = start
	
	while is_dirt(current):
		var next: Vector2i = current + direction
		if not is_dirt(next):
			return next
		current = next
	
	return current


func _is_blocking_tile(coord: Vector2i) -> bool:
	var tile_data: TileData = get_cell_tile_data(coord)
	
	if tile_data == null:
		return false
	
	var type: String = tile_data.get_custom_data("type")
	return type == "dirt" or type == "wall"


func is_dirt(coord: Vector2i) -> bool:
	var tile_data: TileData = get_cell_tile_data(coord)
	return tile_data and tile_data.get_custom_data("type") == "dirt"


func _destroy_map() -> void:
	var areas: Array[MapArea] = _get_map_areas()
	
	if areas.size() <= 1:
		return
	
	var max_tile_count: int = 160 * 144
	var area_to_destroy: MapArea = null
	
	for area in areas:
		if area.tile_count < max_tile_count:
			max_tile_count = area.tile_count
			area_to_destroy = area
	
	if area_to_destroy == null:
		print("something went horribly wrong")
		return
	
	for tile in area_to_destroy.cells:
		set_cell(tile, 0, water_atlas)
		astar.set_point_solid(tile)
		
		if gold_positions[tile]:
			gold_positions[tile].queue_free()


func _get_map_areas() -> Array[MapArea]:
	var unvisited: Dictionary = {}
	var regions: Array[MapArea] = []
	var dirt_tiles: Array[Vector2i] = []
	
	for coord in get_used_cells():
		var tile_data: TileData = get_cell_tile_data(coord)
		if !tile_data:
			continue
		
		var type: String = tile_data.get_custom_data("type")
		
		if type == "dirt":
			dirt_tiles.append(coord)
		elif type != "wall":
			unvisited[coord] = true
	
	while not unvisited.is_empty():
		var start: Vector2i = unvisited.keys()[0]
		var region: MapArea = _flood_fill(start, unvisited)
		regions.append(region)
	
	for dirt in dirt_tiles:
		var adjacent_regions: Array[MapArea] = []
		
		for direction in directions_short:
			var neighbor: Vector2i = dirt + direction
			
			for region in regions:
				if neighbor in region.cells and region not in adjacent_regions:
					adjacent_regions.append(region)
		
		if not adjacent_regions.is_empty():
			var biggest_region: MapArea = adjacent_regions[0]
			
			for region in adjacent_regions:
				if region.tile_count > biggest_region.tile_count:
					biggest_region = region
			
			biggest_region.cells.append(dirt)
			biggest_region.tile_count += 1
	
	return regions


func _flood_fill(start: Vector2i, unvisited: Dictionary) -> MapArea:
	var queue: Array[Vector2i] = [start]
	var tile_count: int = 0
	var tiles: Array[Vector2i] = []
	
	unvisited.erase(start)
	
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		tile_count += 1
		tiles.append(current)
		
		for direction in directions_short:
			var neighbor: Vector2i = current + direction
			if unvisited.has(neighbor):
				unvisited.erase(neighbor)
				queue.append(neighbor)
	
	var map_area: MapArea = MapArea.new()
	map_area.tile_count = tile_count
	map_area.cells = tiles
	return map_area

#endregion


#region CHECK VALID PATH

func is_point_walkable(pos: Vector2) -> bool:
	var coord: Vector2i = local_to_map(pos)
	return map_rect.has_point(coord) and not astar.is_point_solid(coord)


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

#endregion


#region GOLD SPAWN

func get_gold_pos() -> Vector2i:
	var candidates: Array[Vector2i] = []
	for pos in gold_positions:
		var tile_data: TileData = get_cell_tile_data(pos)
		if !gold_positions[pos] and tile_data.get_custom_data("type") != "wall":
			candidates.append(pos)
	
	if candidates.size() <= 0:
		return Vector2i(-1,-1)
	
	var rng_idx: int = randi_range(0, candidates.size() - 1)
	return candidates[rng_idx]


func update_gold_dictionary(gold: Gold, coord: Vector2i) -> void:
	gold_positions[coord] = gold

#endregion


#region HELPERS

func in_water(tile: Vector2i) -> bool:
	var tile_data: TileData = get_cell_tile_data(tile)
	return !tile_data or tile_data.get_custom_data("type") == "wall"

#endregion


class MapArea:
	var cells: Array[Vector2i]
	var tile_count: int
