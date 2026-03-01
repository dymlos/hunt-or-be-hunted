extends Node
class_name InputMapSetup

static func ensure_actions() -> void:
	# Player 1 movement (WASD)
	_ensure_key_action("p1_move_up", KEY_W)
	_ensure_key_action("p1_move_down", KEY_S)
	_ensure_key_action("p1_move_left", KEY_A)
	_ensure_key_action("p1_move_right", KEY_D)

	# Player 1 aim (IJKL)
	_ensure_key_action("p1_aim_up", KEY_I)
	_ensure_key_action("p1_aim_down", KEY_K)
	_ensure_key_action("p1_aim_left", KEY_J)
	_ensure_key_action("p1_aim_right", KEY_L)

	# Player 1 shoot
	_ensure_key_action("p1_shoot", KEY_SPACE)

	# Player 2 movement (Arrows)
	_ensure_key_action("p2_move_up", KEY_UP)
	_ensure_key_action("p2_move_down", KEY_DOWN)
	_ensure_key_action("p2_move_left", KEY_LEFT)
	_ensure_key_action("p2_move_right", KEY_RIGHT)

	# Player 2 aim (Numpad 8456)
	_ensure_key_action("p2_aim_up", KEY_KP_8)
	_ensure_key_action("p2_aim_down", KEY_KP_5)
	_ensure_key_action("p2_aim_left", KEY_KP_4)
	_ensure_key_action("p2_aim_right", KEY_KP_6)

	# Player 2 shoot
	_ensure_key_action("p2_shoot", KEY_ENTER)

static func _ensure_key_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	else:
		# If the action already exists, let's check if it has any events.
		# If it does, we trust the editor's project.godot settings or existing bindings
		# to avoid overriding or duplicating with clashing keys.
		if InputMap.action_get_events(action_name).size() > 0:
			return

	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action_name, ev)
