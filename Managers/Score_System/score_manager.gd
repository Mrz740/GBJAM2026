extends Node

signal score_changed(new_score: int)

var points_per_tick: int = 1
var seconds_per_tick: float = 0.5

var current_score: int = 0
var current_score_multiplier: int = 1

var _timer: Timer

var total_score: Dictionary

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = seconds_per_tick
	_timer.one_shot = false
	_timer.autostart = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)


# The function is called add but it can be used to substract points
func add_score(points: int, source: String = "") -> void:
	var gained := points * current_score_multiplier
	current_score += gained
	score_changed.emit(current_score)
	total_score[source] = total_score.get(source, 0) + gained


func set_multiplier(value: int) -> void:
	if value == current_score_multiplier:
		return
	current_score_multiplier = max(1, value)


func start_run() -> void:
	reset()
	_timer.start()


func stop_run() -> void:
	_timer.stop()


func reset() -> void:
	current_score = 0
	set_multiplier(1)
	score_changed.emit(current_score)


func _on_timer_timeout() -> void:
	if points_per_tick <= 0:
		return
	add_score(points_per_tick, "time")
