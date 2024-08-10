extends Control

var record_effect: AudioEffectRecord
var spectrum_effect: AudioEffectSpectrumAnalyzerInstance
var recording: AudioStreamWAV

const VU_COUNT: int = 30
const FREQ_MAX: float = 18000
const MIN_DB: float = 100

const MIN_SIZE: float = 100
const WIDTH: float = 12
const HEIGHT: float = 300


func _ready() -> void:
	var idx = AudioServer.get_bus_index("Record")
	record_effect = AudioServer.get_bus_effect(idx, 0) as AudioEffectRecord
	record_effect.set_recording_active(true)

	spectrum_effect = AudioServer.get_bus_effect_instance(idx, 1) as AudioEffectSpectrumAnalyzerInstance
	
	
#func _process(_delta: float) -> void:
	#queue_redraw()
	

func _draw():
	var prev_hz = 0
	
	# Straight line
	for i in range(0, VU_COUNT):
		var hz = i * FREQ_MAX / VU_COUNT;
		var magnitude: float = spectrum_effect.get_magnitude_for_frequency_range(prev_hz, hz).length()
		var energy = clamp((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		var height = -energy * HEIGHT
		var c = Color.WHITE
		draw_line(Vector2((WIDTH+3) * i, size.y), Vector2((WIDTH+3) * i, size.y-MIN_SIZE+height), c, WIDTH)
		prev_hz = hz

	# Circular
	#for i in range(0, VU_COUNT):
		#var angle = PI / VU_COUNT * i
		#var hz = i * FREQ_MAX / VU_COUNT;
		#var magnitude: float = spectrum_effect.get_magnitude_for_frequency_range(prev_hz, hz).length()
		#var energy = clamp((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		#var height = energy * HEIGHT
		#draw_set_transform(Vector2(size.x/2.0, size.y/2.0), angle)
		#draw_line(Vector2(0, MIN_SIZE), Vector2(0, MIN_SIZE+height), Color.WHITE, WIDTH, true)
		#draw_set_transform(Vector2(size.x/2.0, size.y/2.0), -angle)
		#draw_line(Vector2(0, MIN_SIZE), Vector2(0, MIN_SIZE+height), Color.WHITE, WIDTH, true)
		#prev_hz = hz
