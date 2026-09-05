extends Node

const TIMEOUT_SECONDS: float = 10.0
var session: NetSession
var server: bool = false
var stage: int = 0
var saw_remote: bool = false

func _ready() -> void:
	var port: int = GameIds.DEFAULT_PORT
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--role=server":
			server = true
		elif argument.begins_with("--port="):
			port = int(argument.trim_prefix("--port="))
	session = NetSession.new()
	session.name = "Session"
	add_child(session)
	get_tree().create_timer(TIMEOUT_SECONDS).timeout.connect(func() -> void: _fail("probe timeout"))
	if server:
		session.validate_reach = func(_actor: int, _action: int) -> bool: return true
		if session.host(port) != OK:
			_fail("host failed")
			return
		multiplayer.peer_connected.connect(func(_peer: int) -> void: saw_remote = true)
		multiplayer.peer_disconnected.connect(_on_departure)
		print("GUESTS_NET_READY")
	else:
		session.snapshot_received.connect(_on_snapshot)
		session.outcome_received.connect(_on_outcome)
		session.connection_failed.connect(func() -> void: _fail("connection failed"))
		if session.join("127.0.0.1", port) != OK:
			_fail("join failed")

func _on_snapshot(value: Dictionary) -> void:
	if stage == 0:
		stage = 1
		session.submit(GameIds.Action.PICK_LAMP)
	elif stage == 2:
		var inventory: Array = value["inventories"][multiplayer.get_unique_id()]
		if not inventory.has(GameIds.Item.LAMP):
			_fail("accepted item absent from authoritative snapshot")
			return
		stage = 3
		session.submit(GameIds.Action.PICK_LAMP)

func _on_outcome(outcome: int) -> void:
	match stage:
		1:
			if outcome != GameIds.Outcome.OK:
				_fail("first pickup was rejected")
				return
			stage = 2
		3:
			if outcome != GameIds.Outcome.UNAVAILABLE:
				_fail("duplicate pickup was accepted")
				return
			stage = 4
			session.submit(999)
		4:
			if outcome != GameIds.Outcome.DENIED:
				_fail("unknown wire action not denied")
				return
			stage = 5
			print("GUESTS_NET_CLIENT_OK")
			session.close()
			get_tree().quit(0)

func _on_departure(_peer: int) -> void:
	if not saw_remote or not session.state.lamp_available:
		_fail("disconnected holder did not return lamp")
		return
	print("GUESTS_NET_HOST_OK")
	get_tree().quit(0)

func _fail(message: String) -> void:
	printerr("GUESTS_NET_FAILED: ", message)
	get_tree().quit(1)
