class_name GameInputEvents

static var _last_axis: String = "x"

static func movement_input() -> Vector2:
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		_last_axis = "x"
	elif Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_down"):
		_last_axis = "y"
	var dir = Vector2.ZERO
	dir.x = 0.0
	dir.y = 0.0
	if Input.is_action_pressed("move_left"):
		dir.x = -1
	elif Input.is_action_pressed("move_right"):
		dir.x = 1
	if Input.is_action_pressed("move_up"):
		dir.y = -1
	elif Input.is_action_pressed("move_down"):
		dir.y = 1

	if dir.x != 0 and dir.y != 0:
		return Vector2(dir.x, 0) if _last_axis == "x" else Vector2(0, dir.y)
	return Vector2(dir.x, dir.y)

static func is_movement_input() -> bool:
	return Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") \
		or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down")
