extends Node2D

@export var map: TileMapLayer
@export var spawn_parent: Node


func _ready() -> void:
	if not map:
		push_warning("game_scene: no map assigned, SpawnerManager will have nothing to spawn on.")
		return

	SpawnerManager.register_map(map, spawn_parent)
	SpawnerManager.start_run()
