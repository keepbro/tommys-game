extends Node

func _ready() -> void:
	_setup("jump", [_key(KEY_SPACE), _key(KEY_W), _key(KEY_UP)])
	_setup("dash", [_key(KEY_SHIFT)])
	_setup("shoot", [_mouse(MOUSE_BUTTON_LEFT)])
	_setup("pause", [_key(KEY_P)])

	# VERSUS MODE: two players on one keyboard.
	# Player 1 keeps A/D so the arrow keys belong to Player 2 alone.
	_setup("p1_left", [_key(KEY_A)])
	_setup("p1_right", [_key(KEY_D)])
	_setup("p1_jump", [_key(KEY_W), _key(KEY_SPACE)])
	_setup("p1_dash", [_key(KEY_SHIFT)])
	_setup("p1_shoot", [_mouse(MOUSE_BUTTON_LEFT)])

	_setup("p2_left", [_key(KEY_LEFT)])
	_setup("p2_right", [_key(KEY_RIGHT)])
	_setup("p2_jump", [_key(KEY_UP)])
	_setup("p2_dash", [_key(KEY_CTRL)])
	_setup("p2_shoot", [_key(KEY_ENTER), _key(KEY_KP_0)])
	# Number keys 1-5 use the things in your bag
	var number_keys := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]
	for i in number_keys.size():
		_setup("slot_%d" % (i + 1), [_key(number_keys[i])])
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
