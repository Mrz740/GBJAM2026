class_name Player
extends CharacterBody2D

signal player_did_move

static var instance: Player

@export var gold_scene: PackedScene
@export var game_map: GameMap
@export var move_speed: float = 5.0

var current_gold: int = 0

@onready var player_label: Label = %player_label
@onready var collision_area: Area2D = %CollisionArea
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D


func _enter_tree() -> void:
	instance = self


func _exit_tree() -> void:
	instance = null


func _ready() -> void:
	collision_area.body_entered.connect(_on_collision_area_body_entered)


func _process(delta):
	if message_time > 0.0:
		player_label.show()
		message_time -= delta
		return
	player_label.hide()


func _physics_process(_delta: float) -> void:
	get_input()
	move_and_slide()


func get_input() -> void:
	var input_direction: Vector2 = Input.get_vector("LEFT", "RIGHT", "UP", "DOWN")
	
	if !input_direction:
		velocity = Vector2.ZERO
		return
	
	player_did_move.emit()
	velocity = input_direction.normalized() * move_speed


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


var message_time: float
var max_message_time: float = 5.0
func show_message() -> void:
	message_time = max_message_time
	player_label.show()


func _on_collision_area_body_entered(body: Node2D):
	if body.is_in_group("enemy"):
		hide()
