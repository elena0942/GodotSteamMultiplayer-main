extends NodeState
class_name AttackStateBear

@export var player: CharacterBody2D
@export var animated_sprite_2d: AnimatedSprite2D

@onready var state_machine = get_parent()
@onready var attack_cooldown: Timer = $"../../Timers/Attack Cooldown"

var current_speed: int
var player_direction: Vector2

func _ready() -> void:
	attack_cooldown.timeout.connect(_on_attack_cooldown) #switch from using  timer to on_animation_finished when slash is done

func _on_physics_process(_delta: float) -> void:
	match player.player_direction: #no attack anim for bear yet
		Vector2.UP:    animated_sprite_2d.play("hurt_u")
		Vector2.RIGHT: animated_sprite_2d.play("hurt_r")
		Vector2.LEFT:  animated_sprite_2d.play("hurt_l")
		Vector2.DOWN:  animated_sprite_2d.play("hurt_d")
	if !is_multiplayer_authority():
		return
	if player.is_sneaking:
		transition.emit("Sneak")
	
func _on_attack_cooldown() -> bool: #on animated sprite finished, when it exists
	player.is_attacking = false
	#if animated_sprite_2d.animation == "Attack":
	player._attack_area.disabled = true
	return player.is_attacking

func _on_enter() -> void:
	#if not is_multiplayer_authority():
		#return
	player.is_attacking = true
	player._attack_area.disabled = false
	attack_cooldown.start()


func _on_next_transitions() -> void:
	if not player.is_multiplayer_authority():
		return
	if !attack_cooldown.is_stopped() and player.is_attacking: #don't transition until bear is done attacking
		return
	if player.is_moving:
		transition.emit("Walk")
	else:
		transition.emit("Idle")

func _on_exit() -> void:
	if not player.is_multiplayer_authority():
		return
	animated_sprite_2d.stop()
	player.is_attacking = false
