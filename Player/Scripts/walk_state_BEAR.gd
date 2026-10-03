extends NodeState
class_name WalkStateBear

@export var player: PlayerBear
@export var animated_sprite_2d: AnimatedSprite2D
@export var walk_speed: int = 200
@export var run_speed: int = 250
@export var sneak_speed: int = 150
@export var player_direction: Vector2
@export var is_running = Input.is_action_pressed("run")

var is_kb_done: bool = true
var current_speed: int
var footstep_timer: Timer

@onready var footstep_audio: AudioStreamPlayer2D = $"../../Sound/WalkFootstep_Grass"

func _on_process(_delta: float) -> void:
	pass

func _on_physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("sneak"):
		player.is_sneaking = !player.is_sneaking
	if player.is_moving:
		if is_kb_done and not player.is_running and not player.is_sneaking:
			current_speed = walk_speed
			animated_sprite_2d.speed_scale = 1.0
		elif is_kb_done and player.is_running:
			current_speed = run_speed
			animated_sprite_2d.speed_scale = 2.0
		elif is_kb_done and player.is_sneaking:
			current_speed = sneak_speed
			animated_sprite_2d.speed_scale = 0.5
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

	if player.is_running and not player.is_sneaking:
		match player.player_direction: #no run anim for bear yet
			Vector2.UP:    animated_sprite_2d.play("walk_u")
			Vector2.RIGHT: animated_sprite_2d.play("walk_r")
			Vector2.LEFT:  animated_sprite_2d.play("walk_l")
			Vector2.DOWN:  animated_sprite_2d.play("walk_d")
	elif player.is_sneaking and not player.is_running:
		match player.player_direction: #no sneak anim for bear yet
			Vector2.UP:    animated_sprite_2d.play("walk_u")
			Vector2.RIGHT: animated_sprite_2d.play("walk_r")
			Vector2.LEFT:  animated_sprite_2d.play("walk_l")
			Vector2.DOWN:  animated_sprite_2d.play("walk_d")
	else:
		match player.player_direction:
			Vector2.UP:    animated_sprite_2d.play("walk_u")
			Vector2.RIGHT: animated_sprite_2d.play("walk_r")
			Vector2.LEFT:  animated_sprite_2d.play("walk_l")
			Vector2.DOWN:  animated_sprite_2d.play("walk_d")

func _on_next_transitions() -> void:
	if not player.is_moving:
		transition.emit("Idle")

@warning_ignore("unused_parameter")
func _on_detect_area_area_entered(area: Area2D) -> void:
	pass

func _play_footstep() -> void:
	var frame = animated_sprite_2d.frame
	if animated_sprite_2d.animation == "walk_u" or animated_sprite_2d.animation == "walk_d" or animated_sprite_2d.animation == "walk_r" or animated_sprite_2d.animation == "walk_l":
		#if frame == 1 or frame == 3 or frame == 5:
		footstep_audio.play()

func _on_enter() -> void:
	if not is_multiplayer_authority():
		return
	
	player.is_running = false
	
	var anim_name: StringName = animated_sprite_2d.animation
	var frame_count: int = animated_sprite_2d.sprite_frames.get_frame_count(anim_name)
	var fps: float = animated_sprite_2d.sprite_frames.get_animation_speed(anim_name)
	var cycle_duration: float = frame_count / fps / max(animated_sprite_2d.speed_scale, 0.01)

	footstep_timer = Timer.new()
	footstep_timer.wait_time = cycle_duration / 1.07 
	footstep_timer.timeout.connect(_play_footstep)
	add_child(footstep_timer)
	footstep_timer.start()

func _on_exit() -> void:
	#animated_sprite_2d.stop()
	if footstep_timer:
		footstep_timer.queue_free()
		footstep_timer = null

func _on_kb_cooldown_timeout():
	is_kb_done = true
