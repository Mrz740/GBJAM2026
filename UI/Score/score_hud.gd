extends Control

@export var score_label: Label
@export var life_icons: Array[TextureRect]


func _ready() -> void:
	ScoreManager.score_changed.connect(_on_score_changed)
	_on_score_changed(ScoreManager.current_score)

	var player: Player = Player.instance
	if player:
		player.health_changed.connect(_on_health_changed)
		_on_health_changed(player.current_health)


func _on_score_changed(new_score: int) -> void:
	if score_label:
		#score_label.text = "Score: " + str(new_score)
		score_label.text = str(new_score)


func _on_health_changed(new_health: int) -> void:
	for i in life_icons.size():
		life_icons[i].visible = i < new_health
