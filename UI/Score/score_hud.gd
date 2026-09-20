extends Control

@export var score_label: Label
@export var life_icons: Array[TextureRect]
@export var key_icons: Array[TextureRect]
@export var days_label: Label
@export var time_label: Label


func _ready() -> void:
	ScoreManager.score_changed.connect(_on_score_changed)
	Player.instance.keys_updated.connect(_on_keys_updated)
	
	_on_score_changed(ScoreManager.current_score)
	
	var player: Player = Player.instance
	if player:
		player.health_changed.connect(_on_health_changed)
		_on_health_changed(player.current_health)
		_on_keys_updated()
	
	days_label.text = "Day%s" % GameManager.current_day 


func _process(_delta: float) -> void:
	time_label.text = "%03d" % GameManager.get_time_left()


func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "%03d" % new_score


func _on_health_changed(new_health: int) -> void:
	for i in life_icons.size():
		life_icons[i].visible = i < new_health


func _on_keys_updated() -> void:
	for i in life_icons.size():
		key_icons[i].visible = i < Player.instance.keys
