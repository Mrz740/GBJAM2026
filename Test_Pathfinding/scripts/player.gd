class_name Player
extends CharacterBody2D

signal player_did_move

static var instance: Player

@export var gold_scene: PackedScene
@export var game_map: GameMap
@export var move_speed: float = 5.0
@onready var sprite_2d: Sprite2D = %Sprite2D

var current_gold: int = 0


func _enter_tree() -> void:
	instance = self


func _exit_tree() -> void:
	instance = null


func _process(delta):
	get_input()


func get_input() -> void:
	var input_direction: Vector2 = Input.get_vector("LEFT", "RIGHT", "UP", "DOWN")
	
	if !input_direction:
		velocity = Vector2.ZERO
		return
	
	player_did_move.emit()
	velocity = input_direction.normalized() * move_speed


func _physics_process(_delta: float) -> void:
	move_and_slide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("A"):
		game_map.dig(global_position)
	elif event.is_action_pressed("B"):
		drop_gold()


func drop_gold() -> void:
	if current_gold <= 0:
		return
	
	var gold_node: Gold = gold_scene.instantiate()
	get_tree().current_scene.add_child(gold_node)
	
	var tile: Vector2i = game_map.local_to_map(global_position)
	gold_node.global_position = game_map.map_to_local(tile)
	
	gold_node.dropped_by_player = true
	gold_node.can_pick_up = false
