extends Node

# Add here scenes for the enemies when we eventually have them
const COIN_SCENE: PackedScene = preload("res://Pickups/coin.tscn")

const TILE_TYPE_DATA_LAYER: String = "type"
const BLOCKING_TILE_TYPES: Array[String] = ["placeholder1", "placeholder2"]
const INVALID_TILE: Vector2i = Vector2i(-1, -1)

var coin_value: int = 1
var seconds_per_coin: float = 3.0

var map: TileMapLayer = null
var spawn_parent: Node = null

var _timer: Timer

var _occupied_tiles: Dictionary[Vector2i, Node2D] = {}


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = seconds_per_coin
	_timer.one_shot = false
	_timer.autostart = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)


func register_map(new_map: TileMapLayer, new_spawn_parent: Node = null) -> void:
	map = new_map
	spawn_parent = new_spawn_parent if new_spawn_parent else new_map
	_occupied_tiles.clear()

	if not map.tree_exiting.is_connected(unregister_map):
		map.tree_exiting.connect(unregister_map)


func unregister_map() -> void:
	stop_run()
	if map and map.tree_exiting.is_connected(unregister_map):
		map.tree_exiting.disconnect(unregister_map)
	map = null
	spawn_parent = null
	_occupied_tiles.clear()


func has_map() -> bool:
	return is_instance_valid(map)


func start_run() -> void:
	_timer.start()


func stop_run() -> void:
	_timer.stop()


func spawn_entity_at(entity: Node2D, tile: Vector2i) -> void:
	entity.position = map.map_to_local(tile)
	_get_spawn_parent().add_child(entity)
	_occupied_tiles[tile] = entity


func spawn_coin_at(tile: Vector2i) -> void:
	var new_coin: Node2D = COIN_SCENE.instantiate()
	new_coin.value = coin_value
	spawn_entity_at(new_coin, tile)


func spawn_coin_at_random() -> bool:
	var tile: Vector2i = get_random_tile()
	if tile == INVALID_TILE:
		return false
	spawn_coin_at(tile)
	return true


func get_random_tile() -> Vector2i:
	if not has_map():
		push_warning("SpawnerManager: no map registered, cannot pick a random tile.")
		return INVALID_TILE

	var candidates: Array[Vector2i] = []

	for coords in map.get_used_cells():
		if is_tile_spawnable(coords):
			candidates.append(coords)

	if candidates.is_empty():
		return INVALID_TILE

	return candidates.pick_random()


func is_tile_spawnable(tile: Vector2i) -> bool:
	if is_instance_valid(_occupied_tiles.get(tile)):
		return false

	var tile_data: TileData = map.get_cell_tile_data(tile)
	if tile_data == null:
		return false

	return tile_data.get_custom_data(TILE_TYPE_DATA_LAYER) not in BLOCKING_TILE_TYPES


func free_tile_at(position: Vector2) -> void:
	if has_map():
		_occupied_tiles.erase(map.local_to_map(position))


func _get_spawn_parent() -> Node:
	if is_instance_valid(spawn_parent):
		return spawn_parent
	return get_tree().current_scene


func _on_timer_timeout() -> void:
	spawn_coin_at_random()
