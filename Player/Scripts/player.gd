#### WORKING - SPAWNPOINTS V1 ####

class_name Player
extends CharacterBody2D

#### SIGNALS ####

signal healthChanged
signal ownerPeerId(int)

#### VARIABLES AND CONSTANTS ####

const MAX_TRAIL_COUNT: int = 50

@export var player: Player
@export var inventory_data: InventoryData


@export var player_direction: Vector2
@export var net_position: Vector2

@export var owner_peer_id: int
@export var bear_damage: int

@export var trail_color: Color = Color.WHITE

@export var wait_time: float = 1.0

@export var is_running: bool
@export var is_moving: bool
@export var is_muddy: bool = false

var current_interactable: Node = null
var hb_entered: bool
var can_damage: bool
var _building: Node = null
var building: Node:
	set(value):
		set_building(value)
	get:
		return _building
var is_dead: bool
var removing: bool = false
var can_interact: bool
var is_attacking: bool = false
var is_in_water: bool = false

@onready var health: float = max_health
@onready var max_health: float = 100.0
@onready var _hitbox: CollisionShape2D = $DetectArea/Hitbox
@onready var inventory_ui = $PlayerUI/Inventory/InventoryUI
@onready var camera: Camera2D = $Camera2D
@onready var player_ui: Control = $PlayerUI
@onready var state_machine: Node = $StateMachine
@onready var trail_timer = $Timers/TrailTimer
@onready var mud_wear_off: Timer = $Timers/MudWearOff

##### FUNCTIONS ######

func _ready():
	healthChanged.emit(100.0, 100.0)
	net_position = global_position
	camera.enabled = is_multiplayer_authority()
	player_ui.visible = is_multiplayer_authority()
	health = max_health
	#Global.set_player_reference(self) ## INVENTORY V1
	await get_tree().process_frame
	
	# Tracking
	$TrackPoints.self_modulate = trail_color
	$TrackPoints.visible = false
	trail_timer.timeout.connect(update_trail)
	trail_timer.start()
	
	## Sound
	#await get_tree().get_nodes_in_group("PlayerBEAR")
	#for item in get_tree().get_nodes_in_group("PlayerBEAR"):
		#if item.has_node("SoundMarker"):
			#item.get_node("SoundMarker").hide()


func _process(_delta: float) -> void:
	# Interaction key actions
	
	if Input.is_action_just_pressed("interact") and current_interactable == null:
		self.building = null
	elif Input.is_action_just_pressed("interact") and current_interactable != null:
		Global.playerInteracted.emit(current_interactable.name, self)
	
	# Tracking functionality
	
	if player.is_moving:
		removing = false
		trail_timer.paused = false
	else:
		if not removing and not trail_timer.paused:
			trail_timer.paused = true
			var wait := get_tree().create_timer(3.0)
			wait.timeout.connect(_on_pause_finished)
	
	# Mud wash off logic
	var main_root = get_tree().current_scene
	var tilemap_layer: TileMapLayer = main_root.get_node_or_null("Environment/Background Top")
	var map_pos: Vector2i = tilemap_layer.local_to_map(global_position)
	var tile_data: TileData = tilemap_layer.get_cell_tile_data(map_pos)
	if tile_data:
		is_in_water = tile_data.get_custom_data("water")
		if is_in_water:
			is_muddy = false
			await get_tree().create_timer(1.0).timeout

# Tracking
func _on_trail_node_visible() -> void:
	$TrackPoints.show()

func _on_trail_node_invisible() -> void:
	$TrackPoints.hide()

func _on_pause_finished() -> void:
	if player.is_moving:
		return
	trail_timer.paused = false
	removing = true

func update_trail():
	if !player.is_muddy:
		if player.is_moving:
			$TrackPoints.add_point(player.global_position)
			if $TrackPoints.points.size() == MAX_TRAIL_COUNT:
				$TrackPoints.remove_point(0)
		elif removing:
			if not $TrackPoints.points.is_empty():
				$TrackPoints.remove_point(0)
		else:
			removing = false
	else:
		print("ME MODDY!")


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
	
	#set_building(null)

# Multiplayer
func _enter_tree() -> void:
	$Key.hide()
	print("node name: ", name, " | authority: ", get_multiplayer_authority(), " | my id: ", multiplayer.get_unique_id(), " | is_authority: ", is_multiplayer_authority())
	set_multiplayer_authority(owner_peer_id)

func _physics_process(delta: float) -> void:
	@warning_ignore("unused_parameter")
	if not is_multiplayer_authority():
		global_position = global_position.lerp(net_position, 0.25)
		return
	var direction: Vector2 = GameInputEvents.movement_input()
	is_moving = direction != Vector2.ZERO
	is_running = Input.is_action_pressed("run")
	if direction != Vector2.ZERO:
		player_direction = direction

# Health
func set_health(value) -> void:
	#health = get_node("PlayerUI/ProgressBar").value #connect to ui
	health = clampi(value, 0.0, max_health)
	healthChanged.emit(health, max_health)
	if health <= 0:
		die()

func _on_hitbox_entered(area: Area2D) -> void:
	bear_damage = 10.0
	can_damage = true
	hb_entered = true
	
	print("Area entered: ", area.get_groups())
	if area.is_in_group("BearAttackArea"):
		if can_damage:
			state_machine.transition_to("Hurt")
			can_damage = false
			player.take_damage(bear_damage)
			await get_tree().create_timer(wait_time).timeout
			can_damage = true
	elif area.is_in_group("InteractableEnvironment"):
		current_interactable = area.get_parent()
	else:
		return

func _on_hitbox_exited(area: Area2D) -> void:
	if area.get_parent() == current_interactable:
		current_interactable = null

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
	return is_dead

# Interaction key (I) actions
func _input(event: InputEvent) -> void:
	pass
	#if event.is_action_pressed("ui_inventory"):
		#inventory_ui.visible = !inventory_ui.visible # Open/close each time "I" is pressed
		#get_tree().paused = !get_tree().paused

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
