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

var sound_map = {}

func _ready():
	load_sound_configuration()
	OS.open_midi_inputs()


func load_sound_configuration():
	sound_map.clear()
	
	if not FileAccess.file_exists(SOUNDBOARD_JSON):
		return
		
	# Load soundboard.json
	var f = FileAccess.open(SOUNDBOARD_JSON, FileAccess.READ)
	if f == null:
		return
		
	var json = f.get_as_text()
	var test_json_conv = JSON.new()
	test_json_conv.parse(json)
	sound_map = test_json_conv.get_data()
	f.close()


func get_sound_file(sound: String) -> String:
	var SOUND_PATH = "user://soundboard"
	var sound_file = null
	if sound_map["sounds"].has(sound):
		sound_file = SOUND_PATH.path_join(sound_map["sounds"][sound])
	else:
		var path = SOUND_PATH.path_join(sound) + ".ogg"
		if FileAccess.file_exists(path):
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

	var stream = AudioStreamOggVorbis.new()
	
	var sound_file = get_sound_file(sound)
	if sound_file:
		var f = FileAccess.open(sound_file, FileAccess.READ)
		if f == null:
			return stream
		var bytes = f.get_buffer(f.get_length())
		var packets = OggPacketSequence.new()
		# BROKEN in 4.0.3rc2
		# https://github.com/godotengine/godot/issues/61091
		packets.packet_data = bytes
		stream.packet_sequence = packets
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
		player.connect("finished", Callable(player, "queue_free"))
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
