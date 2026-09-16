class_name Enemy
extends CharacterBody2D

@export var move_speed : float = 5.0
@export var visualize_path: bool = true
@export var idx: int = 0

var enemy_manager: EnemyManager = null
var game_map: GameMap

var enemy_type: EnemyManager.EnemyType
var current_path: Array[Vector2i]
var can_update_path: bool
var target_position: Vector2
#var current_target: Node2D

var crab_detection_radius: float = 60.0
var pirate_detection_radius: float = 35.0
var skeleton_detection_radius: float = 35.0
var enemy_radius: float

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var area_collision_shape: CollisionShape2D = %AreaCollisionShape
@onready var area_2d: Area2D = %Area2D
@onready var line_2d: Line2D = %Line2D


func setup(manager: EnemyManager, map: GameMap, index: int, type: EnemyManager.EnemyType) -> void:
	enemy_manager = manager
	game_map = map
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


func _process(delta: float) -> void:
	
	var current_tile: Vector2i = game_map.local_to_map(global_position)
	if game_map.in_water(current_tile):
		destroy_enemy()
		return
	
	match enemy_type:
		EnemyManager.EnemyType.CRAB:
			_get_random_target_or_player()
			animated_sprite_2d.play("crab_walk")
			_move_ai(delta)
		
		EnemyManager.EnemyType.PIRATE:
			_get_closest_target()
			_move_ai(delta)
		
		EnemyManager.EnemyType.SKELETON:
			_get_closest_target()
			_move_ai(delta)


func _move_ai(delta: float) -> void:
	
	if target_position == -Vector2.ONE:
		return
	
	if current_path.is_empty():
		can_update_path = true
		if !Player.instance.dead:
			_update_enemy_path()
		return
	
	var next_tile: Vector2i = current_path.front()
	if enemy_manager.has_occupied_tile(next_tile):
		return
	
	can_update_path = false
	var next_position: Vector2 = game_map.get_cell_world(current_path.front())
	
	# not using move_and_slide() so that enemies can overlap with each other. It's less prone to bugs
	global_position = global_position.move_toward(next_position, move_speed * delta)
	
	if global_position.is_equal_approx(next_position):
		current_path.pop_front()
		can_update_path = true
		
		var current_tile: Vector2i = game_map.local_to_map(global_position)
		enemy_manager.update_enemy_current_tile(self, current_tile)


func _update_enemy_path() -> void:
	if !can_update_path:
		return
	if !is_valid_target():
		return
	
	if game_map.is_point_walkable(target_position):
		
		var current_tile: Vector2i = game_map.local_to_map(global_position)
		var target_tile: Vector2i = game_map.local_to_map(target_position)
		
		current_path = game_map.astar.get_id_path(current_tile, target_tile)
		
		if current_path.size() > 1:
			current_path.pop_front()
		
		if visualize_path:
			var test: Array
			for p in current_path:
				var offset: Vector2i = Vector2i.ONE * floori(game_map.TILE_SIZE * 0.5)
				test.append(p * game_map.TILE_SIZE + offset)
			line_2d.points = test


func _get_closest_target() -> void:
	if Player.instance == null:
		target_position = -Vector2.ONE
		return
		
	var areas: Array = area_2d.get_overlapping_areas()
	
	var closest_target: Node2D = Player.instance
	var max_dist: float = INF
	
	for area in areas:
		if area is not Gold:
			continue
			
		var gold: Gold = area as Gold
		var current_dist: float = (gold.global_position - global_position).length_squared()
		
		if current_dist < max_dist and gold.dropped_by_player:
			max_dist = current_dist
			closest_target = gold
	
	target_position = closest_target.global_position


func _get_random_target_or_player() -> void:
	if (global_position - Player.instance.global_position).length_squared() < enemy_radius*enemy_radius:
		target_position = Player.instance.global_position
		return
	
	set_random_tile()


func set_random_tile() -> void:
	target_position = game_map.map_to_local(enemy_manager.get_random_tile_within_radius(global_position, enemy_radius))


func is_valid_target() -> bool:
	return target_position != -Vector2.ONE


func destroy_enemy() -> void:
	enemy_manager.enemy_current_tile.erase(self)
	enemy_manager.enemy_next_tile.erase(self)
	queue_free()
