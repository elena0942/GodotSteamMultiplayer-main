extends NodeState
class_name HurtState

@export var player: CharacterBody2D
@export var animated_sprite_2d: AnimatedSprite2D
@export var walk_speed: int = 70

@onready var state_machine = get_parent()
@onready var kb_cooldown := $"../../Timers/KB Cooldown"
@onready var player_walk_script := $"../Walk"

var player_direction: Vector2

var kb_just_happened: bool
var kb_idle_time : float = 1.0
var hurt_anim : String
var is_kb_done: bool
var bear_attack_area: Area2D

func on_process(delta : float):
	@warning_ignore("unused_parameter")
	pass

func knockback():
	var bear_player = get_tree().get_first_node_in_group("PlayerBEAR") as CharacterBody2D #could be MP error only if more than 1 bear
	
	match player.player_direction:
		Vector2.UP:
			hurt_anim = "hurt_u"
		Vector2.RIGHT:
			hurt_anim = "hurt_r"
		Vector2.LEFT:
			hurt_anim = "hurt_l"
		Vector2.DOWN:
			hurt_anim = "hurt_d"
	
	if player and bear_attack_area and is_multiplayer_authority():
		
		var kb_dir = (player.global_position - bear_player.global_position).normalized()
		var kb_force := 600.0

		player.velocity = kb_dir * kb_force
	
	animated_sprite_2d.speed_scale = 1.0
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
	if area.is_in_group("BearAttackArea"):
		bear_attack_area = area
		knockback()

func _on_physics_process(delta: float) -> void:
	var direction: Vector2 = GameInputEvents.movement_input()
	if is_multiplayer_authority():
		player.velocity = player.velocity.move_toward(Vector2.ZERO, 800.0 * delta)
			
		if direction != Vector2.ZERO:
			player.player_direction = direction
		player.move_and_slide()
		player.net_position = player.global_position
	match player.player_direction:
		Vector2.UP: hurt_anim = "hurt_u"
		Vector2.RIGHT: hurt_anim = "hurt_r"
		Vector2.LEFT: hurt_anim = "hurt_l"
		Vector2.DOWN: hurt_anim = "hurt_d"

func _on_next_transitions() -> void:
	if not is_multiplayer_authority():
		return
	#if is_kb_done:
		#transition.emit("Idle")

func Enter() -> void:
	#knockback()
	pass

func transition_to():
	pass
