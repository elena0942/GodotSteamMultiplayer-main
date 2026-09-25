@tool
extends Node2D

@export var item_name = ""
@export var item_texture: Texture
@export var player_in_range = false

var scene_path: String = "res://Scenes/UI/inventory_item.tscn"

@onready var icon_sprite = $Sprite2D
@onready var prompt = $detect_area

func _ready():
	if not Engine.is_editor_hint():
		icon_sprite.texture =  item_texture
		prompt.visible = false

func _process(delta): 
	if Engine.is_editor_hint():
		icon_sprite.texture =  item_texture

	if player_in_range and Input.is_action_just_pressed("interact"):
		print("Picked up item")
		pickup_item()


func pickup_item():
	var item = {
		"name": item_name,
		"amount": 1,
		"texture": item_texture,
		"scene_path": scene_path,
	}
	#rudimentary logic for different items
	
	print("Picking up: ", item["name"])
	if Global.player_node:
		Global.add_item(item, false)
		self.queue_free()

#player is near enough to an item to pick up
func _on_area_2d_body_entered(body) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		if player_in_range:
			prompt.visible = true
			prompt.play("keyprompt")

#player no longer near item, cannot pickup
func _on_area_2d_body_exited(body) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		if not player_in_range:
			prompt.visible = false
			prompt.stop()

func set_item_data(data):
	item_name = data["name"]
	item_texture = data["texture"]

func initiate_items(type, name, effect, texture):
	item_name = name
	item_texture = texture
