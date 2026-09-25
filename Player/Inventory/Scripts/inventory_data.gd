class_name InventoryData
extends Resource #was resource

signal inventory_updated

var slots: Array[InventorySlot] = []

func add_item(new_item: ItemData) -> bool:
	if new_item.is_stackable: #check if new item can be stacked
		for slot in slots:
			if slot.item == new_item:
				slot.amount += 1
				inventory_updated.emit()
				return true
	for slot in slots: #find first empty slot, if stacking unavailable
		if slot.item == null:
			slot.item = new_item
			slot.quantity = 1
			inventory_updated.emit()
			return true
	return false #inventory is full
