class_name PlayerController
extends CharacterBody3D

signal interact_requested
signal promise_requested
signal effects_requested
signal mute_requested

const WALK_SPEED: float = 2.8
const GRAVITY: float = 9.8
const MOUSE_SENSITIVITY: float = 0.0025
const PITCH_LIMIT: float = 1.4
const ACTION_LEFT: StringName = &"walk_left"
const ACTION_RIGHT: StringName = &"walk_right"
const ACTION_FORWARD: StringName = &"walk_forward"
const ACTION_BACK: StringName = &"walk_back"
const BINDINGS: Dictionary = {
	ACTION_LEFT: KEY_A, ACTION_RIGHT: KEY_D,
	ACTION_FORWARD: KEY_W, ACTION_BACK: KEY_S,
}

@onready var camera: Camera3D = $Head/Camera3D

func _ready() -> void:
	for action: StringName in BINDINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var key: InputEventKey = InputEventKey.new()
			key.physical_keycode = BINDINGS[action]
			InputMap.action_add_event(action, key)
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		rotate_y(-motion.relative.x * MOUSE_SENSITIVITY)
		camera.rotation.x = clampf(camera.rotation.x - motion.relative.y * MOUSE_SENSITIVITY, -PITCH_LIMIT, PITCH_LIMIT)
	if event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event as InputEventKey
		match key.physical_keycode:
			KEY_E:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					interact_requested.emit()
			KEY_R:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					promise_requested.emit()
			KEY_F8: effects_requested.emit()
			KEY_F9: mute_requested.emit()
			KEY_F6: get_tree().reload_current_scene()
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var movement: Vector2 = Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		movement = Input.get_vector(ACTION_LEFT, ACTION_RIGHT, ACTION_FORWARD, ACTION_BACK)
	var direction: Vector3 = transform.basis * Vector3(movement.x, 0.0, movement.y)
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	move_and_slide()
