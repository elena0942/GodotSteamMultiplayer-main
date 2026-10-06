extends NodeState
class_name WalkStateBear

@export var player: PlayerBear
@export var animated_sprite_2d: AnimatedSprite2D
@export var player_direction: Vector2

var current_speed: int
var footstep_timer: Timer
var cycle_denominator: float = 1.07

var anim_name: StringName
var frame_count: int
var fps: float
var cycle_duration: float

@onready var footstep_audio: AudioStreamPlayer2D = $"../../Sound/WalkFootstep_Grass"

func _on_process(_delta: float) -> void:
	pass

func _on_physics_process(_delta: float) -> void:
	if player.is_moving:
		if player.is_kb_done:
			current_speed = player.walk_speed
			animated_sprite_2d.speed_scale = 1.0
		else:
			return
	else:
		player.velocity = Vector2.ZERO
		current_speed = player.walk_speed
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
	elif player.is_running:
		transition.emit("Run")
	elif player.is_sneaking:
		transition.emit("Sneak")
	elif Input.is_action_just_pressed("hit"):
		transition.emit("Attack")
	else:
		return

func _on_detect_area_area_entered(area: Area2D) -> void:
	pass

func _play_footstep() -> void:
	if animated_sprite_2d.animation.begins_with("walk_"):
		footstep_audio.play()

func _on_enter() -> void:
	var anim_name: StringName = animated_sprite_2d.animation
	var frame_count: int = animated_sprite_2d.sprite_frames.get_frame_count(anim_name)
	var fps: float = animated_sprite_2d.sprite_frames.get_animation_speed(anim_name)
	var cycle_duration: float = frame_count / fps / max(animated_sprite_2d.speed_scale, 0.01)
	
	footstep_timer = Timer.new()
	footstep_timer.wait_time = cycle_duration / 1.07
	footstep_timer.timeout.connect(_play_footstep)
	add_child(footstep_timer)
	footstep_timer.start()

	if not is_multiplayer_authority():
		return
	
	player.is_running = false
	animated_sprite_2d.speed_scale = 1.0

	


func _on_exit() -> void:
	if footstep_timer:
		footstep_timer.queue_free()
		footstep_timer = null

func _on_kb_cooldown_timeout():
	player.is_kb_done = true
