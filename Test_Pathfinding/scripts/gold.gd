class_name Gold
extends Area2D

var dropped_by_player: bool
var can_pick_up: bool = true


func _on_body_entered(body: Node2D):
	if !can_pick_up:
		return
	
	if body == Player.instance:
		body.current_gold += 1
		queue_free()
	elif body.is_in_group("enemy") and dropped_by_player:
		queue_free()


func _on_body_exited(body):
	if body == Player.instance:
		can_pick_up = true
