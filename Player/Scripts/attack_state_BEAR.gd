extends NodeState
class_name AttackStateBear

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D
@onready var state_machine = get_parent()

var player_direction: Vector2

func _on_process(_delta: float) -> void:
	pass

func _on_enter() -> void:
	print("Player AttackState")
	
	var casted_player = player as Player
	if casted_player == null:
		return 
	if Input.is_action_pressed("hit"):
		if player.player_direction == Vector2.UP:
			animated_sprite_2d.play("hit_u")
		elif player.player_direction == Vector2.RIGHT:
			animated_sprite_2d.play("hit_r")
		elif player.player_direction == Vector2.LEFT:
			animated_sprite_2d.play("hit_l")
		elif player.player_direction == Vector2.DOWN:
			animated_sprite_2d.play("hit_d")
		else:
			animated_sprite_2d.play("hit_d")

func _on_next_transitions() -> void:
	if not player.is_multiplayer_authority():
		return
	GameInputEvents.movement_input()

	if GameInputEvents.is_movement_input():
		transition.emit("Walk")
	else:
		transition.emit("Idle")

func _on_exit() -> void:
	animated_sprite_2d.stop()
