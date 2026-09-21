extends Panel

@export var buttons: Array[Control]
@export var focus_texture: TextureRect
@export var options_menu: Control
@export var died_screen: Control
@export var end_day_screen: Control

var current_btn: Control


func _ready():
	current_btn = buttons[0]


func _input(event: InputEvent) -> void:
	if !visible and !died_screen.visible and !end_day_screen.visible:
		if event.is_action_pressed("START"):
			SoundManager.play_sfx_menu()
			GameManager.pause_game()
			show.call_deferred()
		return
	
	if event.is_action_pressed("UP"):
		SoundManager.play_sfx_menu()
		
		var current_idx: int = buttons.find(current_btn)
		current_btn = buttons[ (current_idx - 1) % buttons.size() ]
		update_focus_position()
	
	elif event.is_action_pressed("DOWN"):
		SoundManager.play_sfx_menu()
		
		var current_idx: int = buttons.find(current_btn)
		current_btn = buttons[ (current_idx + 1) % buttons.size() ]
		update_focus_position()
	
	if event.is_action_pressed("START"):
		SoundManager.play_sfx_menu()
		
		if current_btn == buttons[0]:
			hide()
			unpause_game.call_deferred()
		elif current_btn == buttons[1]:
			GameManager.reset_game()
		elif current_btn == buttons[2]:
			open_options()
		elif current_btn == buttons[3]:
			GameManager.back_to_menu()


func update_focus_position() -> void:
	focus_texture.global_position = current_btn.global_position - Vector2(14, 0)


func unpause_game() -> void:
	GameManager.unpause_game()


func open_options() -> void:
	options_menu.show()
	hide()
