class_name Enemy
extends CharacterBody2D

const THROWABLE: PackedScene = preload("res://Test_Pathfinding/scenes/throwable.tscn")

@export var move_speed : float = 5.0
@export var visualize_path: bool = true
@export var idx: int = 0
@export var throw_rate: float = 5.0

var throw_time: float

var enemy_manager: EnemyManager = null

var enemy_type: EnemyManager.EnemyType
var current_path: Array[Vector2i]
var can_update_path: bool
var target_position: Vector2
#var current_target: Node2D

var crab_detection_radius: float = 60.0
var pirate_detection_radius: float = 35.0
var skeleton_detection_radius: float = 35.0
var enemy_radius: float

var stun_cooldown: float
var stun_time: float = 3.5

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var area_collision_shape: CollisionShape2D = %AreaCollisionShape
@onready var area_2d: Area2D = %Area2D
@onready var line_2d: Line2D = %Line2D
@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D


func setup(manager: EnemyManager, index: int, type: EnemyManager.EnemyType) -> void:
	enemy_manager = manager
	idx = index
	name = "enemy_%s" % index
	enemy_type = type
	
	match enemy_type:
		EnemyManager.EnemyType.CRAB:
			enemy_radius = crab_detection_radius
		EnemyManager.EnemyType.PIRATE:
			enemy_radius = pirate_detection_radius
		EnemyManager.EnemyType.SKELETON:
			enemy_radius = skeleton_detection_radius


func _ready() -> void:
	line_2d.global_position = Vector2.ZERO
	line_2d.visible = visualize_path
	if Player.instance != null:
		Player.instance.player_did_move.connect(_update_enemy_path)
	
	if GameMap.instance != null:
		GameMap.instance.map_dug.connect(_on_map_dug)


func _on_map_dug(coord: Vector2i) -> void:
	var current_tile: Vector2i = GameMap.instance.local_to_map(global_position)
	if current_tile == coord:
		stun()


func stun() -> void:
	match enemy_type:
		EnemyManager.EnemyType.CRAB:
			animated_sprite_2d.play("crab_stunned")
		
		EnemyManager.EnemyType.PIRATE:
			animated_sprite_2d.play("pirate_stunned")
		
		EnemyManager.EnemyType.SKELETON:
			animated_sprite_2d.play("skeleton_stunned")
	
	stun_cooldown = stun_time


func _process(delta: float) -> void:
	
	var current_tile: Vector2i = GameMap.instance.local_to_map(global_position)
	if GameMap.instance.in_water(current_tile):
		destroy_enemy()
		return
	
	if stun_cooldown > 0.0:
		stun_cooldown -= delta
		var enemy_blink_time: float = 5.0
		visible = int(stun_cooldown * enemy_blink_time) % 2 == 0
		collision_shape_2d.disabled = true
		return
	else:
		visible = true
		collision_shape_2d.disabled = false
	
	match enemy_type:
		EnemyManager.EnemyType.CRAB:
			animated_sprite_2d.play("crab_walk")
			_get_random_target_or_player()
			_move_ai(delta)
		
		EnemyManager.EnemyType.PIRATE:
			animated_sprite_2d.play("pirate_walk")
			_set_closest_target()
			_move_ai(delta)
		
		EnemyManager.EnemyType.SKELETON:
			animated_sprite_2d.play("skeleton_walk")
			_get_position_away_from_player()
			_move_ai(delta)
			_throw_items(delta)


func _move_ai(delta: float) -> void:
	if target_position == -Vector2.ONE:
		return
	
	if current_path.is_empty():
		can_update_path = true
		if !Player.instance.dead:
			_update_enemy_path()
		return
	
	var next_tile: Vector2i = current_path.front()
	if enemy_manager.has_occupied_tile(next_tile, self):
		return
	
	can_update_path = false
	#var next_position: Vector2 = GameMap.instance.get_cell_world(current_path.front())
	var next_position: Vector2 = GameMap.instance.map_to_local(current_path.front())
	
	# not using move_and_slide() so that enemies can overlap with each other. It's less prone to bugs
	global_position = global_position.move_toward(next_position, move_speed * delta)
	
	if global_position.is_equal_approx(next_position):
		current_path.pop_front()
		can_update_path = true
		
		var current_tile: Vector2i = GameMap.instance.local_to_map(global_position)
		enemy_manager.update_enemy_current_tile(self, current_tile)
	
	
	#var direction: Vector2 = next_position - global_position
	#if direction.length() > 1.0:
		#velocity = direction.normalized() * move_speed
		#move_and_slide()
	#else:
		#velocity = Vector2.ZERO
		#
		#current_path.pop_front()
		#can_update_path = true
		#
		#var current_tile: Vector2i = GameMap.instance.local_to_map(global_position)
		#enemy_manager.update_enemy_current_tile(self, current_tile)


func _update_enemy_path() -> void:
	if !can_update_path:
		return
	if !is_valid_target():
		return
	
	if GameMap.instance.is_point_walkable(target_position):
		
		var current_tile: Vector2i = GameMap.instance.local_to_map(global_position)
		var target_tile: Vector2i = GameMap.instance.local_to_map(target_position)
		
		current_path = GameMap.instance.astar.get_id_path(current_tile, target_tile)
		
		if current_path.size() > 1:
			current_path.pop_front()
		
		if visualize_path:
			var test: Array
			for p in current_path:
				var offset: Vector2i = Vector2i.ONE * floori(GameMap.instance.TILE_SIZE * 0.5)
				test.append(p * GameMap.instance.TILE_SIZE + offset)
			line_2d.points = test


func _set_closest_target() -> void:
	if Player.instance == null:
		target_position = -Vector2.ONE
		return
	target_position = get_closest_target()


func get_closest_target() -> Vector2:
	var areas: Array = area_2d.get_overlapping_areas()
	
	var closest_target: Node2D = Player.instance
	var max_dist: float = INF
	
	for area in areas:
		var coin: Coin = area.get_parent() as Coin
		if coin == null:
			continue
		
		if !coin.dropped_by_player:
			continue
		
		var current_dist: float = (coin.global_position - global_position).length_squared()
		
		if current_dist < max_dist:
			max_dist = current_dist
			closest_target = coin
	
	return closest_target.global_position


func _get_random_target_or_player() -> void:
	var closest: Vector2 = get_closest_target()
	#if (global_position - Player.instance.global_position).length_squared() < enemy_radius*enemy_radius:
	if closest.distance_squared_to(global_position) < enemy_radius * enemy_radius:
		target_position = closest
		return
	set_random_tile()


func _get_position_away_from_player() -> void:
	var player_pos: Vector2 = Player.instance.global_position
	var radius: float = skeleton_detection_radius
	
	var center: Vector2i = GameMap.instance.local_to_map(player_pos)
	var tiles: Array[Vector2i] = []
	
	var tile_radius: float = ceili(radius / GameMap.instance.TILE_SIZE)
	var min_range: float = tile_radius * 0.75
	
	for x in range(center.x - tile_radius, center.x + tile_radius + 1):
		for y in range(center.y - tile_radius, center.y + tile_radius + 1):
			var coord: Vector2i = Vector2i(x, y)
			
			if enemy_manager.is_valid_tile(coord) and !enemy_manager.has_occupied_tile(coord, self) and coord.distance_squared_to(center) > min_range*min_range:
				tiles.append(coord)
	
	if tiles.is_empty():
		target_position = GameMap.instance.map_to_local(center)
	else:
		target_position = GameMap.instance.map_to_local(tiles[randi_range(0, tiles.size()-1)])


func _throw_items(delta: float) -> void:
	if throw_time > 0.0:
		throw_time -= delta
		return
	throw_time = throw_rate
	
	var throwable: Throwable = THROWABLE.instantiate()
	throwable.global_position = global_position
	get_tree().current_scene.add_child(throwable)
	throwable.throw(Player.instance.global_position, Player.instance.input_direction)


func set_random_tile() -> void:
	target_position = GameMap.instance.map_to_local(enemy_manager.get_random_tile_within_radius(global_position, enemy_radius))


func is_valid_target() -> bool:
	return target_position != -Vector2.ONE


func destroy_enemy() -> void:
	GameMap.instance.spawn_gold_to_center(enemy_type, global_position)
	enemy_manager.enemy_current_tile.erase(self)
	enemy_manager.enemy_next_tile.erase(self)
	enemy_manager.reduce_enemy_count()
	queue_free()
