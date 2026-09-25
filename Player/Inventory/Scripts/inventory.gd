extends Control

@export var inventory_data: InventoryData
@export var ui_slot_prefab: PackedScene
@onready var grid_container: GridContainer = $InventoryUI/PanelContainer/VBoxContainer/GridContainer

func _ready() -> void:
	inventory_data.inventory_updated.connect(populate_grid)
	populate_grid()

func populate_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	
	for slot in inventory_data.slots:
		var visual_slot = ui_slot_prefab.instantiate()
		grid_container.add_child(visual_slot)
#		visual_slot.update_slot_display(slot)
