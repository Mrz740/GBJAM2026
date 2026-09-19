extends Node

# Add here scenes for the enemies when we eventually have them
const COIN_SCENE: PackedScene = preload("res://Pickups/coin.tscn")
const GOLD_SCENE: PackedScene = preload("res://Test_Pathfinding/scenes/gold.tscn")
const CHEST_SCENE: PackedScene = preload("res://Test_Pathfinding/scenes/chest.tscn")
const KEY_SCENE: PackedScene = preload("res://Test_Pathfinding/scenes/key.tscn")
const POWERUP_SCENE: PackedScene = preload("res://Test_Pathfinding/scenes/powerup.tscn")

const TILE_TYPE_DATA_LAYER: String = "type"
const BLOCKING_TILE_TYPES: Array[String] = ["water"]
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


func unpause_run() -> void:
	_timer.paused = false


func pause_run() -> void:
	_timer.paused = true


func spawn_entity_at(entity: Node2D, tile: Vector2i) -> void:
	_get_spawn_parent().add_child(entity)
	entity.global_position = map.to_global(map.map_to_local(tile))
	_occupied_tiles[tile] = entity
	entity.tree_exiting.connect(free_tile.bind(tile), CONNECT_ONE_SHOT)


func spawn_coin_at(tile: Vector2i) -> void:
	var new_coin: Node2D = COIN_SCENE.instantiate()
	new_coin.value = coin_value
	spawn_entity_at(new_coin, tile)


func drop_coin_at(tile: Vector2i, value: int) -> Coin:
	var new_coin: Coin = COIN_SCENE.instantiate()
	new_coin.value = value
	new_coin.dropped_by_player = true
	new_coin.can_pick_up = false
	spawn_entity_at(new_coin, tile)
	ScoreManager.add_score(-new_coin.value)
	return new_coin


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
	
	# VERY CRUDE FIX TO COINS NOT SPAWNING ON ROCKS
	# =============================================
	var game_map: GameMap = map.get_parent()
	if game_map.temp_dig_layer.get_cell_atlas_coords(tile) == game_map.rock_atlas:
		return false
	# =============================================
	# VERY CRUDE FIX TO COINS NOT SPAWNING ON ROCKS
	
	if tile_data == null:
		return false

	return tile_data.get_custom_data(TILE_TYPE_DATA_LAYER) not in BLOCKING_TILE_TYPES


func free_tile(tile: Vector2i) -> void:
	_occupied_tiles.erase(tile)


func free_tile_at(global_pos: Vector2) -> void:
	if has_map():
		free_tile(map.local_to_map(map.to_local(global_pos)))


func _get_spawn_parent() -> Node:
	if is_instance_valid(spawn_parent):
		return spawn_parent
	return get_tree().current_scene


func _on_timer_timeout() -> void:
	spawn_coin_at_random()
