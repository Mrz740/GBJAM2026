class_name Player
extends CharacterBody2D

signal player_did_move
signal health_changed(new_health: int)

static var instance: Player

@export var game_map: GameMap
@export var move_speed: float = 5.0

var current_health: int = 3
var max_health: int = 3

var current_gold: int = 0
var dead: bool
var digging: bool
var hurt: bool

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
	if dead:
		return
	get_input()
	move_and_slide()


func get_input() -> void:
	var input_direction: Vector2 = Input.get_vector("LEFT", "RIGHT", "UP", "DOWN")
	
	if hurt and !animated_sprite_2d.is_playing():
		hurt = false

	if digging:
		velocity = Vector2.ZERO
		if !animated_sprite_2d.is_playing():
			digging = false
		return
	
	if !input_direction:
		if !hurt:
			animated_sprite_2d.play("idle")
		velocity = Vector2.ZERO
		return

	if !hurt:
		if input_direction.y < 0:
			animated_sprite_2d.play("walk_up")
		elif input_direction.y > 0:
			animated_sprite_2d.play("walk_down")

		if input_direction == Vector2.RIGHT or input_direction == Vector2.LEFT:
			if animated_sprite_2d.animation == "walk_up":
				animated_sprite_2d.play("walk_up")
			else:
				animated_sprite_2d.play("walk_down")

	player_did_move.emit()
	velocity = input_direction.normalized() * move_speed


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("A"):
		if digging:
			return
		animated_sprite_2d.play("dig")
		digging = true
		game_map.dig(global_position)
	elif event.is_action_pressed("B"):
		drop_coin()


func drop_coin() -> void:
	if current_gold <= 0:
		return

	var tile: Vector2i = game_map.local_to_map(global_position)
	if !SpawnerManager.is_tile_spawnable(tile):
		return

	current_gold -= 1
	SpawnerManager.drop_coin_at(tile, SpawnerManager.coin_value)


var message_time: float
var max_message_time: float = 5.0
func show_message() -> void:
	message_time = max_message_time
	player_label.show()


func _on_collision_area_body_entered(body: Node2D):
	if body.is_in_group("enemy"):
		current_health -= 1
		health_changed.emit(current_health)
		if current_health <= 0:
			dead = true
			animated_sprite_2d.play("death")
			#hide()
			await animated_sprite_2d.animation_finished
			await get_tree().create_timer(0.25).timeout
			$"../HUDLayer/DiedScreen".show()
			return

		digging = false
		hurt = true
		animated_sprite_2d.play("hit")


