extends Control

# soundboard.json:
#
# {
#	"sounds": {
#		"applause": "soundboard/applause.ogg",
#		"hmm": "soundboard/interesting.ogg",
#	},
#	"midi": {
#		"note_36": "applause"
#	}
# }

const SOUNDBOARD_JSON = "user://soundboard.json"

var sound_map = {}

func _ready():
	load_sound_configuration()
	OS.open_midi_inputs()


func load_sound_configuration():
	sound_map.clear()
	
	var f = File.new()
	if not f.file_exists(SOUNDBOARD_JSON):
		return
		
	# Load soundboard.json
	if f.open(SOUNDBOARD_JSON, File.READ) != OK:
		return
		
	var json = f.get_as_text()
	sound_map = parse_json(json)
	f.close()


func sound_exists(sound: String) -> bool:
	return sound_map["sounds"].has(sound)
		

# Load an ogg file into a stream
func load_sound_file(sound: String) -> AudioStream:
	load_sound_configuration()

	var stream = AudioStreamOGGVorbis.new()
	
	if sound_exists(sound):
		var f = File.new()
		var sound_file = sound_map["sounds"][sound]
		var path = "user://soundboard".plus_file(sound_file)
		var err = f.open(path, File.READ)
		if err != OK:
			return stream
		var bytes = f.get_buffer(f.get_len())
		stream.data = bytes
		f.close()
		
	return stream


func play(sound: String) -> void:
	sound = sound.replace(" ", "")
	sound = sound.replace("!", "")
	sound = sound.replace(",", "")
	sound = sound.replace(".", "")
	sound = sound.to_lower()
	
	$AudioStreamPlayer.stream = load_sound_file(sound)
	$AudioStreamPlayer.play()


func _input(event):
	if event is InputEventMIDI:
		event = event as InputEventMIDI
		
		if event.velocity > 0:
			play_midi(event.pitch)


func play_midi(pitch: int):
	#prints("Ctr:", event.controller_number, "Val:", event.controller_value, "Not:", event.pitch, "Vel:", event.velocity)
	var key = "note_%d" % pitch
	if sound_map["midi"].has(key):
		play(sound_map["midi"][key])
