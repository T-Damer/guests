extends SceneTree

var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		printerr("FAIL: ", description)

func _run() -> void:
	_test_inventory()
	_test_care()
	_test_shift()
	_test_transport_defaults()
	if failures.is_empty():
		print("GUESTS_RULES_OK checks=", checks)
		quit(0)
	else:
		printerr("GUESTS_RULES_FAILED count=", failures.size())
		quit(1)

func _test_inventory() -> void:
	var inventory: InventoryState = InventoryState.new(1)
	expect(inventory.add(GameIds.Item.LAMP), "first item fits")
	expect(not inventory.add(GameIds.Item.LAMP), "no duplicate item")
	expect(not inventory.add(GameIds.Item.FUSE), "capacity enforced")
	expect(not inventory.remove(GameIds.Item.FUSE), "cannot remove missing item")
	expect(inventory.remove(GameIds.Item.LAMP), "item can be removed")
	expect(not inventory.add(-1), "unknown item rejected")

func _test_care() -> void:
	var definition: GuestProfile = load(GameIds.PROFILE_PATH) as GuestProfile
	expect(definition != null and definition.is_valid(), "resource definition loads")
	var care: CareState = CareState.new(definition)
	expect(not care.promise_return(), "cannot promise without contact")
	care.tick(100.0, false, false)
	expect(care.phase == CareState.Phase.CALM, "no unseen countdown before introduction")
	care.greet()
	care.tick(definition.grace_seconds, false, false)
	expect(care.phase == CareState.Phase.WARNING, "warning before searching")
	care.tick(definition.warning_seconds, false, false)
	expect(care.phase == CareState.Phase.SEARCHING, "unresolved warning escalates")
	care.tick(0.1, true, false)
	expect(care.phase == CareState.Phase.CALM, "contact recovers without combat")
	expect(care.promise_return(), "introduced resident accepts promise")
	care.tick(definition.promise_seconds - 0.5, false, false)
	expect(care.phase == CareState.Phase.WAITING, "promise creates work window")
	care.tick(0.5, false, false)
	expect(care.phase == CareState.Phase.WARNING, "expired promise warns")
	care.tick(100.0, false, true)
	expect(care.phase == CareState.Phase.CALM, "working radio supports absence")
	care.tick(-10.0, false, false)
	care.tick(NAN, false, false)
	expect(care.absence_seconds == 0.0, "invalid elapsed time ignored")
	var other: CareState = CareState.new(definition)
	expect(not other.introduced, "instances do not share mutable state")
	var whole: CareState = CareState.new(definition)
	var stepped: CareState = CareState.new(definition)
	whole.greet()
	stepped.greet()
	whole.promise_return()
	stepped.promise_return()
	whole.tick(30.0, false, false)
	for index: int in range(60):
		stepped.tick(0.5, false, false)
	expect(whole.phase == stepped.phase and is_equal_approx(whole.absence_seconds, stepped.absence_seconds), "time partition invariance")

func _test_shift() -> void:
	var shift: ShiftState = ShiftState.new()
	expect(shift.apply(GameIds.Action.FINISH) == GameIds.Outcome.NOT_READY, "cannot finish empty shift")
	expect(shift.apply(GameIds.Action.RADIO) == GameIds.Outcome.NEED_POWER, "radio needs power")
	expect(shift.apply(GameIds.Action.INSTALL_FUSE) == GameIds.Outcome.NEED_ITEM, "fuse required")
	expect(shift.register_actor(2), "second actor registered")
	expect(shift.apply(GameIds.Action.PICK_LAMP) == GameIds.Outcome.OK, "first pickup wins")
	expect(shift.apply(GameIds.Action.PICK_LAMP, 2) == GameIds.Outcome.UNAVAILABLE, "concurrent pickup cannot duplicate")
	expect(shift.apply(GameIds.Action.PLACE_LAMP, 2) == GameIds.Outcome.NEED_ITEM, "actor cannot spend another inventory")
	expect(shift.apply(GameIds.Action.PLACE_LAMP) == GameIds.Outcome.OK, "lamp placed")
	shift.apply(GameIds.Action.PICK_FUSE, 2)
	shift.remove_actor(2)
	expect(shift.fuse_available, "disconnect returns critical item to supply")
	shift.apply(GameIds.Action.PICK_FUSE)
	shift.apply(GameIds.Action.INSTALL_FUSE)
	shift.apply(GameIds.Action.GREET)
	shift.apply(GameIds.Action.RADIO)
	shift.tick(30.0, false)
	expect(shift.apply(GameIds.Action.FINISH) == GameIds.Outcome.DONE, "full care loop finishes")
	expect(shift.apply(GameIds.Action.RADIO) == GameIds.Outcome.UNAVAILABLE, "completed shift immutable")
	expect(shift.apply(999) == GameIds.Outcome.INVALID, "unknown action rejected")
	var packed: Dictionary = shift.snapshot()
	packed["inventories"][GameIds.SERVER_ID].append(999)
	var original: InventoryState = shift.inventories[GameIds.SERVER_ID]
	expect(not original.items.has(999), "snapshot cannot mutate authority")
	var capacity: ShiftState = ShiftState.new()
	capacity.register_actor(2)
	capacity.register_actor(3)
	capacity.register_actor(4)
	expect(not capacity.register_actor(5), "four actor limit")

func _test_transport_defaults() -> void:
	var session: NetSession = NetSession.new()
	root.add_child(session)
	session.submit(GameIds.Action.PICK_LAMP)
	expect(session.state.lamp_available, "missing reach validator fails closed")
	session.validate_reach = func(_actor: int, _action: int) -> bool: return false
	session.submit(GameIds.Action.PICK_LAMP)
	expect(session.state.lamp_available, "unreachable target rejected")
	var losses: Array[bool] = []
	session.connection_failed.connect(func() -> void: losses.append(true))
	session._on_connection_lost()
	expect(losses.size() == 1, "unexpected disconnect is reported")
	losses.clear()
	session.close()
	session._on_connection_lost()
	expect(losses.is_empty(), "intentional local close is not connection failure")
	session.free()
