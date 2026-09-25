extends PanelContainer

@onready var item_amount: Label = $Contents/ItemAmount
@onready var item_icon: Sprite2D = $Contents/ItemIcon

func update_slot_display(slot_data: InventorySlot) -> void:
	if slot_data.item != null:
		item_icon.texture = slot_data.item.icon
		item_amount.text = str(slot_data.amount) if slot_data.amount >= 1 else ""
	else:
		item_icon.texture = null
		item_amount.text = ""
