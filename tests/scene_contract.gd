extends SceneTree

## Interaction fixture: positions are deliberate test placements, not an autonomous
## traversal/playtest. Uses real colliders, target rays and input signal wiring.
const MAIN: PackedScene = preload("res://game/scenes/main.tscn")
var ward: Node3D
var actor: PlayerController
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("SCENE_FAIL: ", message)

func _run() -> void:
	ward = MAIN.instantiate() as Node3D
	root.add_child(ward)
	actor = ward.get_node("Player") as PlayerController
	actor.set_physics_process(false)
	ward.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await physics_frame
	await physics_frame

	# Out-of-range and nearby wall-occluded targets are distinct failure cases.
	await aim(Vector3(0, 0.02, 6.2), "FusePickup")
	expect(ward._target() == null, "cannot target distant supply")
	var supply: Node3D = ward.get_node("FusePickup") as Node3D
	var supply_position: Vector3 = supply.position
	supply.position = Vector3(2.6, 1.2, -2.8)
	await aim(Vector3(1.3, 0.02, -2.8), "FusePickup")
	expect(ward._target() == null, "cannot target nearby supply through wall")
	supply.position = supply_position
	# Nearby wall-occluded contact must not count as care support.
	var resident_position: Vector3 = ward.get_node("Guest").position
	ward.get_node("Guest").position = Vector3(2.7, 0, -2.8)
	actor.position = Vector3(1.3, 0.02, -2.8)
	await physics_frame
	expect(not ward._has_line_of_sight_to_guest(), "wall blocks care observation")
	ward.get_node("Guest").position = resident_position
	await physics_frame

	await act_at(Vector3(-4.4, 0.02, 4.3), "FusePickup", GameIds.Action.PICK_FUSE)
	var inventory: InventoryState = ward.state.inventories[GameIds.SERVER_ID]
	expect(inventory.has_item(GameIds.Item.FUSE), "fuse pickup signal changes inventory")
	await act_at(Vector3(-5.8, 0.02, 4.5), "LampPickup", GameIds.Action.PICK_LAMP)
	expect(inventory.has_item(GameIds.Item.LAMP), "lamp pickup signal changes inventory")
	await act_at(Vector3(-0.3, 0.02, 0), "Breaker", GameIds.Action.INSTALL_FUSE)
	expect(ward.state.power_on and ward.get_node("CorridorLight").visible, "power state enables actual light")
	await act_at(Vector3(5.2, 0.02, -4.1), "LampSocket", GameIds.Action.PLACE_LAMP)
	expect(ward.state.lamp_placed and ward.get_node("BedsideLight").visible, "placed lamp enables actual fixture")
	await act_at(Vector3(4.8, 0.02, -5.6), "Contact", GameIds.Action.GREET)
	expect(ward.state.care.introduced, "resident contact reachable")
	actor.promise_requested.emit()
	expect(ward.state.care.promise_active, "promise input wired to resident")
	ward.state.tick(30.0, false)
	ward._sync_view()
	expect(ward.state.care.phase == CareState.Phase.SEARCHING, "unanswered promise reaches escalation")
	expect(ward.get_node("Guest").phase == CareState.Phase.SEARCHING, "view receives actual care phase")
	await act_at(Vector3(4.1, 0.02, -5.65), "RadioSwitch", GameIds.Action.RADIO)
	ward.state.tick(0.1, false)
	ward._sync_view()
	expect(ward.state.care.phase == CareState.Phase.CALM, "working radio recovers warning")
	await act_at(Vector3(-5.2, 0.02, 5.4), "Finish", GameIds.Action.FINISH)
	expect(ward.state.completed, "actual scene interactions complete shift")

	var snapshot: Dictionary = ward.state.snapshot()
	actor.effects_requested.emit()
	expect(ward.state.snapshot() == snapshot, "effects toggle does not change gameplay")
	expect(ward.get_node("PostLight").visible, "staff post light remains on")
	ward.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("GUESTS_SCENE_OK checks=", checks)
		quit(0)
	else:
		quit(1)

func aim(position: Vector3, target_name: String) -> void:
	actor.global_position = position
	actor.camera.look_at((ward.get_node(target_name) as Node3D).global_position)
	await physics_frame
	await physics_frame

func act_at(position: Vector3, target_name: String, action: int) -> void:
	await aim(position, target_name)
	var target: InteractionPoint = ward._target() as InteractionPoint
	expect(target != null and target.action == action, "reachable target: " + target_name)
	if target != null:
		actor.interact_requested.emit()
