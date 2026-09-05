class_name ShiftState
extends RefCounted

var care: CareState
var power_on: bool = false
var lamp_placed: bool = false
var radio_on: bool = false
var completed: bool = false
var lamp_available: bool = true
var fuse_available: bool = true
var revision: int = 0
var inventories: Dictionary = {}

func _init(definition: GuestProfile = null) -> void:
	care = CareState.new(definition)
	register_actor(GameIds.SERVER_ID)

func register_actor(actor: int) -> bool:
	if actor <= 0 or inventories.has(actor) or inventories.size() >= GameIds.MAX_PLAYERS:
		return false
	inventories[actor] = InventoryState.new()
	return true

func remove_actor(actor: int) -> void:
	if not inventories.has(actor):
		return
	var inventory: InventoryState = inventories[actor]
	if inventory.has_item(GameIds.Item.LAMP):
		lamp_available = true
	if inventory.has_item(GameIds.Item.FUSE):
		fuse_available = true
	inventories.erase(actor)
	revision += 1

func apply(action: int, actor: int = GameIds.SERVER_ID) -> GameIds.Outcome:
	if not GameIds.Action.values().has(action) or not inventories.has(actor):
		return GameIds.Outcome.INVALID
	if completed:
		return GameIds.Outcome.UNAVAILABLE
	var inventory: InventoryState = inventories[actor]
	match action:
		GameIds.Action.PICK_LAMP:
			if not lamp_available:
				return GameIds.Outcome.UNAVAILABLE
			if not inventory.add(GameIds.Item.LAMP):
				return GameIds.Outcome.FULL
			lamp_available = false
		GameIds.Action.PICK_FUSE:
			if not fuse_available:
				return GameIds.Outcome.UNAVAILABLE
			if not inventory.add(GameIds.Item.FUSE):
				return GameIds.Outcome.FULL
			fuse_available = false
		GameIds.Action.INSTALL_FUSE:
			if power_on:
				return GameIds.Outcome.UNAVAILABLE
			if not inventory.remove(GameIds.Item.FUSE):
				return GameIds.Outcome.NEED_ITEM
			power_on = true
		GameIds.Action.PLACE_LAMP:
			if lamp_placed:
				return GameIds.Outcome.UNAVAILABLE
			if not inventory.remove(GameIds.Item.LAMP):
				return GameIds.Outcome.NEED_ITEM
			lamp_placed = true
		GameIds.Action.RADIO:
			if not power_on:
				return GameIds.Outcome.NEED_POWER
			radio_on = not radio_on
		GameIds.Action.GREET:
			care.greet()
		GameIds.Action.PROMISE:
			if not care.promise_return():
				return GameIds.Outcome.NEED_CONTACT
		GameIds.Action.FINISH:
			if not (power_on and lamp_placed and radio_on and care.introduced and care.phase == CareState.Phase.CALM):
				return GameIds.Outcome.NOT_READY
			completed = true
			revision += 1
			return GameIds.Outcome.DONE
	revision += 1
	return GameIds.Outcome.OK

func tick(delta: float, caregiver_present: bool) -> void:
	if completed:
		return
	var previous_phase: CareState.Phase = care.phase
	care.tick(delta, caregiver_present, radio_on and power_on)
	if previous_phase != care.phase:
		revision += 1

func snapshot() -> Dictionary:
	var packed_inventories: Dictionary = {}
	for actor: int in inventories:
		var inventory: InventoryState = inventories[actor]
		packed_inventories[actor] = inventory.items.duplicate()
	return {
		"revision": revision, "phase": int(care.phase), "introduced": care.introduced,
		"power_on": power_on, "lamp_placed": lamp_placed, "radio_on": radio_on,
		"completed": completed, "lamp_available": lamp_available,
		"fuse_available": fuse_available, "inventories": packed_inventories,
	}
