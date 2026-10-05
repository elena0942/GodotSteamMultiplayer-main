extends NodeState
class_name IdleState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D

var player_direction: Vector2
var is_kb_done: bool = true
var hb_entered: bool

func _on_process(_delta: float) -> void:
	pass

func _on_physics_process(_delta: float) -> void:
	var casted_player = player as Player
	if casted_player == null:
		return 

	match player.player_direction:
		Vector2.UP: animated_sprite_2d.play("idle_u")
		Vector2.DOWN: animated_sprite_2d.play("idle_d")
		Vector2.RIGHT: animated_sprite_2d.play("idle_r")
		Vector2.LEFT: animated_sprite_2d.play("idle_l")

func _on_hitbox_entered(area: Area2D) -> void:
	if !area.is_in_group("PlayerBEAR"):
		return
	else:
		var bear = get_tree().get_first_node_in_group("PlayerBEAR")
		var bear_hitbox = bear.get_node("DetectArea") as Area2D
		
		if bear_hitbox:
			transition.emit("Hurt")
		else:
			return

func _on_next_transitions() -> void:
	if player.is_moving and is_kb_done and not hb_entered:
		transition.emit("Walk")
	elif hb_entered:
		transition.emit("Hurt")
	elif is_multiplayer_authority() and Input.is_action_pressed("hit"):
		transition.emit("Hit")

func _on_enter() -> void:
	pass

## works for SP, not MP
#func _on_next_transitions() -> void:
	#if not player.is_multiplayer_authority():
		#return
	#GameInputEvents.movement_input()
#
	#if GameInputEvents.is_movement_input() and is_kb_done: #player cannot move until knockback is done
		#transition.emit("Walk")
	#elif Input.is_action_pressed("hit"):
		#transition.emit("Hit")

func _on_exit() -> void:
	animated_sprite_2d.stop()

func _on_kb_cooldown_timeout():
	is_kb_done = true
	return is_kb_done
