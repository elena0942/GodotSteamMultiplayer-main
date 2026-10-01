#### WORKING - SPAWNPOINTS V1 ####

class_name PlayerBear
extends CharacterBody2D

#### SIGNALS ####

signal healthChanged
signal can_track(value: bool)

#### VARIABLES ####

@export var owner_peer_id: int
@export var inventory_data: InventoryData
@export var player_direction: Vector2
@export var is_moving: bool
@export var net_position: Vector2
@export var track_cooldown: float = 1.0
@export var wait_time: float = 1.0
@export var bear_damage: int


var can_damage: bool
var interactable = null
var _building: Node = null
var building: Node:
	set(value):
		set_building(value)
	get:
		return _building
var is_dead: bool
var trails_visible: bool = false
var can_view_trails: bool = true
var playerlist: Array = []
var target_player
var angle: float = 0.0

@onready var player: CharacterBody2D
@onready var health: float = max_health
@onready var max_health: float = 500.0
@onready var _hitbox: CollisionShape2D = $DetectArea/Hitbox
@onready var inventory_ui = $PlayerUI/Inventory/InventoryUI
@onready var camera: Camera2D = $Camera2D
@onready var player_ui: Control = $PlayerUI
@onready var trail_vis_timer: Timer = $TrailVisTimer
@onready var sound_marker: Sprite2D = $SoundMarker

##### DICTIONARIES AND ARRAYS #####



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
	if not is_multiplayer_authority():
		global_position = global_position.lerp(net_position, 0.25)
		return
	var direction: Vector2 = GameInputEvents.movement_input()
	is_moving = direction != Vector2.ZERO
	if direction != Vector2.ZERO:
		player_direction = direction
	
	while get_tree().get_nodes_in_group("PlayerPERSON").is_empty(): #wait until player list populates before running function below
		await get_tree().process_frame
	
	listen(delta)

# Health
func set_health(value) -> void:
	#health = get_node("PlayerUI/ProgressBar").value #connect to ui
	health = clampi(value, 0.0, max_health)
	healthChanged.emit(health, max_health)
	if health <= 0:
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

# Hearing functionality
func listen(delta):
	player = get_tree().get_first_node_in_group("PlayerBEAR")
	target_player = find_nearest_player()
	
	sound_marker.self_modulate.a = 0.0
	
	var vis_tween: Tween = create_tween()
	if target_player.is_moving:
		vis_tween.tween_property(self, "sound_marker.self_modulate.a", 1.0, 2.0) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	elif not target_player.is_moving and vis_tween.is_running():
		vis_tween.kill()
	else:
		return
	var target_angle = get_angle_to(target_player.global_position)
	angle = lerp_angle(angle, target_angle, 10.0 * delta)
	
	var radius = 80.0
	var offset = Vector2(cos(angle), sin(angle)) * radius
	var distance_to_player = global_position.distance_to(target_player.global_position)
	
	sound_marker.global_position = player.global_position + offset
	sound_marker.look_at(target_player.global_position)

	if distance_to_player <= 80.0:
		sound_marker.flip_h = true
	else:
		sound_marker.flip_h = false

func find_nearest_player() -> CharacterBody2D:
	var available_players = get_tree().get_nodes_in_group("PlayerPERSON")
	
	if available_players.is_empty():
		return null
	
	var target_player = available_players[0]
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
	#trails_visible = false
	can_view_trails = false
	for player in get_tree().get_nodes_in_group("Player"):
		if player.has_node("TrackPoints"):
			player.get_node("TrackPoints").hide()
	var cooldown := get_tree().create_timer(10.0)
	cooldown.timeout.connect(_on_trail_cooldown)

func _on_trail_cooldown():
	can_view_trails = true

func track():
	can_view_trails = false
	trail_vis_timer.start()
	
	for player in get_tree().get_nodes_in_group("Player"):
		if player.has_node("TrackPoints"):
			player.get_node("TrackPoints").show()
			print("track works")

# Interaction key (L click) actions
func _process(delta):
	if Input.is_action_just_pressed("interact"):
		print("pressedinteract")
	elif Input.is_action_just_pressed("track") and can_view_trails:
		track()
	self.building = null


# Interaction key (I) actions
func _input(event):
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
