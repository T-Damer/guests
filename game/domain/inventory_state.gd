class_name InventoryState
extends RefCounted

var capacity: int
var items: Array[int] = []

func _init(slot_count: int = GameIds.INVENTORY_SLOTS) -> void:
	capacity = maxi(0, slot_count)

func add(item: int) -> bool:
	if not GameIds.Item.values().has(item) or items.has(item) or items.size() >= capacity:
		return false
	items.append(item)
	return true

func remove(item: int) -> bool:
	if not items.has(item):
		return false
	items.erase(item)
	return true

func has_item(item: int) -> bool:
	return items.has(item)
