extends Node2D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("START"):
		ScoreManager.start_run()
		get_tree().change_scene_to_file("res://Scenes/game_scene.tscn")