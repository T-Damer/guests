class_name GuestView
extends Node3D

## Deliberately simple original proxy. Only visual children deform.
const STRETCH_RATE: float = 2.0
const CALM_STRETCH: float = 0.0
const WARNING_STRETCH: float = 0.35
const SEARCH_STRETCH: float = 1.0
const HEAD_LIFT: float = 0.88
const NECK_STRETCH: float = 4.0
const HEAD_BASE_HEIGHT: float = 1.64
const NECK_BASE_HEIGHT: float = 1.39

var phase: CareState.Phase = CareState.Phase.CALM
var _stretch: float = 0.0
@onready var head: Node3D = $Head
@onready var neck: MeshInstance3D = $Neck

func _process(delta: float) -> void:
	var target: float = CALM_STRETCH
	if phase == CareState.Phase.WARNING:
		target = WARNING_STRETCH
	elif phase == CareState.Phase.SEARCHING:
		target = SEARCH_STRETCH
	_stretch = move_toward(_stretch, target, STRETCH_RATE * delta)
	head.position.y = HEAD_BASE_HEIGHT + HEAD_LIFT * _stretch
	head.rotation.z = _stretch * 0.12
	neck.scale.y = 1.0 + NECK_STRETCH * _stretch
	neck.position.y = NECK_BASE_HEIGHT + HEAD_LIFT * _stretch * 0.5
