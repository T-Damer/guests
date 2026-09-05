class_name GuestProfile
extends Resource

## Definitions are shared resources; never store mutable resident state here.
@export var resident_id: StringName = &"027"
@export var display_name: String = "Ждущая"
@export_range(0.1, 120.0) var grace_seconds: float = 6.0
@export_range(0.1, 120.0) var warning_seconds: float = 5.0
@export_range(0.1, 120.0) var promise_seconds: float = 18.0

func is_valid() -> bool:
	return not resident_id.is_empty() and is_finite(grace_seconds) and is_finite(warning_seconds) and is_finite(promise_seconds) and grace_seconds > 0.0 and warning_seconds > 0.0 and promise_seconds > 0.0
