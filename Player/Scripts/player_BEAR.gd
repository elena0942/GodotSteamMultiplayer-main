#### WORKING - SPAWNPOINTS V1 ####

class_name PlayerBear
extends CharacterBody2D

#### SIGNALS ####

signal healthChanged
#signal can_track(value: bool)

#### VARIABLES ####

@export var owner_peer_id: int
@export var bear_damage: int
@export var run_speed: int = 150
@export var walk_speed: int = 100
@export var sneak_speed: int = 60

@export var player_direction: Vector2
@export var net_position: Vector2

@export var is_moving: bool
@export var is_running: bool
@export var is_sneaking: bool
@export var is_kb_done: bool

@export var track_cooldown: float = 1.0
@export var wait_time: float = 1.0

@export var inventory_data: InventoryData

var can_damage: bool
var interactable = null
var _building: Node = null
var building: Node:
	set(value):
		set_building(value)
	get:
		return _building
var is_dead: bool
var is_attacking: bool = false
# Trail ability
var trails_visible: bool = false
var can_view_trails: bool = true
# Hearing ability
var target_player
var angle: float = 0.0
var ability_total_duration: float = 0.0
var ability_time_remaining: float = 0.0

var water_layer: TileMapLayer = null
var water_state: WaterState = WaterState.NONE

@onready var player: CharacterBody2D

@onready var _attack_area: CollisionShape2D = $AttackArea/Attack
@onready var _hitbox: CollisionShape2D = $DetectArea/Hitbox
@onready var inventory_ui = $PlayerUI/Inventory/InventoryUI
@onready var camera: Camera2D = $Camera2D
@onready var player_ui: Control = $PlayerUI
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var footstep_audio: AudioStreamPlayer2D = $Sound/WalkFootstep_Grass

@onready var track_ability_ui = $PlayerUI/TrackAbility
@onready var sound_marker: Sprite2D = $SoundMarker

@onready var health: float = max_health
@onready var max_health: float = 500.0

@onready var trail_vis_timer: Timer = $Timers/TrailVisTimer
@onready var cooldown: Timer = $Timers/Cooldown

enum WaterState { NONE, EDGE, DEEP }

const WATER_LEVEL_DRY: float = 1.0
const WATER_LEVEL_EDGE: float = 1.0
const WATER_LEVEL_DEEP: float = 0.70

const TRANSITION_DURATION: float = 0.5

##### DICTIONARIES AND ARRAYS #####

var playerlist: Array = []

##### FUNCTIONS ######

# Inventory
@export var inventory : Array[Dictionary] = []
# to access or retrive item: inventory[index]["amount"]
# to add an item: 
#var new_item: Dictionary = {
#	"name": "item name here",
#	"amount": int here
#then: inventory.append(new_item)

# Prompt Visibility (E)
func set_building(new_building):
	if new_building != null:
		$Key.show()
		$KeyPrompt.play("KeyPrompt") #shows "e" keyprompt when near a building
	else:
		$Key.hide()
		$KeyPrompt.stop()
	_building = new_building

func _ready():
	net_position = global_position
	camera.enabled = is_multiplayer_authority()
	player_ui.visible = is_multiplayer_authority()
	health = max_health
	#Global.set_player_reference(self) ## INVENTORY V1
	await get_tree().process_frame
	trail_vis_timer.timeout.connect(_on_trail_vis_timer_timeout)
	
	_attack_area.disabled = true
	is_kb_done = true
	sound_marker.self_modulate.a = 0.0
	
# Spawnpoints

	#if Global.spawn_name != "": 
		#var spawn = get_node_or_null("%" + Global.spawn_name)
		#if spawn:
			#global_position = spawn.global_position
			#print("Spawned at", spawn.name)
		#else:
			#push_warning("Could not find spawn: " + Global.spawn_name)
	#else:
		#print("No spawn point specified.")
	
	set_building(null)

# Knockback and Health

func _on_hitbox_entered(area: Area2D) -> void:
	@warning_ignore("unused_parameter")
	#bear_damage = 10.0
	#can_damage = true
	print("DB player entered bear HB")
	#if area.is_in_group("PlayerPERSON"):
		#if can_damage:
			#can_damage = false
			#player.take_damage(bear_damage)
			#await get_tree().create_timer(wait_time).timeout
			#can_damage = true

# Multiplayer
func _enter_tree() -> void:
	print("node name: ", name, " | authority: ", get_multiplayer_authority(), " | my id: ", multiplayer.get_unique_id(), " | is_authority: ", is_multiplayer_authority())
	set_multiplayer_authority(owner_peer_id)

func _physics_process(delta: float) -> void:
	if !is_attacking:
		match player_direction:
			Vector2.UP:
				_attack_area.position = Vector2(0.0, -70.0)
				_attack_area.rotation_degrees = 90
			Vector2.RIGHT:
				_attack_area.position = Vector2(80.0, 0.0)
				_attack_area.rotation_degrees = 0
			Vector2.LEFT:
				_attack_area.position = Vector2(-80.0, 0.0)
				_attack_area.rotation_degrees = 0
			Vector2.DOWN:
				_attack_area.position = Vector2(0.0, 70.0)
				_attack_area.rotation_degrees = 90

	if not is_multiplayer_authority():
		global_position = global_position.lerp(net_position, 0.25)
		return
	var direction: Vector2 = GameInputEvents.movement_input()
	
	if ability_time_remaining > 0.0:
		ability_time_remaining = max(ability_time_remaining - delta, 0.0) #MP timing fix
	track_ability_ui.value = ability_time_remaining
	
	is_moving = direction != Vector2.ZERO
	is_running = Input.is_action_pressed("run") #only active while holding
	if Input.is_action_just_pressed("sneak"):
		is_sneaking = !is_sneaking
	
	if direction != Vector2.ZERO:
		player_direction = direction
	

	while get_tree().get_nodes_in_group("PlayerPERSON").is_empty(): #wait until player list populates before running function below
		await get_tree().process_frame
	
	listen(delta)
	_ensure_water_layer()
	_update_water_state()

func _ensure_water_layer() -> void:
	if water_layer != null:
		return
	water_layer = get_tree().current_scene.get_node_or_null("Environment/Water")

func _update_water_state() -> void:
	var map_pos: Vector2i = water_layer.local_to_map(global_position)
	var tile_data: TileData = water_layer.get_cell_tile_data(map_pos)

	var new_state := WaterState.NONE
	if tile_data != null:
		if tile_data.get_custom_data("water"):
			new_state = WaterState.DEEP
		elif tile_data.get_custom_data("water_edge"):
			new_state = WaterState.EDGE

	if new_state == water_state:
		return

	water_state = new_state
	var target_level: float = WATER_LEVEL_DRY
	match water_state:
		WaterState.DEEP:
			target_level = WATER_LEVEL_DEEP
		WaterState.EDGE:
			target_level = WATER_LEVEL_EDGE
		WaterState.NONE:
			target_level = WATER_LEVEL_DRY

	create_tween().tween_property(animated_sprite_2d.material, "shader_parameter/water_level", target_level, TRANSITION_DURATION)
	print(target_level)


# Health
func set_health(value) -> void:
	#health = get_node("PlayerUI/ProgressBar").value #connect to ui
	health = clampi(value, 0.0, max_health)
	healthChanged.emit(health, max_health)
	if health <= 0.0:
		die()

# Take damage
func take_damage(player_damage: int) -> void:
	health -= player_damage
	print("took ", player_damage, "damage. Health is now ", health)
	set_health(health)

# Death
func die() -> bool:
	print("bear died") #death logic here
	_hitbox.set_deferred("disabled", true)
	
	is_dead = true
	return is_dead

# Sounds
#func _on_frame_changed() -> void:
	#var frame = animated_sprite_2d.frame
	#if animated_sprite_2d.animation == "walk_u" or animated_sprite_2d.animation == "walk_d" or animated_sprite_2d.animation == "walk_r" or animated_sprite_2d.animation == "walk_l":
		#if frame == 1:# or frame == 3 or frame == 5:
			#footstep_audio.play()

# Hearing functionality
func listen(delta):
	player = get_tree().get_first_node_in_group("PlayerBEAR")
	target_player = find_nearest_player()
	sound_marker.self_modulate.a = 0.0
	
	if target_player == null:
		return
	if not is_multiplayer_authority():
		return
	
	var distance_to_player = global_position.distance_to(target_player.global_position)
	var vis_tween: Tween

	if distance_to_player <= 1000.0 and target_player.is_moving and target_player.is_running: #bear can hear running players from far away + check so that only shift + movement constitutes running
		vis_tween = create_tween()
		vis_tween.tween_property(sound_marker, "self_modulate:a", 1.0, 2.0) \
		.set_ease(Tween.EASE_OUT)
	elif distance_to_player <= 300.0 and target_player.is_moving: #bear can hear walking players if they are close
		vis_tween = create_tween()
		vis_tween.tween_property(sound_marker, "self_modulate:a", 1.0, 2.0) \
		.set_ease(Tween.EASE_OUT)
	elif distance_to_player > 1000.0 or not target_player.is_running: #bear cannot hear players if they are too far away, or only walking
		vis_tween = create_tween()
		vis_tween.tween_property(sound_marker, "self_modulate:a", 0.0, 1.0) \
		.set_ease(Tween.EASE_OUT)
	else:
		return
	var target_angle = get_angle_to(target_player.global_position)
	angle = lerp_angle(angle, target_angle, 10.0 * delta)
	
	var radius = 80.0
	var offset = Vector2(cos(angle), sin(angle)) * radius
	
	
	sound_marker.global_position = player.global_position + offset
	sound_marker.look_at(target_player.global_position)

	if distance_to_player <= 80.0:
		sound_marker.flip_h = true
	else:
		sound_marker.flip_h = false

func find_nearest_player() -> Node:
	var available_players = get_tree().get_nodes_in_group("PlayerPERSON").filter(
		func(p): return p is CharacterBody2D and p.owner_peer_id != 0 and not p.is_muddy) #adds an auth gate to the script, filtering out NPCs and muddy people
	if available_players.is_empty():
		return null

	target_player = available_players[0]
	var nearest_dist = global_position.distance_squared_to(target_player.global_position)
	
	for i in range(1, available_players.size()):
		var player_array_selection = available_players[i]
		var dist = global_position.distance_squared_to(player_array_selection.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			target_player = player_array_selection
	return target_player

# Track functionality
func _on_trail_vis_timer_timeout():
	can_view_trails = false
	for item in get_tree().get_nodes_in_group("Player"):
		if item.has_node("TrackPoints"):
			item.get_node("TrackPoints").hide()
	_on_trail_cooldown()

func _on_trail_cooldown():
	await cooldown.timeout
	can_view_trails = true
	cooldown.stop()

func track():
	if ability_time_remaining > 0.0:
		return
	elif is_running:
		return
	
	can_view_trails = false
	trail_vis_timer.start()
	cooldown.start()
	
	ability_total_duration = trail_vis_timer.wait_time + cooldown.wait_time
	ability_time_remaining = ability_total_duration
	track_ability_ui.max_value = ability_total_duration
	
	if !is_running:
		for item in get_tree().get_nodes_in_group("Player"):
			if item.has_node("TrackPoints"):
				item.get_node("TrackPoints").show()

# Interaction key (L click) actions
func _process(delta):
	@warning_ignore("unused_parameter")
	if Input.is_action_just_pressed("interact"):
		pass
	elif Input.is_action_just_pressed("track") and can_view_trails:
		track()
	self.building = null

# Interaction key (I) actions
func _input(event):
	@warning_ignore("unused_parameter")
	#if event.is_action_pressed("ui_inventory"):
		#inventory_ui.visible = !inventory_ui.visible # Open/close each time "I" is pressed
		#get_tree().paused = !get_tree().paused
	pass

func apply_item_effect(item):
	match item["effect"]:
		"Health":
			#health += 50 -- note: no health functionality yet. func in place for a tester
			print("Health increased by 50HP.")
		_:
			print("There is no effect for this item.")

func add_item(item: ItemData) -> void:
	if inventory_data.add_item(item):
		print("Item added successfully")
	else:
		print("inventory is full")
	var new_item_name := ""
	var new_item_amount := 1
	
	var new_item: Dictionary = {
		"name": (new_item_name),
		"amount": (new_item_amount),
	}
	
	inventory.append(new_item)


#### WORKING - NO SPAWNPOINTS ####
#class_name Player
#extends CharacterBody2D
#
#var player_direction: Vector2
#
#
#var _house: Node = null
#
#var house: Node:
	#set(value):
		#set_house(value)
	#get:
		#return _house
#
#func set_house(new_house):
	#if new_house != null:
		#$Key.show()
		#$KeyPrompt.play("KeyPrompt")
	#else:
		#$Key.hide()
		#$KeyPrompt.stop()
	#_house = new_house
#
#func _ready():
	#global_position = Global.player_pos
	#set_house(null)
#
#func _process(delta):
	#if Input.is_action_just_pressed("interact"):
		#print("pressedinteract")
		#self.house = null
#
#
#func _unhandled_input(event):
	#if event is InputEventKey and event.is_action_pressed("interact") and house != null:
		#print("pressedinteract")
		#house.enter()
		#self.house = null
