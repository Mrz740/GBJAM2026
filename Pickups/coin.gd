class_name Coin
extends Node2D

@export var value: int = 1
@export var pickup_sfx: AudioStream

var dropped_by_player: bool
var can_pick_up: bool = true

var _collected: bool = false

@onready var pickup_area: Area2D = %PickupArea
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D


func _ready() -> void:
	if GameMap.instance:
		GameMap.instance.map_updated.connect(_on_map_updated)
	animated_sprite_2d.play("default")
	timer = 1.0


var timer: float
func _process(delta: float) -> void:
	if timer > 0.0:
		timer -= delta
		return
	can_pick_up = true


func _exit_tree():
	if GameMap.instance:
		GameMap.instance.map_updated.disconnect(_on_map_updated)


func _on_map_updated() -> void:
	var coord: Vector2i = GameMap.instance.local_to_map(global_position)
	if GameMap.instance.get_terrain_type(coord) == GameMap.TerrainType.WATER:
		queue_free()


func _on_pickup_area_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body is Player:
		if !can_pick_up:
			return
		_collected = true
		ScoreManager.add_score(value, "coins")
		SoundManager.play_sfx(pickup_sfx)
		queue_free()
	elif body.is_in_group("enemy") and dropped_by_player:
		_collected = true
		queue_free()


func _on_pickup_area_body_exited(body: Node2D) -> void:
	if body is Player:
		can_pick_up = true
