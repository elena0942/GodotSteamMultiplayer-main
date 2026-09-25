extends NodeState
class_name WalkState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D
@export var walk_speed: int = 170
@export var player_direction: Vector2

var is_kb_done: bool = true
var current_speed: int

func _on_process(_delta: float) -> void:
	pass

func _on_physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	else:
		print(player.name)
		var direction: Vector2 = GameInputEvents.movement_input()
		current_speed = walk_speed
		var is_moving = Input.is_action_pressed("move_up") \
			or Input.is_action_pressed("move_down") \
			or Input.is_action_pressed("move_right") \
			or Input.is_action_pressed("move_left")

		if is_moving:
			if is_kb_done: #player cannot speed up if knockback is active
				current_speed = walk_speed
				animated_sprite_2d.speed_scale = 1.0
			else:
				return


		if direction == Vector2.UP:
			animated_sprite_2d.play("walk_u")
		elif direction == Vector2.RIGHT:
			animated_sprite_2d.play("walk_r")
		elif direction == Vector2.LEFT:
			animated_sprite_2d.play("walk_l")
		elif direction == Vector2.DOWN:
			animated_sprite_2d.play("walk_d")

		if direction != Vector2.ZERO:
			player.player_direction = direction
			player.velocity = direction * current_speed
		else:
			player.velocity = Vector2.ZERO

		player.move_and_slide()

func _on_detect_area_area_entered(area: Area2D) -> void:
	pass

func _on_next_transitions() -> void:
	if not player.is_multiplayer_authority():
		return
	if !GameInputEvents.is_movement_input():
		transition.emit("Idle")
	#elif Input.is_action_just_pressed("hit"):
		#animated_sprite_2d.stop()
		#transition.emit("Hit")

func _on_enter() -> void:
	pass

func _on_exit() -> void:
	animated_sprite_2d.stop()

func _on_kb_cooldown_timeout():
	is_kb_done = true
