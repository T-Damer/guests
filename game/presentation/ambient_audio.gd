class_name AmbientAudio
extends Node3D

## Original procedural placeholder audio; no downloaded recordings or voices.
const SAMPLE_RATE: int = 22050
const HUM_FREQUENCY: float = 100.0
const WARNING_FREQUENCY: float = 440.0
const LOOP_SECONDS: float = 1.0
const WARNING_SECONDS: float = 0.18
const HUM_VOLUME_DB: float = -32.0
const RADIO_VOLUME_DB: float = -30.0
const WARNING_VOLUME_DB: float = -18.0

var hum: AudioStreamPlayer3D
var radio: AudioStreamPlayer3D
var warning: AudioStreamPlayer3D

func _ready() -> void:
	hum = _player(_tone(HUM_FREQUENCY, LOOP_SECONDS, true), HUM_VOLUME_DB)
	radio = _player(_tone(220.0, LOOP_SECONDS, true), RADIO_VOLUME_DB)
	warning = _player(_tone(WARNING_FREQUENCY, WARNING_SECONDS, false), WARNING_VOLUME_DB)
	hum.position = Vector3(0.0, 2.7, 0.0)
	radio.position = Vector3(4.4, 1.0, -7.0)
	warning.position = Vector3(6.3, 1.5, -5.8)
	hum.play()

func set_radio(active: bool) -> void:
	if active and not radio.playing:
		radio.play()
	elif not active:
		radio.stop()

func play_warning() -> void:
	warning.play()

func _player(stream: AudioStreamWAV, volume: float) -> AudioStreamPlayer3D:
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume
	player.max_distance = 18.0
	add_child(player)
	return player

func _tone(frequency: float, seconds: float, loop: bool) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * seconds)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	for index: int in range(count):
		var time: float = float(index) / SAMPLE_RATE
		var envelope: float = 1.0 if loop else sin(PI * float(index) / count)
		var sample: float = sin(TAU * frequency * time) * envelope * 0.35
		data.encode_s16(index * 2, int(sample * 32767.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream

func _exit_tree() -> void:
	for player: AudioStreamPlayer3D in [hum, radio, warning]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
