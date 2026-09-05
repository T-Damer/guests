class_name CareState
extends RefCounted

## Renderer-independent, deterministic care rules. SEARCHING is a warning-state
## contract in the bootstrap; locomotion/capture are deliberately not implemented.
enum Phase { CALM, WAITING, WARNING, SEARCHING }

var profile: GuestProfile
var introduced: bool = false
var phase: Phase = Phase.CALM
var absence_seconds: float = 0.0
var promise_remaining: float = 0.0
var promise_active: bool = false

func _init(definition: GuestProfile = null) -> void:
	profile = definition if definition != null else GuestProfile.new()
	assert(profile.is_valid(), "Invalid guest definition")

func greet() -> void:
	introduced = true
	absence_seconds = 0.0
	promise_remaining = 0.0
	promise_active = false
	phase = Phase.CALM

func promise_return() -> bool:
	if not introduced:
		return false
	promise_active = true
	promise_remaining = profile.promise_seconds
	absence_seconds = 0.0
	phase = Phase.WAITING
	return true

func tick(delta: float, caregiver_present: bool, radio_working: bool) -> void:
	if not is_finite(delta) or delta < 0.0 or not introduced:
		return
	if caregiver_present:
		absence_seconds = 0.0
		phase = Phase.CALM
		if promise_active:
			promise_remaining = profile.promise_seconds
		return
	if radio_working:
		absence_seconds = 0.0
		phase = Phase.CALM
		return
	var elapsed: float = delta
	if promise_active:
		var previous_remaining: float = promise_remaining
		promise_remaining = maxf(0.0, promise_remaining - elapsed)
		if promise_remaining > 0.0:
			phase = Phase.WAITING
			return
		elapsed = maxf(0.0, elapsed - previous_remaining)
		promise_active = false
		absence_seconds = profile.grace_seconds
	absence_seconds += elapsed
	if absence_seconds < profile.grace_seconds:
		phase = Phase.CALM
	elif absence_seconds < profile.grace_seconds + profile.warning_seconds:
		phase = Phase.WARNING
	else:
		phase = Phase.SEARCHING
