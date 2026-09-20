class_name Player
extends CharacterBody2D

signal player_did_move
signal keys_updated
signal health_changed(new_health: int)

static var instance: Player

@export var walk_speed: float = 45.0
@export var run_speed: float = 65.0
@export var fast_timer: float = 5.0
@export var end_day_screen: Control
@export var died_screen: Control
@export var dig_indicators: Array[AnimatedSprite2D]

var current_speed: float

var a_hold_time: float
var a_hold: bool
var a_hold_threshold: float = 0.2
var step_threhold: float = 0.5

var health_blink_tween: Tween
var powerup_blink_tween: Tween
var shovel_blink_tween: Tween
var money_target: float = 0.0
var money_tween: Tween
var money_hide_tween: Tween

var blink_time: float = 0.5
var long_blink_time: float = 1.5

var fast_cooldown: float

var message_time: float
var max_message_time: float = 5.0
var can_reach_ship: bool

var current_health: int = 3
var max_health: int = 3

var keys: int = 0 
var max_keys: int = 3
var dead: bool
var digging: bool
var hurt: bool

var input_direction: Vector2 
var old_direction: Vector2

@onready var player_label: Label = %player_label
@onready var collision_area: Area2D = %CollisionArea
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

@onready var key_sprite: AnimatedSprite2D = %KeySprite
@onready var money: Sprite2D = %Money
@onready var money_label: Label = %MoneyLabel
@onready var life: Sprite2D = %Life
@onready var powerup: AnimatedSprite2D = %Powerup
@onready var shovel_powerup: AnimatedSprite2D = %ShovelPowerup


func _enter_tree() -> void:
	instance = self


func _exit_tree() -> void:
	instance = null
	GameMap.instance.map_updated.disconnect(_on_map_updated)


func _ready() -> void:
	for dig in dig_indicators:
		dig.play("default")
	collision_area.body_entered.connect(_on_collision_area_body_entered)
	GameMap.instance.map_updated.connect(_on_map_updated)


func _process(delta: float) -> void:
	if fast_cooldown > 0.0:
		fast_cooldown -= delta
		current_speed = run_speed
	else:
		current_speed = walk_speed
	
	if a_hold:
		a_hold_time += delta
		
		if a_hold_time > a_hold_threshold:
			for i in range(GameManager.shovel_powerup):
				var steps: int = clampi( floori(a_hold_time / step_threhold), 0, GameManager.max_shovel_dig )
				dig_indicators[i].visible = i <= steps
	else:
		for i in range(dig_indicators.size()):
			dig_indicators[i].hide()
	
	if message_time > 0.0:
		player_label.show()
		message_time -= delta
		return
	
	if message_time == -1.0:
		player_label.show()
		return
	
	player_label.hide()


func _physics_process(_delta: float) -> void:
	if dead:
		return
	get_input()
	if a_hold:
		return
	move_and_slide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("A"):
		if GameMap.instance.local_to_map(global_position) == GameMap.instance.ship_tile:
			GameManager.pause_game()
			end_day_screen.show()
			return
		
		a_hold = true
		a_hold_time = 0.0
	
	elif event.is_action_released("A"):
		a_hold = false
		
		if digging:
			return
		
		var coord: Vector2i = GameMap.instance.local_to_map(global_position)
		
		var coords: Array[Vector2i] = [coord]
		if a_hold_time >= a_hold_threshold:
			var dir: Vector2i = Vector2i(roundi(old_direction.x), roundi(old_direction.y))
			coord += dir
			
			var time_held: float = clampi( floori(a_hold_time / step_threhold), 0, GameManager.max_shovel_dig )
			
			for i in range(GameManager.shovel_powerup):
				if time_held >= i:
					coords.append(coord)
					coord += dir
		
		if coords.size() > 1:
			for i in range(1, coords.size()):
				try_dig(coords[i])
				await get_tree().process_frame
		else:
			try_dig(coords[0])
	
	elif event.is_action_pressed("B"):
		drop_coin()


func get_input() -> void:
	input_direction = Input.get_vector("LEFT", "RIGHT", "UP", "DOWN")
	
	if input_direction:
		old_direction = input_direction
		var player_tile: Vector2i = GameMap.instance.local_to_map(global_position)
		var next_tile: Vector2i = Vector2i(roundi(input_direction.x), roundi(input_direction.y) )
		dig_indicators[0].position = GameMap.instance.map_to_local( player_tile + next_tile )
		
		for i in range(1, GameManager.shovel_powerup):
			var previous_tile: Vector2i = GameMap.instance.local_to_map(dig_indicators[i-1].position)
			dig_indicators[i].position = GameMap.instance.map_to_local(previous_tile + next_tile)
	
	if hurt and !animated_sprite_2d.is_playing():
		hurt = false
	
	if digging:
		velocity = Vector2.ZERO
		if !animated_sprite_2d.is_playing():
			digging = false
		return
	
	if !input_direction and !a_hold:
		if !hurt:
			animated_sprite_2d.play("idle")
		velocity = Vector2.ZERO
		return
	
	if !hurt:
		if a_hold:
			if input_direction.x < 0:
				animated_sprite_2d.flip_h = true
			else:
				animated_sprite_2d.flip_h = false
			
			animated_sprite_2d.play("dig_idle")
			return
		animated_sprite_2d.flip_h = false
	
		if input_direction.x < 0:
			animated_sprite_2d.play("walk_left")
		elif input_direction.x > 0:
			animated_sprite_2d.play("walk_right")
		elif input_direction.y < 0:
			animated_sprite_2d.play("walk_up")
		elif input_direction.y > 0:
			animated_sprite_2d.play("walk_down")
	
	player_did_move.emit()
	velocity = input_direction.normalized() * current_speed


func try_dig(coord: Vector2i):
	if GameMap.instance.local_to_map(global_position) == GameMap.instance.ship_tile:
		GameManager.pause_game()
		end_day_screen.show()
		return
	
	animated_sprite_2d.play("dig")
	digging = true
	GameMap.instance.dig(coord)


func try_dig2(coord: Vector2i, coord2: Vector2i):
	if GameMap.instance.local_to_map(global_position) == GameMap.instance.ship_tile:
		GameManager.pause_game()
		end_day_screen.show()
		return
	
	if digging:
		return
	
	animated_sprite_2d.play("dig")
	digging = true
	GameMap.instance.dig(coord)
	GameMap.instance.dig.call_deferred(coord2)


func drop_coin() -> void:
	if ScoreManager.current_score <= 0:
		return
	
	var tile: Vector2i = GameMap.instance.local_to_map(global_position)
	if !SpawnerManager.is_tile_spawnable(tile):
		return
	
	SpawnerManager.drop_coin_at(tile, SpawnerManager.coin_value)


func show_too_big_message() -> void:
	player_label.text = "too big..."
	message_time = max_message_time


func show_lack_of_keys() -> void:
	key_sprite.show()
	key_sprite.play("default")


func hide_lack_of_keys() -> void:
	key_sprite.hide()


func lose_health(amount: int) -> void:
	current_health -= amount
	health_changed.emit(current_health)
	if current_health <= 0:
		dead = true
		animated_sprite_2d.play("death")
		await animated_sprite_2d.animation_finished
		await get_tree().create_timer(0.25).timeout
		died_screen.show()
		return
	digging = false
	hurt = true
	animated_sprite_2d.play("hit")


func gain_health(amount: int) -> void:
	if current_health < max_health:
		current_health += amount
	health_changed.emit(current_health)
	
	if health_blink_tween:
		health_blink_tween.kill()
	
	life.show()
	
	health_blink_tween = create_tween()
	health_blink_tween.tween_interval(blink_time)
	health_blink_tween.tween_callback(life.hide)
	
	health_blink_tween.tween_interval(blink_time)
	health_blink_tween.tween_callback(life.show)
	
	health_blink_tween.tween_interval(long_blink_time)
	health_blink_tween.tween_callback(life.hide)


func update_keys(amount: int) -> void:
	keys += amount
	keys = clamp(keys, 0, max_keys)
	keys_updated.emit()


func gain_powerup() -> void:
	if powerup_blink_tween:
		powerup_blink_tween.kill()
	
	powerup.show()
	powerup.play("default")
	
	powerup_blink_tween = create_tween()
	powerup_blink_tween.tween_interval(blink_time)
	powerup_blink_tween.tween_callback(powerup.hide)
	
	powerup_blink_tween.tween_interval(blink_time)
	powerup_blink_tween.tween_callback(powerup.show)
	
	powerup_blink_tween.tween_interval(long_blink_time)
	powerup_blink_tween.tween_callback(powerup.hide)
	
	fast_cooldown = fast_timer


func upgrade_shovel() -> void:
	if shovel_blink_tween:
		shovel_blink_tween.kill()
	
	GameManager.upgrade_shovel()
	
	shovel_powerup.show()
	shovel_powerup.play("default")
	
	shovel_blink_tween = create_tween()
	shovel_blink_tween.tween_interval(blink_time)
	shovel_blink_tween.tween_callback(shovel_powerup.hide)
	
	shovel_blink_tween.tween_interval(blink_time)
	shovel_blink_tween.tween_callback(shovel_powerup.show)
	
	shovel_blink_tween.tween_interval(long_blink_time)
	shovel_blink_tween.tween_callback(shovel_powerup.hide)


func gain_money(rand_value: float) -> void:
	money_target += rand_value
	
	if money_tween:
		money_tween.kill()
	if money_hide_tween:
		money_hide_tween.kill()
	
	money.show()
	
	var current_value: float = float(money_label.text)
	
	money_tween = create_tween()
	
	money_tween.tween_method(
		func(value: float) -> void:
			money_label.text = str(roundi(value)),
		current_value, money_target, 0.5
	)
	
	money_hide_tween = create_tween()
	money_hide_tween.tween_interval(1.5)
	
	money_hide_tween.tween_callback(
		func() -> void:
			money.hide()
			money_label.text = "0"
	)
	money_target = 0


func _on_map_updated() -> void:
	if GameMap.instance.in_water(GameMap.instance.local_to_map(global_position)):
		lose_health(3)
		return
	
	if !can_reach_ship:
		return
	
	var current_tile: Vector2i = GameMap.instance.local_to_map(global_position)
	var current_path: Array[Vector2i] = GameMap.instance.astar.get_id_path(current_tile, GameMap.instance.ship_tile)
	
	if current_path.is_empty():
		player_label.text = "Can't reach\nship..."
		message_time = -1.0
		can_reach_ship = false
		GameManager.shorten_time()


func _on_collision_area_body_entered(body: Node2D):
	if body.is_in_group("enemy"):
		lose_health(1)
