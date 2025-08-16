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
const SOUNDBOARD_PATH = "user://soundboard"

signal midi

var sound_map = {}

func _ready():
	load_sound_configuration()
	OS.open_midi_inputs()


func load_sound_configuration():
	Soundboard.hide()
	
	sound_map.clear()
	sound_map["midi"] = {}
	
	if not FileAccess.file_exists(SOUNDBOARD_JSON):
		return
		
	for b in %Buttons.get_children():
		b.queue_free()

	# Load all sounds starting at MIDI note 60
	var note = 60
	var files = DirAccess.get_files_at(SOUNDBOARD_PATH)
	files.sort()
	for f in files:
		var sound = f.replace(".ogg", "")
		sound_map["midi"]["note_%d" % note] = sound
		note += 1
		
		var b = Button.new()
		b.text = sound
		b.pressed.connect(
			func():
				play(sound, true)
				Helper.enable_mouse_passthrough()
		)
		b.add_theme_font_size_override("font_size", 24)
		%Buttons.add_child(b)
	
	# Load soundboard.json overriding the defaults above
	var f = FileAccess.open(SOUNDBOARD_JSON, FileAccess.READ)
	if f == null:
		return
		
	var json = f.get_as_text()
	var test_json_conv = JSON.new()
	test_json_conv.parse(json)
	var midi_data = test_json_conv.get_data()
	sound_map.midi.merge(midi_data)
	f.close()


func get_sound_file(sound: String) -> String:
	var sound_file = ""
	var path = SOUNDBOARD_PATH.path_join(sound) + ".ogg"
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
	#prints("Play sound", sound)
	
	var stream: AudioStream
	
	var sound_file = get_sound_file(sound)
	if sound_file:
		stream = AudioStreamOggVorbis.load_from_file(sound_file)
	
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
	load_sound_configuration()

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
	load_sound_configuration()

	#prints("Ctr:", event.controller_number, "Val:", event.controller_value, "Not:", event.pitch, "Vel:", event.velocity)
	var key = "note_%d" % pitch
	if sound_map["midi"].has(key):
		play(sound_map["midi"][key], true)
		midi.emit(pitch)
		#prints("Play midi", pitch)
