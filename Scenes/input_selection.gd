extends Node2D

enum Scheme { NONE, WASD, ARROWS }

const SCHEME_AB_KEYS := {
	Scheme.WASD: [KEY_Z, KEY_X],
	Scheme.ARROWS: [KEY_J, KEY_K],
}

const SCHEME_BINDINGS := {
	Scheme.WASD: {
		"UP": KEY_W, "DOWN": KEY_S, "LEFT": KEY_A, "RIGHT": KEY_D,
		"A": KEY_X, "B": KEY_Z,
	},
	Scheme.ARROWS: {
		"UP": KEY_UP, "DOWN": KEY_DOWN, "LEFT": KEY_LEFT, "RIGHT": KEY_RIGHT,
		"A": KEY_K, "B": KEY_J,
	},
}

@onready var wasd_option: ColorRect = $WasdOption
@onready var arrows_option: ColorRect = $ArrowOption

var _active_scheme: Scheme = Scheme.NONE
var _pressed_keys: Array = []

func _ready() -> void:
	_update_visuals()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("START"):
		_try_confirm()
		return

	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	var keycode: int = event.keycode

	if keycode in SCHEME_AB_KEYS[Scheme.WASD]:
		_register_key(Scheme.WASD, keycode)
	elif keycode in SCHEME_AB_KEYS[Scheme.ARROWS]:
		_register_key(Scheme.ARROWS, keycode)

func _register_key(scheme: Scheme, keycode: int) -> void:
	if scheme != _active_scheme:
		_active_scheme = scheme
		_pressed_keys.clear()
		_pressed_keys.append(keycode)
	else:
		if keycode in _pressed_keys:
			_pressed_keys.erase(keycode)
		else:
			_pressed_keys.append(keycode)

	_update_visuals()

func _try_confirm() -> void:
	if _active_scheme == Scheme.NONE:
		return
	if _pressed_keys.size() < SCHEME_AB_KEYS[_active_scheme].size():
		return

	_apply_scheme(_active_scheme)
	_transition_to_scene("res://Scenes/test_scene.tscn")

func _apply_scheme(scheme: Scheme) -> void:
	for action in SCHEME_BINDINGS[scheme]:
		InputMap.action_erase_events(action)
		var ev := InputEventKey.new()
		ev.keycode = SCHEME_BINDINGS[scheme][action]
		InputMap.action_add_event(action, ev)

func _transition_to_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func _update_visuals() -> void:
	var wasd_progress := 0.0
	var arrows_progress := 0.0

	if _active_scheme == Scheme.WASD:
		wasd_progress = float(_pressed_keys.size()) / SCHEME_AB_KEYS[Scheme.WASD].size()
	elif _active_scheme == Scheme.ARROWS:
		arrows_progress = float(_pressed_keys.size()) / SCHEME_AB_KEYS[Scheme.ARROWS].size()

	wasd_option.modulate = Color.WHITE.lerp(Color(1, 1, 1, 0.35), 1.0 - wasd_progress)
	arrows_option.modulate = Color.WHITE.lerp(Color(1, 1, 1, 0.35), 1.0 - arrows_progress)
