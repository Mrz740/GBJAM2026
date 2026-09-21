class_name ChestKey
extends Node2D

@export var value: int = 10
@export var key_sfx: AudioStream

var can_pick_up: bool = true
var test_timer: float = 0.25


func _exit_tree():
	if GameMap.instance:
		GameMap.instance.map_updated.disconnect(_on_map_updated)


func _ready() -> void:
	if GameMap.instance:
		GameMap.instance.map_updated.connect(_on_map_updated)


func _process(delta: float) -> void:
	if test_timer > 0.0:
		test_timer -= delta
		return
	can_pick_up = true


func _on_map_updated() -> void:
	var coord: Vector2i = GameMap.instance.local_to_map(global_position)
	if GameMap.instance.get_terrain_type(coord) == GameMap.TerrainType.WATER:
		queue_free()


func _on_area_2d_body_entered(body):
	if body is Player:
		if !can_pick_up:
			return
		if Player.instance.keys >= Player.instance.max_keys:
			return
		Player.instance.update_keys(1)
		SoundManager.play_sfx(key_sfx)
		queue_free()
