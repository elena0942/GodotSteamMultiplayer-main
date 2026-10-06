extends NodeState
class_name WalkState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D
@export var walk_speed: int = 70
@export var run_speed: int = 100
@export var player_direction: Vector2
@export var is_running = Input.is_action_pressed("run")

var is_kb_done: bool = true
var current_speed: int

func _on_process(_delta: float) -> void:
	pass

func _on_physics_process(_delta: float) -> void:
	if player.is_moving:
		if is_kb_done and not player.is_running:
			current_speed = walk_speed
			animated_sprite_2d.speed_scale = 1.0
		elif is_kb_done and player.is_running:
			current_speed = run_speed
			animated_sprite_2d.speed_scale = 2.0
		else:
			return
	else:
		player.velocity = Vector2.ZERO
		current_speed = walk_speed
		animated_sprite_2d.speed_scale = 1.0
	
	if is_multiplayer_authority():
		player.move_and_slide()
		player.net_position = player.global_position
		player.velocity = player.player_direction * current_speed
		
	match player.player_direction:
		Vector2.UP:    animated_sprite_2d.play("walk_u")
		Vector2.RIGHT: animated_sprite_2d.play("walk_r")
		Vector2.LEFT:  animated_sprite_2d.play("walk_l")
		Vector2.DOWN:  animated_sprite_2d.play("walk_d")

func _on_next_transitions() -> void:
	if !player.is_moving:
		transition.emit("Idle")


## works for SP, not MP
#func _on_physics_process(_delta: float) -> void:
	#print(player.name)
	#var direction: Vector2 = GameInputEvents.movement_input()
	#current_speed = walk_speed
	#var is_moving = Input.is_action_pressed("move_up") \
		#or Input.is_action_pressed("move_down") \
		#or Input.is_action_pressed("move_right") \
		#or Input.is_action_pressed("move_left")
#
	#if is_moving:
		#if is_kb_done: #player cannot speed up if knockback is active
			#current_speed = walk_speed
			#animated_sprite_2d.speed_scale = 1.0
		#else:
			#return
#
#
	#if direction == Vector2.UP:
		#animated_sprite_2d.play("walk_u")
	#elif direction == Vector2.RIGHT:
		#animated_sprite_2d.play("walk_r")
	#elif direction == Vector2.LEFT:
		#animated_sprite_2d.play("walk_l")
	#elif direction == Vector2.DOWN:
		#animated_sprite_2d.play("walk_d")
#
	#if direction != Vector2.ZERO:
		#player.player_direction = direction
		#player.velocity = direction * current_speed
	#else:
		#player.velocity = Vector2.ZERO
#
	#player.move_and_slide()
#
#func _on_next_transitions() -> void:
	#if not player.is_multiplayer_authority():
		#return
	#if !GameInputEvents.is_movement_input():
		#transition.emit("Idle")
	##elif Input.is_action_just_pressed("hit"):
		##animated_sprite_2d.stop()
		##transition.emit("Hit")
func _on_enter() -> void:
	is_running = false

func _on_exit() -> void:
	#animated_sprite_2d.stop()
	pass

func _on_kb_cooldown_timeout():
	is_kb_done = true
