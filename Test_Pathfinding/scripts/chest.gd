class_name Chest
extends Node2D

enum ChestLoot {
	GOLD,
	LIFE,
	POWERUP,
	SHOVEL
}

var _collected: bool = false
var can_pick_up: bool

var loot_dictionary: Dictionary[ChestLoot, float] = {
	ChestLoot.GOLD : 2.0,
	ChestLoot.LIFE : 0.5,
	ChestLoot.POWERUP : 1.0,
	ChestLoot.SHOVEL: 1.0
}

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D


func _ready() -> void:
	animated_sprite_2d.play("closed")
	if GameMap.instance:
		GameMap.instance.map_updated.connect(_on_map_updated)


func _exit_tree():
	if GameMap.instance:
		GameMap.instance.map_updated.disconnect(_on_map_updated)


func _on_map_updated() -> void:
	var coord: Vector2i = GameMap.instance.local_to_map(global_position)
	if GameMap.instance.get_terrain_type(coord) == GameMap.TerrainType.WATER:
		queue_free()


func _on_area_2d_body_entered(body):
	if _collected:
		Player.instance.hide_lack_of_keys()
		return
	
	if body is Player:
		if Player.instance.keys <= 0:
			Player.instance.show_lack_of_keys()
			return
		Player.instance.hide_lack_of_keys()
		Player.instance.update_keys(-1)
		_collected = true
		
		get_chest_loot()
		
		animated_sprite_2d.play("open")
		# Play sound effect


func get_chest_loot() -> void:
	var total_weight: float = 0.0
	
	for i in loot_dictionary:
		total_weight += loot_dictionary[i]
	
	var rng: float = randf()
	var chance_percentage: float = 0.0
	
	var chest_loot: ChestLoot
	for i in loot_dictionary:
		chance_percentage += loot_dictionary[i] / total_weight
		if chance_percentage >= rng:
			chest_loot = i
			break
	
	match chest_loot:
		
		ChestLoot.GOLD:
			var rand_value: int = randi_range(20, 50)
			ScoreManager.add_score(rand_value, "coins")
			Player.instance.gain_money(rand_value)
		
		ChestLoot.LIFE:
			Player.instance.gain_health(1)
		
		ChestLoot.POWERUP:
			Player.instance.gain_powerup()
		
		ChestLoot.SHOVEL:
			Player.instance.upgrade_shovel()
	

func _on_area_2d_body_exited(body):
	if body is Player:
		Player.instance.hide_lack_of_keys()
