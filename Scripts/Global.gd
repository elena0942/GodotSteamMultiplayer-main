#### WORKING - SPAWNPOINTS V1 ####
extends Node

var spawn_name: String = "game_start_spawn"
var player_pos : Vector2
var player_node: Node = null
var inventory = []

signal inventory_updated

var spawnable_items = [
	{"type": "consumable", "name": "Berry", "effect": "_", "texture": preload("res://Crops/crops/Singular Crops/1px/2.png")},
	{"type": "consumable", "name": "Orange", "effect": "_", "texture": preload("res://Crops/crops/Singular Crops/1px/13.png")}
]

@onready var inventory_slot_scene = preload("res://player/Inventory/Scenes/inventory_slot.tscn")

var hotbar_size = 10
var hotbar_inventory = []


func _ready():
	inventory.resize(20)
	hotbar_inventory.resize(hotbar_size)

func add_item(item, to_hotbar = false):
	var added_to_hotbar = false
	if to_hotbar:
		added_to_hotbar = add_hotbar_item(item)
		inventory_updated.emit()
	if not added_to_hotbar:
		for i in range(inventory.size()):
			if inventory[i] != null and inventory[i]["name"] == item["name"] and inventory[i]["type"] == item["type"] and inventory[i]["effect"] == item["effect"]:
				inventory[i]["quantity"] += item["quantity"]
				inventory_updated.emit()
				print("Item added", inventory)
				return true
			elif inventory[i] == null:
				inventory[i] = item
				inventory_updated.emit()
				print("Item added", inventory)
				return true
		return false

func remove_item(item_name, item_type, item_effect):
	for i in range(inventory.size()):
		if inventory[i] != null and inventory[i]["name"] == item_name and inventory[i]["type"] == item_type and inventory[i]["effect"] == item_effect:
			inventory[i]["quantity"] -= 1
			if inventory[i]["quantity"] <= 0:
				inventory[i] = null
			inventory_updated.emit()
			return true
	return false

func increase_inventory_size(extra_slots):
	inventory.resize(inventory.size() + extra_slots)
	inventory_updated.emit()

func set_player_reference(player):
	player_node = player

func adjust_drop_position(position):
	var radius = 100
	var nearby_items = get_tree().get_nodes_in_group("item")
	for item in nearby_items:
		if item.global_position.distance_to(position) < radius:
			var random_offset = Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
			position += random_offset
			break
	return position

func drop_item(item_data, drop_position):
	var item_scene = load(item_data["scene_path"])
	var item_instance = item_scene.instantiate()
	item_instance.set_item_data(item_data)
	drop_position = adjust_drop_position(drop_position)
	item_instance.global_position = drop_position
	get_tree().current_scene.add_child(item_instance)

func add_hotbar_item(item):
	for i in range(hotbar_size):
		if hotbar_inventory[i] == null:
			hotbar_inventory[i] = item
			return true
	return false

func remove_hotbar_item(item_name, item_type, item_effect):
	for i in range(hotbar_inventory.size()):
		if hotbar_inventory[i] != null and hotbar_inventory[i]["name"] == item_name and hotbar_inventory[i]["type"] == item_type and hotbar_inventory[i]["effect"] == item_effect:
			print("Removed hotbar item")
			hotbar_inventory[i] = null
			inventory_updated.emit()
			return true
	return false

func unassign_hotbar_item(item_name, item_type, item_effect):
	for i in range(hotbar_inventory.size()):
		if hotbar_inventory[i] != null and hotbar_inventory[i]["name"] == item_name and hotbar_inventory[i]["type"] == item_type and hotbar_inventory[i]["effect"] == item_effect:
			print("Unassigned hotbar item")
			hotbar_inventory[i] = null
			inventory_updated.emit()
			return true
	return false

func is_item_assigned_to_hotbar(item_to_check):
	return item_to_check in hotbar_inventory
