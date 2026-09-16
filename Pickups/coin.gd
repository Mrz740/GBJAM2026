class_name Coin
extends Node2D


@export var value: int = 1

var dropped_by_player: bool
var can_pick_up: bool = true

var _collected: bool = false

@onready var pickup_area: Area2D = %PickupArea


func _on_pickup_area_body_entered(body: Node2D) -> void:
	if _collected:
		return

	if body is Player:
		if !can_pick_up:
			return
		_collected = true
		ScoreManager.add_score(value, "coins")
		SpawnerManager.collected_coins += 1
		body.current_gold += 1
		# Play sound effect
		queue_free()
	elif body.is_in_group("enemy") and dropped_by_player:
		_collected = true
		queue_free()


func _on_pickup_area_body_exited(body: Node2D) -> void:
	if body is Player:
		can_pick_up = true
