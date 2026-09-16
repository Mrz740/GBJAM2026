@tool
class_name GameMap
extends Node2D

enum TileType {
	EMPTY,
	FULL
}

enum TerrainType {
	EMPTY = -1,
	WATER = 1,
	GRASS = 2,
	DIRT = 3,
}

static var TILE_SIZE: int = 16
static var HALF_TILE_SIZE: int = floori(TILE_SIZE * 0.5)

static var neighbors_to_atlas_coord: Dictionary[Vector4i, Vector2i] = {
	Vector4i( 1, 1, 1, 1 ) : Vector2i(2, 1),
	Vector4i( 0, 0, 0, 1 ) : Vector2i(1, 3),
	Vector4i( 0, 0, 1, 0 ) : Vector2i(0, 0),
	Vector4i( 0, 1, 0, 0 ) : Vector2i(0, 2),
	Vector4i( 1, 0, 0, 0 ) : Vector2i(3, 3),
	Vector4i( 0, 1, 0, 1 ) : Vector2i(1, 0),
	Vector4i( 1, 0, 1, 0 ) : Vector2i(3, 2),
	Vector4i( 0, 0, 1, 1 ) : Vector2i(3, 0),
	Vector4i( 1, 1, 0, 0 ) : Vector2i(1, 2),
	Vector4i( 0, 1, 1, 1 ) : Vector2i(1, 1),
	Vector4i( 1, 0, 1, 1 ) : Vector2i(2, 0),
	Vector4i( 1, 1, 0, 1 ) : Vector2i(2, 2),
	Vector4i( 1, 1, 1, 0 ) : Vector2i(3, 1),
	Vector4i( 0, 1, 1, 0 ) : Vector2i(2, 3),
	Vector4i( 1, 0, 0, 1 ) : Vector2i(0, 1),
	Vector4i( 0, 0, 0, 0 ) : Vector2i(-1, -1)
};

@export var tile_set: TileSet
@export var noise: Noise
@export var falloff_texture: Texture2D
@export var falloff_strength: float = 0.09

@export var map_size: int = 50
@export var max_destroy_count: int = 10

@warning_ignore("unused_private_class_variable")
@export_tool_button("Generate Map", "Environment") var _generate_world = generate_world

var land_tiles: Array[Vector2i] = []

var tile_source_idx: int = 1

var NEIGHBORS: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(1, 1),
]

var water_atlas_placeholder: Vector2i = Vector2i(13, 0)
var grass_atlas_placeholder: Vector2i = Vector2i(13, 1)
var sand_atlas_placeholder: Vector2i = Vector2i(13, 2)

# coords can be checked in the tileset
var water_atlas: Vector2i = Vector2i(0, 0)
var grass_atlas: Vector2i = Vector2i(4, 0)
var sand_atlas: Vector2i = Vector2i(8, 0)
var barely_dirt_atlas: Vector2i = Vector2i(12, 2)

var astar: AStarGrid2D = AStarGrid2D.new()
var map_rect: Rect2i = Rect2i()

var noise_val_arr : Array[float] = []

#var gold_positions: Dictionary[Vector2i, Gold] = {}

var directions_8: Array[Vector2i] = [
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i(-1, -1),
	Vector2i(1, 1),
	Vector2i(-1, 1),
	Vector2i(1, -1),
]

var directions_4: Array[Vector2i] = [
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.UP,
	Vector2i.DOWN,
]

@onready var data_layer: TileMapLayer = %DataLayer
@onready var water_display_layer: TileMapLayer = %WaterDisplayLayer
@onready var grass_display_layer: TileMapLayer = %GrassDisplayLayer
@onready var dirt_display_layer: TileMapLayer = %DirtDisplayLayer
@onready var temp_dig_layer: TileMapLayer = %TempDigLayer


func _ready() -> void:
	generate_world()
	_refresh_all_tiles()
	_setup_astar()


#region MAP GENERATION

func generate_world() -> void:
	data_layer.clear()
	water_display_layer.clear()
	grass_display_layer.clear()
	dirt_display_layer.clear()
	var falloff_img: Image = falloff_texture.get_image()
	
	for x in range(map_size):
		for y in range(map_size):
			
			var tile: Vector2i = Vector2i(x, y)
			
			var noise_val: float = noise.get_noise_2d(x,y) + 1.0 * 0.5
			noise_val_arr.append(noise_val)
			
			var falloff: float = falloff_img.get_pixel(x, y).r * falloff_strength
			
			noise_val -= falloff
			#noise_val = falloff
			
			if noise_val >= 0.0:
				set_tile(tile, TerrainType.GRASS)
				land_tiles.append(tile)
				#data_layer.set_cell(Vector2(x,y), tile_set.get_source_id(tile_source_idx), grass_atlas_placeholder)
			else:
				set_tile(tile, TerrainType.WATER)
				#data_layer.set_cell(Vector2(x,y), tile_set.get_source_id(tile_source_idx), water_atlas_placeholder)
	
	var map_areas: Array[MapArea] = _get_map_areas()
	var biggest_area: MapArea
	
	var biggest_area_size: int = 0
	
	for map_area in map_areas:
		if map_area.tile_count > biggest_area_size:
			biggest_area_size = map_area.tile_count
			biggest_area = map_area
	
	for map_area in map_areas:
		if map_area != biggest_area:
			for tile in map_area.cells:
				set_tile(tile, TerrainType.WATER)
				land_tiles.erase(tile)
				#data_layer.set_cell(tile, tile_set.get_source_id(tile_source_idx), water_atlas_placeholder)
				#astar.set_point_solid(tile)


func _refresh_all_tiles() -> void:
	for cell_pos in data_layer.get_used_cells():
		_refresh_display_tile(cell_pos, water_display_layer, TerrainType.WATER)
		_refresh_display_tile(cell_pos, grass_display_layer, TerrainType.GRASS)
		_refresh_display_tile(cell_pos, dirt_display_layer, TerrainType.DIRT)


func set_tile(coords: Vector2i, terrain_type: TerrainType) -> void:
	var old_terrain_type: TerrainType = get_terrain_type(coords)
	
	data_layer.set_cell(coords, tile_set.get_source_id(tile_source_idx), _get_data_atlas_coord(terrain_type))
	_refresh_display_tile(coords, _get_display_layer(terrain_type), terrain_type)
	
	if old_terrain_type != terrain_type and old_terrain_type != TerrainType.EMPTY:
		_refresh_display_tile(coords, _get_display_layer(old_terrain_type), old_terrain_type)


func _refresh_display_tile(cell_pos: Vector2i, display_layer: TileMapLayer, terrain_type: TerrainType) -> void:
	for i in range(NEIGHBORS.size()):
		var new_pos: Vector2i = cell_pos + NEIGHBORS[i]
		var atlas_coords: Vector2i = _calculate_display_tile_atlas_coords(new_pos, terrain_type)
		
		if atlas_coords - _get_atlas_coord(terrain_type) == Vector2i(-1,-1):
			display_layer.erase_cell(new_pos)
		else:
			
			if display_layer == grass_display_layer:
				
				# the grass center atlas coord, the full white sprite
				if atlas_coords == Vector2i(6,1):
					if randi_range(0, 10) < 10:
						display_layer.set_cell(new_pos, tile_set.get_source_id(tile_source_idx), atlas_coords)
					else:
						display_layer.set_cell(new_pos, tile_set.get_source_id(tile_source_idx), Vector2i(9,7))
				else:
					display_layer.set_cell(new_pos, tile_set.get_source_id(tile_source_idx), atlas_coords)
			else:
				display_layer.set_cell(new_pos, tile_set.get_source_id(tile_source_idx), atlas_coords)


func _calculate_display_tile_atlas_coords(coords: Vector2i, terrain_type: TerrainType) -> Vector2i:
	var botRight: TileType = _get_matching_tile_type(coords - NEIGHBORS[0], terrain_type)
	var botLeft: TileType = _get_matching_tile_type(coords - NEIGHBORS[1], terrain_type)
	var topRight: TileType = _get_matching_tile_type(coords - NEIGHBORS[2], terrain_type)
	var topLeft: TileType = _get_matching_tile_type(coords - NEIGHBORS[3], terrain_type)
	
	return neighbors_to_atlas_coord[Vector4i(topLeft, topRight, botLeft, botRight)] + _get_atlas_coord(terrain_type)


func _get_matching_tile_type(coords: Vector2i, terrain_type: TerrainType) -> TileType:
	var target_placeholder_atlas_coords: Vector2i = _get_data_atlas_coord(terrain_type)
	var atlas_coord: Vector2i = data_layer.get_cell_atlas_coords(coords)
	
	if atlas_coord != target_placeholder_atlas_coords:
		return TileType.EMPTY
	else:
		return TileType.FULL


func _get_atlas_coord(terrain_type: TerrainType) -> Vector2i:
	match terrain_type:
		TerrainType.WATER:
			return water_atlas
		TerrainType.GRASS:
			return grass_atlas
		TerrainType.DIRT:
			return sand_atlas
		_:
			return -Vector2i.ONE


func _get_data_atlas_coord(terrain_type: TerrainType) -> Vector2i:
	match terrain_type:
		TerrainType.WATER:
			return water_atlas_placeholder
		TerrainType.GRASS:
			return grass_atlas_placeholder
		TerrainType.DIRT:
			return sand_atlas_placeholder
		_:
			return -Vector2i.ONE


func _get_display_layer(terrain_type: TerrainType) -> TileMapLayer:
	match terrain_type:
		TerrainType.WATER:
			return water_display_layer
		TerrainType.GRASS:
			return grass_display_layer
		TerrainType.DIRT:
			return dirt_display_layer
		_:
			return null

#endregion


#region ASTAR

func _setup_astar() -> void:
	map_rect = Rect2i(Vector2i.ZERO, Vector2i.ONE * map_size)
	
	astar.region = map_rect
	astar.cell_size = Vector2i.ONE * TILE_SIZE
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	for i in map_size:
		for j in map_size:
			
			var coords: Vector2i = Vector2i(i, j)
			var tile_data: TileData = data_layer.get_cell_tile_data(coords)
			
			if tile_data and tile_data.get_custom_data("type") == "water":
				astar.set_point_solid(coords)
			#else:
				#gold_positions[coords] = null

#endregion


#region DIG MAP

func dig(pos: Vector2) -> void:
	
	var coord: Vector2i = local_to_map(pos)
	
	if get_terrain_type(coord) == TerrainType.DIRT:
		return
	
	var atlas_coord: Vector2i = temp_dig_layer.get_cell_atlas_coords(coord)
	
	if atlas_coord == Vector2i(-1, -1):
		temp_dig_layer.set_cell(coord, tile_set.get_source_id(tile_source_idx), barely_dirt_atlas)
	
	else:
		if (atlas_coord - Vector2i(0,1)).y >= 0:
			temp_dig_layer.set_cell(coord, tile_set.get_source_id(tile_source_idx), atlas_coord - Vector2i(0, 1))
		
		if temp_dig_layer.get_cell_atlas_coords(coord).y == 0:
			set_tile(coord, TerrainType.DIRT)
	
	if get_terrain_type(coord) != TerrainType.DIRT:
		return
	
	_destroy_map()
	#if _can_destroy_map(coord):
		#print("destroy map")
		#_destroy_map()


func _can_destroy_map(start: Vector2i) -> bool:
	for direction in directions_8:
		var opposite: Vector2i = -direction
		var end_a: Vector2i = _find_line_end(start, direction)
		
		if _is_blocking_tile(end_a):
			for direction2 in directions_8:
				opposite = -direction2
				var end_b: Vector2i = _find_line_end(start, opposite)
				if _is_blocking_tile(end_b):
					return true
	return false


func _find_line_end(start: Vector2i, direction: Vector2i) -> Vector2i:
	var current: Vector2i = start
	
	while _is_dirt(current):
		var next: Vector2i = current + direction
		if not _is_dirt(next):
			return next
		current = next
	
	return current


func _is_blocking_tile(coord: Vector2i) -> bool:
	var tile_data: TileData = data_layer.get_cell_tile_data(coord)
	
	if tile_data == null:
		return false
	
	var type: String = tile_data.get_custom_data("type")
	return type == "water"


func _is_dirt(coord: Vector2i) -> bool:
	if !data_layer.get_cell_tile_data(coord):
		return false
	var tile_data: TileData = data_layer.get_cell_tile_data(coord)
	return tile_data and tile_data.get_custom_data("type") == "dirt"


func _destroy_map() -> void:
	var areas: Array[MapArea] = _get_map_areas()
	
	#print(areas.size())
	
	if areas.size() <= 1:
		return
	
	var smallest_area_size: int = map_size * map_size
	#var area_to_destroy: MapArea = null
	
	for area in areas:
		if area.tile_count < smallest_area_size:
			smallest_area_size = area.tile_count
	
	if smallest_area_size > max_destroy_count:
		print("can't destroy area. it's too big ", smallest_area_size)
		Player.instance.show_message()
		return
	
	var cells_to_destroy: Array[Vector2i] = []
	
	for area in areas:
		if area.tile_count == smallest_area_size:
			cells_to_destroy += area.cells
	
	for tile in cells_to_destroy:
		#data_layer.set_cell(tile, tile_set.get_source_id(tile_source_idx), water_atlas_placeholder)
		set_tile(tile, TerrainType.WATER)
		temp_dig_layer.erase_cell(tile)
		astar.set_point_solid(tile)
		
		land_tiles.erase(tile)
		#if gold_positions[tile]:
			#gold_positions[tile].queue_free()


func _get_map_areas() -> Array[MapArea]:
	print("get map areas")
	var unvisited: Dictionary = {}
	var regions: Array[MapArea] = []
	var dirt_tiles: Array[Vector2i] = []
	
	for coord in data_layer.get_used_cells():
		var tile_data: TileData = data_layer.get_cell_tile_data(coord)
		if !tile_data:
			continue
		
		var type: String = tile_data.get_custom_data("type")
		
		if type == "dirt":
			dirt_tiles.append(coord)
		elif type != "water":
			unvisited[coord] = true
	
	while not unvisited.is_empty():
		var start: Vector2i = unvisited.keys()[0]
		var region: MapArea = _flood_fill(start, unvisited)
		regions.append(region)
	
	var stray_dirt_tiles: Array[Vector2i]
	for dirt in dirt_tiles:
		var adjacent_regions: Array[MapArea] = []
		
		for direction in directions_8:
			var neighbor: Vector2i = dirt + direction
			
			if get_terrain_type(neighbor) == TerrainType.DIRT:
				continue
			
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
		
		else:
			stray_dirt_tiles.append(dirt)
	
	unvisited.clear()
	
	for tile in stray_dirt_tiles:
		unvisited[tile] = true
	
	while not unvisited.is_empty():
		var start: Vector2i = unvisited.keys()[0]
		var region: MapArea = _flood_fill(start, unvisited)
		regions.append(region)
	
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
		
		for direction in directions_4:
			var neighbor: Vector2i = current + direction
			if unvisited.has(neighbor):
				unvisited.erase(neighbor)
				queue.append(neighbor)
	
	var map_area: MapArea = MapArea.new()
	map_area.tile_count = tile_count
	map_area.cells = tiles
	return map_area

#endregion


#region HELPERS

func is_point_walkable(pos: Vector2) -> bool:
	var coord: Vector2i = local_to_map(pos)
	return map_rect.has_point(coord) and not astar.is_point_solid(coord)


func get_land_tiles() -> Array[Vector2i]:
	return land_tiles
	

func in_water(tile: Vector2i) -> bool:
	return get_terrain_type(tile) == TerrainType.WATER
	#var tile_data: TileData = data_layer.get_cell_tile_data(tile)
	#return !tile_data or tile_data.get_custom_data("type") == "water"


func get_terrain_type(cellPos: Vector2i) -> TerrainType:
	var placeholder_atlas_coords: Vector2i = data_layer.get_cell_atlas_coords(cellPos)
	
	match placeholder_atlas_coords:
		water_atlas_placeholder:
			return TerrainType.WATER
		grass_atlas_placeholder:
			return TerrainType.GRASS
		sand_atlas_placeholder:
			return TerrainType.DIRT
		Vector2i(-1, -1):
			return TerrainType.EMPTY
		_:
			return TerrainType.GRASS


func local_to_map(pos: Vector2) -> Vector2i:
	return data_layer.local_to_map(pos)


func map_to_local(coord: Vector2i) -> Vector2:
	return data_layer.map_to_local(coord)


func get_cell_world(coord: Vector2i) -> Vector2:
	return map_to_local(coord) - Vector2.ONE * TILE_SIZE * 0.5

#endregion


class MapArea:
	var cells: Array[Vector2i]
	var tile_count: int
