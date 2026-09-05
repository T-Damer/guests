class_name NetSession
extends Node

## Transport/authority seam, not a finished player-replication system.
## Both peers must mount this at the same path. Missing reach validation DENIES.
signal snapshot_received(value: Dictionary)
signal outcome_received(value: int)
signal connection_failed

var state: ShiftState = ShiftState.new()
var validate_reach: Callable
var _windows: Dictionary = {}
var _counts: Dictionary = {}

func host(port: int = GameIds.DEFAULT_PORT) -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port, GameIds.MAX_PLAYERS - 1)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	return OK

func join(address: String, port: int = GameIds.DEFAULT_PORT) -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	multiplayer.connection_failed.connect(func() -> void: connection_failed.emit())
	multiplayer.server_disconnected.connect(func() -> void: connection_failed.emit())
	return OK

func close() -> void:
	multiplayer.multiplayer_peer.close()

func submit(action: int) -> void:
	if multiplayer.is_server():
		_process_request(GameIds.SERVER_ID, action)
	elif multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_request_action.rpc_id(GameIds.SERVER_ID, action)

func _on_peer_connected(peer: int) -> void:
	if not state.register_actor(peer):
		multiplayer.multiplayer_peer.disconnect_peer(peer)
		return
	_receive_snapshot.rpc_id(peer, state.snapshot())

func _on_peer_disconnected(peer: int) -> void:
	state.remove_actor(peer)
	_windows.erase(peer)
	_counts.erase(peer)
	_publish()

@rpc("any_peer", "call_remote", "reliable")
func _request_action(action: int) -> void:
	if multiplayer.is_server():
		_process_request(multiplayer.get_remote_sender_id(), action)

func _process_request(actor: int, action: int) -> void:
	if not state.inventories.has(actor):
		return
	var now: int = Time.get_ticks_msec()
	if not _windows.has(actor) or now - int(_windows[actor]) >= GameIds.REQUEST_WINDOW_MS:
		_windows[actor] = now
		_counts[actor] = 0
	_counts[actor] = int(_counts[actor]) + 1
	var outcome: int = GameIds.Outcome.DENIED
	if int(_counts[actor]) <= GameIds.REQUESTS_PER_WINDOW and GameIds.Action.values().has(action) and validate_reach.is_valid() and bool(validate_reach.call(actor, action)):
		outcome = state.apply(action, actor)
	if actor == GameIds.SERVER_ID:
		_receive_outcome(outcome)
	else:
		_receive_outcome.rpc_id(actor, outcome)
	_publish()

func _publish() -> void:
	var value: Dictionary = state.snapshot()
	snapshot_received.emit(value)
	if multiplayer.get_peers().size() > 0:
		_receive_snapshot.rpc(value)

@rpc("authority", "call_remote", "reliable")
func _receive_snapshot(value: Dictionary) -> void:
	snapshot_received.emit(value)

@rpc("authority", "call_remote", "reliable")
func _receive_outcome(value: int) -> void:
	outcome_received.emit(value)
