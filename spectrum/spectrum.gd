extends Control

var record_effect: AudioEffectRecord
var spectrum_effect: AudioEffectSpectrumAnalyzerInstance
var recording: AudioStreamWAV

const VU_COUNT: int = 64
const FREQ_MIN: float = 2000
const FREQ_MAX: float = 4000
const MIN_DB: float = 100


func _ready() -> void:
	var idx = AudioServer.get_bus_index("Record")
	spectrum_effect = AudioServer.get_bus_effect_instance(idx, 0) as AudioEffectSpectrumAnalyzerInstance
	
	
func _process(_delta: float) -> void:
	queue_redraw()
	

func _draw():
	var prev_hz = FREQ_MIN
	
	var WIDTH = size.x/(VU_COUNT*2)
	var HEIGHT = size.y
	
	# Straight line
	for i in range(0, VU_COUNT + 1):
		var hz = FREQ_MIN + i * (FREQ_MAX-FREQ_MIN) / VU_COUNT;
		var mag_vec = spectrum_effect.get_magnitude_for_frequency_range(prev_hz, hz, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE)
		var magnitude: float = mag_vec.x
		var db = linear_to_db(magnitude) + 40
		if db < -30:
			continue
		var energy = 1.0-abs(db)/30
		var height = -energy * HEIGHT
		var c = Color.WHITE
		draw_line(Vector2(WIDTH * i, size.y), Vector2(WIDTH * i, size.y+height), c, WIDTH-2)
		draw_line(Vector2(size.x - WIDTH * i, size.y), Vector2(size.x - WIDTH * i, size.y+height), c, WIDTH-2)
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
