class_name MainMenu
extends Node2D

# using control nodes for buttons instead of buttons because godot has its own handling of menu
# unless we change the advanced input keys in the input map menu


@export var menu_buttons: Array[Control]
@export var settings_buttons: Array[Control]

var current_btn: Control

@onready var main_menu: Control = %MainMenu
@onready var settings_menu: Control = %SettingsMenu
@onready var credits_menu: Control = %CreditsMenu

@onready var focus_texture: TextureRect = %Focus

var in_intro_scene: bool = true


func _ready() -> void:
	current_btn = menu_buttons[0]
	open_menu()


func _input(event: InputEvent) -> void:
	if in_intro_scene:
		return
	if event.is_action_pressed("UP"):
		update_current_button(true)
	elif event.is_action_pressed("DOWN"):
		update_current_button(false)
	
	if event.is_action_pressed("START"):
		press_button()
	
	if !settings_menu.visible:
		return
		
	if event.is_action_pressed("LEFT"):
		decrease_volume()
	
	elif event.is_action_pressed("RIGHT"):
		increase_volume()


func start_game() -> void:
	GameManager.start_game()


func open_menu() -> void:
	settings_menu.hide()
	credits_menu.hide()
	main_menu.show()
	focus_texture.show()
	
	current_btn = menu_buttons[0]
	update_focus_position()


func open_settings() -> void:
	main_menu.hide()
	credits_menu.hide()
	settings_menu.show()
	focus_texture.show()
	
	current_btn = settings_buttons[0]
	update_focus_position()


func open_credits() -> void:
	focus_texture.hide()
	settings_menu.hide()
	main_menu.hide()
	credits_menu.show()


func update_focus_position() -> void:
	focus_texture.global_position = current_btn.global_position - Vector2(14, 0)


func update_current_button(up: bool) -> void:
	if !main_menu.visible and !settings_menu.visible:
		return
	if up:
		if main_menu.visible:
			var current_idx: int = menu_buttons.find(current_btn)
			current_btn = menu_buttons[ (current_idx - 1) % menu_buttons.size() ]
		elif settings_menu.visible:
			var current_idx: int = settings_buttons.find(current_btn)
			current_btn = settings_buttons[ (current_idx - 1) % settings_buttons.size() ]
		update_focus_position()
	else:
		if main_menu.visible:
			var current_idx: int = menu_buttons.find(current_btn)
			current_btn = menu_buttons[ (current_idx + 1) % menu_buttons.size() ]
		elif settings_menu.visible:
			var current_idx: int = settings_buttons.find(current_btn)
			current_btn = settings_buttons[ (current_idx + 1) % settings_buttons.size() ]
		update_focus_position()


func press_button() -> void:
	if main_menu.visible:
		if current_btn == menu_buttons[0]:
			start_game()
		elif current_btn == menu_buttons[1]:
			open_settings()
		elif current_btn == menu_buttons[2]:
			open_credits()
	
	elif settings_menu.visible:
		if current_btn == settings_buttons[3]:
			open_menu()
	
	elif credits_menu.visible:
		open_menu()


func decrease_volume() -> void:
	if current_btn == settings_buttons[0]:
		SoundManager.change_master(-1)
		settings_buttons[0].text = str(SoundManager.get_master_volume())
	
	elif current_btn == settings_buttons[1]:
		SoundManager.change_music(-1)
		settings_buttons[1].text = str(SoundManager.get_music_volume())
	
	elif current_btn == settings_buttons[2]:
		SoundManager.change_sfx(-1)
		settings_buttons[2].text = str(SoundManager.get_sfx_volume())


func increase_volume() -> void:
	if current_btn == settings_buttons[0]:
		SoundManager.change_master(1)
		settings_buttons[0].text = str(SoundManager.get_master_volume())
	
	elif current_btn == settings_buttons[1]:
		SoundManager.change_music(1)
		settings_buttons[1].text = str(SoundManager.get_music_volume())
	
	elif current_btn == settings_buttons[2]:
		SoundManager.change_sfx(1)
		settings_buttons[2].text = str(SoundManager.get_sfx_volume())
