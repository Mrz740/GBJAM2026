class_name EndDayScreen
extends Control

# using control nodes for buttons instead of buttons because godot has its own handling of menu
# unless we change the advanced input keys in the input map menu

@export var days_left_label: Label
@export var panel_mat: ShaderMaterial
@export var focus: TextureRect

@export var current_gold_label: Label
@export var target_gold_label: Label
@export var gold_texture: TextureRect

var current_btn: Control
var animation_timer: float = 0.5

@onready var yes: Control = %Yes
@onready var no: Control = %No


func _ready() -> void:
	GameManager.on_timeout.connect(punish_next_day)
	
	panel_mat.set_shader_parameter("dither_amount", 1.0)
	
	GameManager.pause_game()
	
	var days_left: int = 4 - GameManager.current_day
	
	if days_left > 1:
		days_left_label.text = "%s DAYS LEFT" % days_left
	else:
		days_left_label.text = "%s DAY LEFT" % days_left
		
	update_gold()
	target_gold_label.text = "%03d" % GameManager.target_gold
	
	await get_tree().create_timer(1.5).timeout
	ScoreManager.old_score = ScoreManager.current_score
	days_left_label.hide()
	current_gold_label.hide()
	target_gold_label.hide()
	gold_texture.hide()
	
	await get_tree().create_timer(0.1).timeout
	animate_panel(1.0, -1.0, -1)
	
	await get_tree().create_timer(animation_timer + 0.01).timeout
	GameManager.unpause_game()
	current_btn = yes
	hide()


func update_gold():
	gold_texture.show()
	current_gold_label.show()
	target_gold_label.show()
	
	var tween: Tween = create_tween()
	tween.tween_method(
		func(value: float) -> void:
			ScoreManager.old_score = roundi(value)
			current_gold_label.text = "%03d" % ScoreManager.old_score,
		float(ScoreManager.old_score), float(ScoreManager.current_score), 1.0
	)


func animate_panel(start: float, end: float, direction: int) -> void:
	panel_mat.set_shader_parameter("direction", direction)
	var tween: Tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(
		func(value: float) -> void:
			panel_mat.set_shader_parameter("dither_amount", value),
		start, end, animation_timer
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _input(event: InputEvent) -> void:
	if !visible:
		return
	
	if event.is_action_pressed("LEFT") or event.is_action_pressed("RIGHT"):
		current_btn = no if current_btn == yes else yes
		focus.global_position = current_btn.global_position - Vector2(8, 4)
	
	elif event.is_action_pressed("A"):
		SoundManager.play_sfx_menu()
		if current_btn == yes:
			if GameManager.current_day >= 3:
				animate_panel(-1.0, 1.0, 1)
				await get_tree().create_timer(animation_timer + 0.01).timeout
				update_gold()
				handle_ending()
			else:
				animate_panel(-1.0, 1.0, 1)
				await get_tree().create_timer(animation_timer + 0.01).timeout
				GameManager.next_day()
		
		else:
			hide()
			GameManager.unpause_game.call_deferred()

func punish_next_day() -> void:
	animate_panel(-1.0, 1.0, 1)
	await get_tree().create_timer(animation_timer + 0.01).timeout
	GameManager.punish_next_day()


var label_tween: Tween
func handle_ending() -> void:
	if ScoreManager.current_score >= GameManager.target_gold:
		if GameManager.times_beaten >= 2:
			days_left_label.text = "You had paid the toll. You are free!"
			days_left_label.visible_characters = -1
			days_left_label.show()
		else:
			days_left_label.text = "You're free...?"
			days_left_label.visible_characters = 11
			days_left_label.show()
			
			var character_count : int = days_left_label.text.length()
			var character_delay : float = 0.25
			
			if label_tween != null and label_tween.is_running():
				label_tween.kill()
			
			label_tween = create_tween()
			label_tween.tween_interval(0.5)
			for i in 4:
				label_tween.tween_callback(
					func() -> void:
						days_left_label.visible_characters += 1
				)
				label_tween.tween_interval(character_delay)
	
	else:
		days_left_label.text = "You lose"
	
	await get_tree().create_timer(3.0).timeout
	GameManager.end_game()
