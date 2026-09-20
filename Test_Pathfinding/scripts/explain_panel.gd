extends Panel

@export var died: Control
@export var end_day: Control
@export var pause_menu: Control
@export var options_menu: Control

@export var next_panel: Control

var current_page: int = -1

func _input(event: InputEvent) -> void:
	if died.visible or end_day.visible or pause_menu.visible or options_menu.visible:
		return
	
	if event.is_action_pressed("SELECT"):
		if current_page == -1:
			next_panel.hide()
			show()
			GameManager.pause_game()
			current_page = 0
		else:
			current_page += 1
			next_panel.show()
			
			if current_page >= 2:
				hide()
				current_page = -1
				GameManager.unpause_game()
