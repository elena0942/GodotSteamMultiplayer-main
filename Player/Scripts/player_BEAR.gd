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

var interactable = null
var _building: Node = null
var building: Node:
	set(value):
		set_building(value)
	get:
		return _building
var is_dead: bool


@onready var health: float = max_health
@onready var max_health: float = 500.0
@onready var _hitbox: CollisionShape2D = $DetectArea/Hitbox
@onready var inventory_ui = $PlayerUI/Inventory/InventoryUI
@onready var camera: Camera2D = $Camera2D
@onready var player_ui: Control = $PlayerUI

##### DICTIONARIES AND ARRAYS #####



##### FUNCTIONS ######

# Tracking

func tracking() -> void:
	pass

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

# Multiplayer
func _enter_tree() -> void:
	print("node name: ", name, " | authority: ", get_multiplayer_authority(), " | my id: ", multiplayer.get_unique_id(), " | is_authority: ", is_multiplayer_authority())
	set_multiplayer_authority(owner_peer_id)

func _physics_process(delta: float) -> void:
	# First check if we have authority over this player
	if not is_multiplayer_authority():
		global_position = global_position.lerp(net_position, 0.25)
		return
	var direction: Vector2 = GameInputEvents.movement_input()
	is_moving = direction != Vector2.ZERO
	if direction != Vector2.ZERO:
		player_direction = direction

# Health
func set_health(value) -> void:
	#health = get_node("PlayerUI/ProgressBar").value #connect to ui
	health = clampi(value, 0.0, max_health)
	healthChanged.emit(health, max_health)
	if health <= 0:
		die()

# Take damage
func take_damage(enemy_damage: int) -> void:
	health -= enemy_damage
	print("took ", enemy_damage, "damage. Health is now ", health)
	set_health(health)

# Death
func die() -> bool:
	print("player died") #death logic here
	_hitbox.set_deferred("disabled", true)
	
	is_dead = true
	return is_dead

# Interaction key (L click) actions
func _process(delta):
	if Input.is_action_just_pressed("interact"):
		print("pressedinteract")
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
