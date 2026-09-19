extends Control

@export var startup_scene: MainMenu
@export var skip_hold_threshold: float = 3.0
@export var scene_dialogue_resources: Array[SceneDialogueResource]
@export var scene_nodes: Array[Node2D]

var current_scene: SceneDialogueResource

var current_dialogue_idx: int
var current_scene_idx: int
var total_dialogue: int

var start_hold: bool
var start_hold_time: float

var time_per_character: float = 0.05

var label_tween: Tween

@onready var dialogue_label: Label = %DialogueLabel
@onready var bg: TextureRect = %Bg


func _ready() -> void:
	if scene_dialogue_resources.is_empty():
		skip_intro()
	else:
		start_dialogue()


func _process(delta: float) -> void:
	if start_hold:
		start_hold_time += delta
	
	if visible:
		bg.texture = current_scene.scene_texture

func _input(event: InputEvent) -> void:
	if !visible:
		return
	if event.is_action_pressed("A"):
		var text_size: int = current_scene.scene_dialogue[current_dialogue_idx].length()
		if dialogue_label.visible_characters == -1 or dialogue_label.visible_characters == text_size:
			
			if current_dialogue_idx < current_scene.scene_dialogue.size()-1:
				next_dialogue()
			else:
				next_scene()
		else:
			label_tween.kill()
			dialogue_label.visible_characters = -1
	
	if event.is_action_pressed("START"):
		start_hold = true
		start_hold_time = 0.0
		
	elif event.is_action_released("START"):
		start_hold = false
		if start_hold_time > skip_hold_threshold:
			skip_intro()


func start_dialogue() -> void:
	current_dialogue_idx = -1
	current_scene_idx = 0
	current_scene = scene_dialogue_resources[current_scene_idx]
	
	if current_scene_idx < scene_nodes.size():
		if scene_nodes[current_scene_idx].has_method("start"):
			scene_nodes[current_scene_idx].start()
	
	for scene in scene_dialogue_resources:
		total_dialogue += scene.scene_dialogue.size()
	if current_dialogue_idx < current_scene.scene_dialogue.size():
		next_dialogue()
	else:
		next_scene()


func next_scene() -> void:
	if current_scene_idx == scene_nodes.size():
		return
	scene_nodes[current_scene_idx].hide()
	current_scene_idx += 1
	
	if current_scene_idx < scene_nodes.size():
		var scene_node: Node2D = scene_nodes[current_scene_idx]
		if scene_node.has_method("start"):
			scene_node.start()
		else:
			scene_node.show()
	
	if current_scene_idx >= scene_dialogue_resources.size():
		skip_intro()
		return
	current_scene = scene_dialogue_resources[current_scene_idx]
	current_dialogue_idx = -1
	next_dialogue()


func next_dialogue() -> void:
	current_dialogue_idx += 1
	dialogue_label.text = current_scene.scene_dialogue[current_dialogue_idx]
	dialogue_label.visible_characters = 0
	
	var character_count : int = dialogue_label.text.length()
	var character_delay : float = time_per_character
	
	if label_tween != null and label_tween.is_running():
		label_tween.kill()
	
	label_tween = create_tween()
	
	for i in character_count:
		label_tween.tween_callback(
			func() -> void:
				dialogue_label.visible_characters += 1
		)
		label_tween.tween_interval(character_delay)


func skip_intro() -> void:
	startup_scene.in_intro_scene = false
	hide()
