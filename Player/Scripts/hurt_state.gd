extends NodeState
class_name HurtState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D
@export var walk_speed: int = 170

@onready var bear_player = get_tree().get_first_node_in_group("PlayerBEAR")
@onready var state_machine = get_parent()
@onready var kb_cooldown := $"../../KB Cooldown"
@onready var player_walk_script := $"../Walk"

var player_direction: Vector2

var is_attacking: bool
var kb_just_happened: bool
var kb_idle_time : float = 1.0
var hurt_anim : String
var is_kb_done: bool

func on_process(delta : float):
	pass

func knockback():
	print("DEBUG: Player KB (hurt_state.gd)")
	player = get_tree().get_first_node_in_group("PlayerPERSON") as CharacterBody2D #could be MP error
	bear_player = get_tree().get_first_node_in_group("PlayerBEAR") as CharacterBody2D #could be MP error
	
	if player and bear_player:
		
		var kb_dir = (player.global_position - bear_player.global_position).normalized()
		var kb_force := 600.0

		player.velocity = kb_dir * kb_force

	animated_sprite_2d.stop()
	animated_sprite_2d.play(hurt_anim) #change to hurt_anim
	kb_just_happened = true
	kb_cooldown.start()


func _on_kb_cooldown_timeout():
	transition.emit("Idle")
	kb_just_happened = false
	is_kb_done = true
	return is_kb_done
	

func _on_hitbox_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerBEAR"):
		knockback()

func _on_physics_process(delta: float) -> void:
	var direction: Vector2 = GameInputEvents.movement_input()
	if player:
		player.velocity = player.velocity.move_toward(Vector2.ZERO, 800.0 * delta)
		
		if direction == Vector2.LEFT:
			hurt_anim = "hurt_l"
		elif direction == Vector2.RIGHT:
			hurt_anim = "hurt_r"
		elif direction == Vector2.UP:
			hurt_anim = "hurt_u"
		elif direction == Vector2.DOWN:
			hurt_anim = "hurt_d"
			
		if direction != Vector2.ZERO:
			player.player_direction = direction
		player.move_and_slide()

func _on_next_transitions() -> void:
	if not is_multiplayer_authority():
		return

func Enter() -> void:
	#knockback()
	pass

func transition_to():
	pass
