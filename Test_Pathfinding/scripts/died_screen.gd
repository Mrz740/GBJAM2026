extends Control

# using control nodes for buttons instead of buttons because godot has its own handling of menu
# unless we change the advanced input keys in the input map menu

@export var retry: Control
@export var quit: Control
@export var focus: TextureRect
var current_btn: Control


func _ready() -> void:
	current_btn = retry


func _input(event: InputEvent) -> void:
	if !visible:
		return
	
	if event.is_action_pressed("UP") or event.is_action_pressed("DOWN"):
		if current_btn == retry:
			current_btn = quit
		else:
			current_btn = retry
		focus.global_position.y = current_btn.global_position.y
	
	elif event.is_action_pressed("START"):
		if current_btn == retry:
			GameManager.reset_game()
		else:
			GameManager.back_to_menu()
