extends Node

func _ready() -> void:
	_setup("jump", [_key(KEY_SPACE), _key(KEY_W), _key(KEY_UP)])
	_setup("dash", [_key(KEY_SHIFT)])
	_setup("shoot", [_mouse(MOUSE_BUTTON_LEFT)])
	# Add A and D keys to movement
	InputMap.action_add_event("ui_left", _key(KEY_A))
	InputMap.action_add_event("ui_right", _key(KEY_D))

func _setup(name: String, events: Array) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name)
	else:
		InputMap.action_erase_events(name)
	for e in events:
		InputMap.action_add_event(name, e)

func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	return e

func _mouse(btn: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = btn
	return e
