extends Control

@export var score_label: Label


func _ready() -> void:
	ScoreManager.score_changed.connect(_on_score_changed)
	_on_score_changed(ScoreManager.current_score)


func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "Score: " + str(new_score)
