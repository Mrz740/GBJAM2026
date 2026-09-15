extends Node2D


@export var value: int = 1

var _collected: bool = false

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body is Player:
		_collected = true
		ScoreManager.add_score(value, "coins")
		# Play sound effect
		queue_free()
