class_name Enemy
extends CharacterBody2D

@export var game_map: GameMap = null
@export var move_speed : float = 5.0
@export var visualize_path: bool = true
@export var idx: int = 0

var current_path: Array[Vector2i]
var can_update_path: bool
var target_position: Vector2
var current_target: Node2D

@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var area_2d: Area2D = %Area2D
@onready var line_2d: Line2D = %Line2D


func _ready() -> void:
	line_2d.global_position = Vector2.ZERO
	line_2d.visible = visualize_path
	if Player.instance != null:
		Player.instance.player_did_move.connect(_update_enemy_path)


func _process(delta: float) -> void:
	_get_closest_target()
	_move_ai(delta)


func _move_ai(delta: float) -> void:
	var current_tile: Vector2i = game_map.local_to_map(global_position)
	
	if game_map.in_water(current_tile):
		destroy_enemy()
		return
	
	game_map.update_enemy_current_tile(self, current_tile)
	
	if current_path.is_empty():
		can_update_path = true
		return
	
	target_position = game_map.map_to_local(current_path.front()) - game_map.tile_size * 0.5
	
	if !game_map.has_enemy_tile_and_can_move(self, current_path.front()):
		return
	
	if current_path.size() > 1:
		if !game_map.has_reserved_tile_and_can_move(self, current_path[1]):
			can_update_path = true
			return
	
	can_update_path = false
	
	# not using move_and_slide() so that enemies can overlap with each other. It's less prone to bugs
	global_position = global_position.move_toward(target_position, move_speed * delta)
	
	if global_position.is_equal_approx(target_position):
		current_path.pop_front()
		can_update_path = true
		
		if current_path.size() > 1:
			game_map.update_enemy_next_tile(self, current_path[1])
		else:
			game_map.update_enemy_next_tile(self, game_map.map_to_local(global_position))


func _update_enemy_path() -> void:
	if !can_update_path:
		return
	if current_target == null:
		return
	
	if game_map.is_point_walkable(current_target.global_position):
		
		var current_tile: Vector2i = game_map.local_to_map(global_position)
		var player_tile: Vector2i = game_map.local_to_map(current_target.global_position)
		
		current_path = game_map.astar.get_id_path(current_tile, player_tile).slice(1)
		
		if visualize_path:
			var test: Array
			for p in current_path:
				var offset: Vector2i = Vector2i.ONE * floori(game_map.tile_size.x * 0.5)
				test.append(p * game_map.tile_size + offset)
			line_2d.points = test


func _get_closest_target() -> void:
	if Player.instance == null:
		current_target = null
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
	
	current_target = closest_target


func destroy_enemy() -> void:
	game_map.enemy_current_tile.erase(self)
	game_map.enemy_next_tile.erase(self)
	queue_free()
