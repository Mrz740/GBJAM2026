extends Node2D

@export var start_y: float = 0.0
@export var end_y: float = 10.0
@export var speed: float = 1.0
@export var tween_object: Sprite2D
@export var animation_time: float = 1.0
@export var ghost_material: ShaderMaterial
@export var timer: Timer
@export var intro_scene: IntroScene
@export var exclamation_mark: Sprite2D
@export var skull : AnimatedSprite2D
@export var skull_material : ShaderMaterial

@export var ghost_texture: AtlasTexture
@export var player_texture: AtlasTexture

var time: float = 0.0
var allow_next: bool

var wait_for_skull: bool


func start() -> void:
	show()
	skull.play("default")
	time = 0.0
	timer.timeout.connect(_on_timeout)
	timer.start()


func _process(delta: float) -> void: 
	if visible:
		handle_portrait()
	
	time += delta
	
	var center: float = (start_y + end_y) * 0.5
	var amplitude: float = abs((end_y - start_y) * 0.5)
	
	var y: float = center + sin(time * speed) * amplitude
	
	tween_object.position.y = floor(y)


func handle_portrait() -> void:
	if !allow_next:
		intro_scene.character_portrait.texture = null
		return
	
	if wait_for_skull:
		return
	
	var ghost_dialogue_indices: Array[int] = [0, 1, 2, 4, 6, 7, 8, 9, 10]
	if intro_scene.current_dialogue_idx in ghost_dialogue_indices:
		intro_scene.character_portrait.texture = ghost_texture
	else:
		intro_scene.character_portrait.texture = player_texture


func _on_timeout() -> void:
	animate_panel(-1.0, 1.0, -1, ghost_material)


func animate_panel(start_: float, end: float, direction: int, material: ShaderMaterial) -> void:
	material.set_shader_parameter("direction", direction)
	var tween: Tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(
		func(value: float) -> void:
			material.set_shader_parameter("dither_amount", value),
		start_, end, animation_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.1)
	tween.tween_callback(
		func() -> void:
			exclamation_mark.show()
	)
	tween.tween_interval(0.5)
	tween.tween_callback(
		func() -> void:
			intro_scene.next_dialogue()
			intro_scene.continue_label.show()
			allow_next = true
			
			if material == skull_material:
				wait_for_skull = false
	)


func _input(event: InputEvent) -> void:
	if !visible:
		return
	if !allow_next:
		return
	
	if event.is_action_pressed("A"):
		SoundManager.play_sfx_menu()
		if intro_scene.current_dialogue_idx == 8 and !wait_for_skull:
			wait_for_skull = true
			animate_panel(-1.0, 1.0, -1, skull_material)
			return
			
		intro_scene.handle_next_dialogue()
		
