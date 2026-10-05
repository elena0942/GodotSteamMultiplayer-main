class_name PlayerDummy
extends CharacterBody2D



#### SIGNALS ####

signal healthChanged

#### VARIABLES AND CONSTANTS ####

const MAX_TRAIL_COUNT: int = 50

@export var speed: float = 10.0
@export var player: CharacterBody2D
@export var owner_peer_id: int
@export var player_direction: Vector2
@export var is_moving: bool
@export var net_position: Vector2
@export var trail_color: Color = Color.WHITE
@export var wait_time: float = 1.0
@export var bear_damage: int
@export var is_running: bool
@export var is_muddy: bool = false

var hb_entered: bool
var can_damage: bool
var is_dead: bool
var removing: bool = false

@onready var health: float = max_health
@onready var max_health: float = 100.0
@onready var _hitbox: CollisionShape2D = $DetectArea/Hitbox
@onready var trail_timer = $TrailTimer
@onready var mud_wear_off: Timer = $Timers/MudWearOff

##### FUNCTIONS ######

func _ready():
	healthChanged.emit(100.0, 100.0)
	net_position = global_position
	health = max_health
	await get_tree().process_frame

	$TrackPoints.self_modulate = trail_color
	$TrackPoints.visible = false
	trail_timer.timeout.connect(update_trail)
	trail_timer.start()

	for item in get_tree().get_nodes_in_group("PlayerBEAR"):
		if item.has_node("SoundMarker"):
			item.get_node("SoundMarker").hide()

	if is_multiplayer_authority():
		is_muddy = randi_range(0, 1) == 0
		if is_muddy:
			mud_wear_off.timeout.connect(_on_mud_wear_off)
			mud_wear_off.start()
		else:
			return

func _on_mud_wear_off() -> void:
	print("mud wore off")
	is_muddy = false

func _process(_delta: float) -> void:
	# Tracking functionality
	
	if is_moving:
		removing = false
		trail_timer.paused = false
	else:
		if not removing and not trail_timer.paused:
			trail_timer.paused = true
			var wait := get_tree().create_timer(3.0)
			wait.timeout.connect(_on_pause_finished)

# Tracking
func _on_trail_node_visible() -> void:
	$TrackPoints.show()

func _on_trail_node_invisible() -> void:
	if is_muddy:
		$TrackPoints.hide()

func _on_pause_finished() -> void:
	if is_moving:
		return
	trail_timer.paused = false
	removing = true

func update_trail():
	if is_muddy:
		return
	if is_moving:
		$TrackPoints.add_point(global_position)
		if $TrackPoints.points.size() == MAX_TRAIL_COUNT:
			$TrackPoints.remove_point(0)
	elif removing:
		if not $TrackPoints.points.is_empty():
			$TrackPoints.remove_point(0)
	else:
		removing = false

# Multiplayer
func _enter_tree() -> void:
	print("node name: ", name, " | authority: ", get_multiplayer_authority(), " | my id: ", multiplayer.get_unique_id(), " | is_authority: ", is_multiplayer_authority())
	set_multiplayer_authority(1)

func _physics_process(delta: float) -> void:
	@warning_ignore("unused_parameter")
	if not is_multiplayer_authority():
		global_position = global_position.lerp(net_position, 0.25)
		return
	#is_moving = true
	#player_direction = Vector2.UP
	#velocity = Vector2.UP * speed
	#move_and_slide()
	net_position = global_position

# Health
func set_health(value) -> void:
	health = clampi(value, 0.0, max_health)
	healthChanged.emit(health, max_health)
	if health <= 0:
		die()

func _on_hitbox_entered(area: Area2D) -> void:
	bear_damage = 10.0
	can_damage = true
	hb_entered = true

	if area.is_in_group("PlayerBEAR"):
		if can_damage:
			can_damage = false
			player.take_damage(bear_damage)
			await get_tree().create_timer(wait_time).timeout
			can_damage = true

# Take damage
func take_damage(bear_damage: float) -> void:
	@warning_ignore("unused_parameter")
	health -= bear_damage
	print("took ", bear_damage, "damage. Health is now ", health)
	set_health(health)

# Death
func die() -> bool:
	print("player died") #death logic here
	_hitbox.set_deferred("disabled", true)
	
	is_dead = true
	if is_dead:
		queue_free()
	return is_dead
