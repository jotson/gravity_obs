extends Node

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

signal midi

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


func get_sound_file(sound: String) -> String:
	var SOUND_PATH = "user://soundboard"
	var sound_file = null
	if sound_map["sounds"].has(sound):
		sound_file = SOUND_PATH.plus_file(sound_map["sounds"][sound])
	else:
		var f = File.new()
		var path = SOUND_PATH.plus_file(sound) + ".ogg"
		if f.file_exists(path):
			sound_file = path
	return sound_file
		

# Load an ogg file into a stream
func load_sound_file(sound: String) -> AudioStream:
	sound = sound.replace(" ", "")
	sound = sound.replace("!", "")
	sound = sound.replace("?", "")
	sound = sound.replace("'", "")
	sound = sound.replace(",", "")
	sound = sound.replace(".", "")
	sound = sound.to_lower()

	load_sound_configuration()

	var stream = AudioStreamOGGVorbis.new()
	
	var sound_file = get_sound_file(sound)
	if sound_file:
		var f = File.new()
		var err = f.open(sound_file, File.READ)
		if err != OK:
			return stream
		var bytes = f.get_buffer(f.get_len())
		stream.data = bytes
		f.close()
		
	return stream


# Queue sounds and play them one after another
var sound_queue = []
func play_queue(sound = null) -> void:
	if sound:
		sound_queue.append(sound)
	
	if sound_queue.size() == 0:
		return
		
	if not $QueuedPlayer.playing:
		sound = sound_queue.pop_front()
		$QueuedPlayer.stream = load_sound_file(sound)
		$QueuedPlayer.play()
	
		
func play(sound: String, single = false) -> void:
	var player: AudioStreamPlayer
	if single:
		# Play non-overlapping
		player = $SinglePlayer
	else:
		# Play overlapping sounds
		player = AudioStreamPlayer.new()
		add_child(player)
		# warning-ignore:return_value_discarded
		player.connect("finished", player, "queue_free")
	player.stream = load_sound_file(sound)
	player.play()


func _input(event):
	if event is InputEventMIDI:
		event = event as InputEventMIDI
		
		if event.velocity > 0:
			play_midi(event.pitch)


func play_midi(pitch: int):
	#prints("Ctr:", event.controller_number, "Val:", event.controller_value, "Not:", event.pitch, "Vel:", event.velocity)
	var key = "note_%d" % pitch
	if sound_map["midi"].has(key):
		play(sound_map["midi"][key], true)
		emit_signal("midi", pitch)
