extends Node

var volume_step_size: float = 10.0

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0


func change_master(direction: float) -> void:
	# -1 to decrease, 1 to increase
	pass


func change_music(direction: float) -> void:
	# -1 to decrease, 1 to increase
	pass


func change_sfx(direction: float) -> void:
	# -1 to decrease, 1 to increase
	pass


func get_master_volume() -> float:
	return master_volume


func get_music_volume() -> float:
	return music_volume


func get_sfx_volume() -> float:
	return sfx_volume
