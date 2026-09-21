extends Node

signal on_timeout

var current_day: int
var target_gold: int
var day_difficulty: float
var time_day: float = 200.0
var times_beaten: int

var skip_intro: bool

var shorten_time_days: Array[float] = [15.0, 10.0, 5.0]

var _timer: Timer

var shovel_powerup: int = 1
var max_shovel_dig: int = 4

func _ready() -> void:
	times_beaten = 0
	skip_intro = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_timer = Timer.new()
	_timer.wait_time = time_day
	_timer.one_shot = false
	_timer.autostart = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)


func start_timer() -> void:
	_timer.stop()
	_timer.wait_time = time_day
	_timer.start()


func stop_timer() -> void:
	_timer.stop()


func pause_timer() -> void:
	_timer.paused = true


func unpause_timer() -> void:
	_timer.paused = false


func get_time_left() -> float:
	return _timer.time_left


func _on_timer_timeout() -> void:
	on_timeout.emit()


func shorten_time() -> void:
	_timer.stop()
	_timer.wait_time = shorten_time_days[current_day - 1]
	_timer.start()


func pause_game() -> void:
	get_tree().paused = true
	SpawnerManager.pause_run()
	ScoreManager.pause_run()
	pause_timer()


func unpause_game() -> void:
	get_tree().paused = false
	SpawnerManager.unpause_run()
	ScoreManager.unpause_run()
	unpause_timer()


func start_game() -> void:
	if times_beaten == 0:
		target_gold = randi_range(200, 350)
	elif times_beaten == 1:
		target_gold = randi_range(400, 600)
	else:
		target_gold = randi_range(800, 999)
	
	ScoreManager.start_run()
	current_day = 1
	reset_shovel()
	get_tree().change_scene_to_file("res://Scenes/game_scene.tscn")
	start_timer()


func end_game() -> void:
	times_beaten += 1
	back_to_menu()


func reset_game() -> void:
	current_day = 1
	reset_shovel()
	ScoreManager.stop_run()
	ScoreManager.current_score = 0
	get_tree().reload_current_scene()
	start_timer()


func next_day() -> void:
	current_day += 1
	get_tree().reload_current_scene()
	start_timer()


func punish_next_day() -> void:
	ScoreManager.current_score /= 2
	next_day()


func back_to_menu() -> void:
	skip_intro = true
	ScoreManager.stop_run()
	SpawnerManager.stop_run()
	reset_shovel()
	SoundManager.stop_music()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/startup_scene.tscn")


func upgrade_shovel() -> void:
	if shovel_powerup < max_shovel_dig:
		shovel_powerup += 1


func reset_shovel() -> void:
	shovel_powerup = 1
