extends Node3D

const INTERACTION_RANGE: float = 2.5
const CONTACT_RANGE: float = 2.8
const QUERY_MASK: int = 3
const MESSAGE_SECONDS: float = 5.0
const CAPTURE_SETTLE_SECONDS: float = 1.0
const PHASE_LABELS: Dictionary = {
	CareState.Phase.CALM: "Контакт устойчив",
	CareState.Phase.WAITING: "Ждёт обещанного возвращения",
	CareState.Phase.WARNING: "Зовёт вас. Не оставляйте её без ответа",
	CareState.Phase.SEARCHING: "Ищет вас. Вернитесь или включите радио",
}

var state: ShiftState = ShiftState.new(load(GameIds.PROFILE_PATH) as GuestProfile)
var _message: String = "Наряд: восстановить питание, принести лампу, установить контакт и включить радио."
var _message_remaining: float = MESSAGE_SECONDS
var _previous_phase: CareState.Phase = CareState.Phase.CALM

@onready var player: PlayerController = $Player
@onready var guest: GuestView = $Guest
@onready var audio: AmbientAudio = $AmbientAudio
@onready var effects: CanvasLayer = $Retro
@onready var status: Label = $HUD/Status
@onready var prompt: Label = $HUD/Prompt
@onready var inventory_label: Label = $HUD/Inventory
@onready var message_label: Label = $HUD/Message

func _ready() -> void:
	player.interact_requested.connect(_interact)
	player.promise_requested.connect(_promise)
	player.effects_requested.connect(func() -> void: effects.visible = not effects.visible)
	player.mute_requested.connect(func() -> void: AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0)))
	_sync_view()
	for argument: String in OS.get_cmdline_user_args():
		if OS.has_feature("debug") and argument.begins_with("--capture-dir="):
			_capture(argument.trim_prefix("--capture-dir="))

func _physics_process(delta: float) -> void:
	# Prototype contact is deliberately distance + unobstructed sight, not proximity through a wall.
	var close: bool = player.global_position.distance_to(guest.global_position) <= CONTACT_RANGE
	var contact: bool = close and _has_line_of_sight_to_guest()
	state.tick(delta, contact)
	_sync_view()
	_message_remaining = maxf(0.0, _message_remaining - delta)
	var target: InteractionPoint = _target()
	prompt.text = "E — " + target.prompt() if target != null else ""
	if target != null and target.action == GameIds.Action.GREET:
		prompt.text += "    R — обещать вернуться"
	message_label.text = _message if _message_remaining > 0.0 or state.completed else ""

func _has_line_of_sight_to_guest() -> bool:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(player.camera.global_position, guest.global_position + Vector3.UP, 1)
	query.exclude = [player.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _target() -> InteractionPoint:
	var origin: Vector3 = player.camera.global_position
	var end: Vector3 = origin - player.camera.global_basis.z * INTERACTION_RANGE
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end, QUERY_MASK)
	query.collide_with_areas = true
	query.exclude = [player.get_rid()]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	return hit["collider"] as InteractionPoint

func _interact() -> void:
	var target: InteractionPoint = _target()
	if target != null:
		_apply(target.action)

func _promise() -> void:
	var target: InteractionPoint = _target()
	if target != null and target.action == GameIds.Action.GREET:
		_apply(GameIds.Action.PROMISE)

func _apply(action: int) -> void:
	var result: GameIds.Outcome = state.apply(action)
	_message = String(GameIds.OUTCOME_LABELS[result])
	if action == GameIds.Action.PROMISE and result == GameIds.Outcome.OK:
		_message = "Я вернусь. — Хорошо. Я подожду."
	elif action == GameIds.Action.GREET and result == GameIds.Outcome.OK:
		_message = "Вы из новой смены? Пожалуйста, включите радио. Здесь слишком тихо."
	_message_remaining = MESSAGE_SECONDS
	_sync_view()

func _sync_view() -> void:
	$CorridorLight.visible = state.power_on
	$BedsideLight.visible = state.lamp_placed
	$PortableLamp.visible = state.lamp_available
	$FuseMesh.visible = state.fuse_available
	$LampPickup.collision_layer = 2 if state.lamp_available else 0
	$FusePickup.collision_layer = 2 if state.fuse_available else 0
	guest.phase = state.care.phase
	audio.set_radio(state.radio_on and state.power_on)
	if state.care.phase != _previous_phase and state.care.phase in [CareState.Phase.WARNING, CareState.Phase.SEARCHING]:
		audio.play_warning()
		_message = String(PHASE_LABELS[state.care.phase])
		_message_remaining = MESSAGE_SECONDS
	_previous_phase = state.care.phase
	status.text = "ГОСТИ / СМЕНА 01\nПитание: %s   Лампа: %s   Радио: %s\n027 — %s" % ["да" if state.power_on else "нет", "да" if state.lamp_placed else "нет", "да" if state.radio_on else "нет", PHASE_LABELS[state.care.phase]]
	var inventory: InventoryState = state.inventories[GameIds.SERVER_ID]
	var slots: PackedStringArray = []
	for item: int in inventory.items:
		slots.append("[" + String(GameIds.ITEM_LABELS[item]) + "]")
	while slots.size() < GameIds.INVENTORY_SLOTS:
		slots.append("[ — ]")
	inventory_label.text = "ИНВЕНТАРЬ  " + "  ".join(slots)

func _capture(directory: String) -> void:
	# Local debug-only visual fixtures, never a network command or release backdoor.
	var absolute: String = ProjectSettings.globalize_path(directory)
	DirAccess.make_dir_recursive_absolute(absolute)
	await get_tree().create_timer(CAPTURE_SETTLE_SECONDS).timeout
	await RenderingServer.frame_post_draw
	var first: Error = get_viewport().get_texture().get_image().save_png(absolute.path_join("start.png"))
	player.set_physics_process(false)
	player.global_position = Vector3(3.3, 0.0, -4.6)
	player.camera.look_at(guest.global_position + Vector3(0.0, 1.65, 0.0))
	state.care.greet()
	state.care.tick(60.0, false, false)
	set_physics_process(false)
	_sync_view()
	await get_tree().create_timer(CAPTURE_SETTLE_SECONDS).timeout
	await RenderingServer.frame_post_draw
	var second: Error = get_viewport().get_texture().get_image().save_png(absolute.path_join("guest-warning.png"))
	state.apply(GameIds.Action.PICK_FUSE)
	state.apply(GameIds.Action.INSTALL_FUSE)
	state.apply(GameIds.Action.PICK_LAMP)
	state.apply(GameIds.Action.PLACE_LAMP)
	state.apply(GameIds.Action.GREET)
	effects.visible = false
	_sync_view()
	await get_tree().create_timer(CAPTURE_SETTLE_SECONDS).timeout
	await RenderingServer.frame_post_draw
	var third: Error = get_viewport().get_texture().get_image().save_png(absolute.path_join("resident-effects-off.png"))
	if first != OK or second != OK or third != OK:
		printerr("GUESTS_CAPTURE_FAILED")
		get_tree().quit(1)
		return
	print("GUESTS_CAPTURE_OK")
	get_tree().quit(0)
