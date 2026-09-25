class_name GameInputEvents

static func movement_input() -> Vector2:
	var direction = Vector2.ZERO

	if Input.is_action_pressed("move_left"):
		direction.x = -1
	elif Input.is_action_pressed("move_right"):
		direction.x = 1

	if Input.is_action_pressed("move_up"):
		direction.y = -1
	elif Input.is_action_pressed("move_down"):
		direction.y = 1

	return direction.normalized()

static func is_movement_input() -> bool:
	return Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") \
		or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down")
