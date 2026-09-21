extends Panel

@export var buttons: Array[Control]
@export var focus_texture: TextureRect
@export var pause_menu: Control
var current_btn: Control


func _ready():
	current_btn = buttons[0]


func _input(event: InputEvent) -> void:
	if !visible:
		return
	
	if event.is_action_pressed("UP"):
		SoundManager.play_sfx_menu()

		var current_idx: int = buttons.find(current_btn)
		current_btn = buttons[ (current_idx - 1) % buttons.size() ]
		update_focus_position()
	elif event.is_action_pressed("DOWN"):
		var current_idx: int = buttons.find(current_btn)
		current_btn = buttons[ (current_idx + 1) % buttons.size() ]
		update_focus_position()
	
	if event.is_action_pressed("LEFT"):
		SoundManager.play_sfx_menu()
		
		decrease_volume()
	elif event.is_action_pressed("RIGHT"):
		SoundManager.play_sfx_menu()

		increase_volume()
	
	if event.is_action_pressed("START"):
		SoundManager.play_sfx_menu()
		
		if current_btn == buttons[3]:
			hide()
			open_pause.call_deferred()


func update_focus_position() -> void:
	focus_texture.global_position = current_btn.global_position - Vector2(14, 0)


func decrease_volume() -> void:
	if current_btn == buttons[0]:
		SoundManager.change_master(-1)
	
	elif current_btn == buttons[1]:
		SoundManager.change_music(-1)
	
	elif current_btn == buttons[2]:
		SoundManager.change_sfx(-1)
		
	update_audio_labels()


func increase_volume() -> void:
	if current_btn == buttons[0]:
		SoundManager.change_master(1)
	
	elif current_btn == buttons[1]:
		SoundManager.change_music(1)
	
	elif current_btn == buttons[2]:
		SoundManager.change_sfx(1)
	
	update_audio_labels()


func update_audio_labels() -> void:
	buttons[0].text = str(roundi(SoundManager.get_master_volume()))
	buttons[1].text = str(roundi(SoundManager.get_music_volume()))
	buttons[2].text = str(roundi(SoundManager.get_sfx_volume()))


func open_pause() -> void:
	pause_menu.show()
