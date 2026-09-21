extends Node

const MENU_SELECT = preload("res://Test_Pathfinding/assets/TestAudio/menu_select.wav")

const SFX_POLYPHONY: int = 8

const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"
const MASTER_BUS: String = "Master"

var volume_step_size: float = 10.0

var master_volume: float = 100.0
var music_volume: float = 100.0
var sfx_volume: float = 100.0

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_player: int = 0


func _ready() -> void:
	# keep audio running while the tree is paused (pause menu, end-of-day screens)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	music_volume = clampf(music_volume, 0.0, 20.0)
	
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)
	
	for i in SFX_POLYPHONY:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_sfx_players.append(player)
	
	_apply_volume(MASTER_BUS, master_volume)
	_apply_volume(MUSIC_BUS, music_volume)
	_apply_volume(SFX_BUS, sfx_volume)


func play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	if stream == null:
		return
	var player := _sfx_players[_next_sfx_player]
	_next_sfx_player = (_next_sfx_player + 1) % _sfx_players.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.play()


func play_sfx_menu() -> void:
	var player := _sfx_players[_next_sfx_player]
	_next_sfx_player = (_next_sfx_player + 1) % _sfx_players.size()
	player.stream = MENU_SELECT
	player.pitch_scale = 1.0
	player.play()


func play_music(stream: AudioStream, restart_if_same: bool = false) -> void:
	if stream == null:
		stop_music()
		return
	if _music_player.stream == stream and _music_player.playing and not restart_if_same:
		return
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func is_music_playing() -> bool:
	return _music_player.playing


func change_master(direction: float) -> void:
	# -1 to decrease, 1 to increase
	master_volume = _step_volume(master_volume, direction)
	
	_apply_volume(MASTER_BUS, master_volume)


func change_music(direction: float) -> void:
	# -1 to decrease, 1 to increase
	music_volume = _step_volume(music_volume, direction)
	music_volume = clampf(music_volume, 0.0, 20.0)
	_apply_volume(MUSIC_BUS, music_volume)


func change_sfx(direction: float) -> void:
	# -1 to decrease, 1 to increase
	sfx_volume = _step_volume(sfx_volume, direction)
	_apply_volume(SFX_BUS, sfx_volume)


func get_master_volume() -> float:
	return master_volume


func get_music_volume() -> float:
	return music_volume


func get_sfx_volume() -> float:
	return sfx_volume


func _step_volume(current: float, direction: float) -> float:
	return clampf(current + volume_step_size * signf(direction), 0.0, 100.0)


func _apply_volume(bus_name: String, volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		push_warning("Audio bus '%s' not found." % bus_name)
		return
	AudioServer.set_bus_mute(bus_index, is_zero_approx(volume))
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume / 100.0))
