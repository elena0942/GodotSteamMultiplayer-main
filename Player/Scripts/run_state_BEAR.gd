extends NodeState
class_name RunStateBear

@export var player: PlayerBear
@export var animated_sprite_2d: AnimatedSprite2D
@export var player_direction: Vector2

var current_speed: int
var footstep_timer: Timer

@onready var footstep_audio: AudioStreamPlayer2D = $"../../Sound/WalkFootstep_Grass"

func _on_process(_delta: float) -> void:
	pass

func _on_physics_process(_delta: float) -> void:
	if !is_multiplayer_authority():
		return
	if player.is_moving:
		if player.is_kb_done and not player.is_sneaking:
			current_speed = player.run_speed
			animated_sprite_2d.speed_scale = 2.0
		else:
			return
	else:
		animated_sprite_2d.speed_scale = 1.0
		transition.emit("Idle")
	
	if is_multiplayer_authority():
		player.move_and_slide()
		player.net_position = player.global_position
		player.velocity = player.player_direction * current_speed
	
	match player.player_direction: #no run anim for bear yet
		Vector2.UP:    animated_sprite_2d.play("walk_u")
		Vector2.RIGHT: animated_sprite_2d.play("walk_r")
		Vector2.LEFT:  animated_sprite_2d.play("walk_l")
		Vector2.DOWN:  animated_sprite_2d.play("walk_d")


func _play_footstep() -> void:
	if animated_sprite_2d.animation.begins_with("walk_"): # change to run_ when run anims are added!
		footstep_audio.play()

func _on_enter() -> void:
	if not is_multiplayer_authority():
		return
	
	player.is_running = false
	animated_sprite_2d.speed_scale = 2.0
	
	var anim_name: StringName = animated_sprite_2d.animation
	var frame_count: int = animated_sprite_2d.sprite_frames.get_frame_count(anim_name)
	var fps: float = animated_sprite_2d.sprite_frames.get_animation_speed(anim_name)
	var cycle_duration: float = frame_count / fps / max(animated_sprite_2d.speed_scale, 0.01)
	
	footstep_timer = Timer.new()
	footstep_timer.wait_time = cycle_duration / 4.0
	footstep_timer.timeout.connect(_play_footstep)
	add_child(footstep_timer)
	footstep_timer.start()

func _on_exit() -> void:
	if footstep_timer:
		footstep_timer.queue_free()
		footstep_timer = null

func _on_next_transitions() -> void:
	if !player.is_running and player.is_moving:
		transition.emit("Walk")
	elif !player.is_running and !player.is_moving:
		transition.emit("Idle")
	elif player.is_running and player.is_sneaking:
		player.is_sneaking = false
		return
