extends Control

const s_applause = preload("res://soundboard/sfx/applause.wav")
const s_hmm = preload("res://soundboard/sfx/interesting.wav")
const s_laughter = preload("res://soundboard/sfx/laughter.wav")
const s_ohno = preload("res://soundboard/sfx/ohno.wav")
const s_spec50 = preload("res://soundboard/sfx/NASAspec50.ogg")
const s_apolloproblem = preload("res://soundboard/sfx/NASAapolloproblem.ogg")
const s_goahead = preload("res://soundboard/sfx/NASAgoahead.ogg")
const s_fuelcells = preload("res://soundboard/sfx/NASAfuelcells.ogg")
const s_eaglehaslanded = preload("res://soundboard/sfx/NASAeaglehaslanded.ogg")
const s_welcome = preload("res://soundboard/sfx/welcome.wav")
const s_airhorn = preload("res://soundboard/sfx/airhorn.wav")
const s_pewpew = preload("res://soundboard/sfx/pewpew.wav")
const s_pssthey = preload("res://soundboard/sfx/pssthey.wav")

var sound_map = {
	# bottom row green
	36: "welcome",
	37: "airhorn",
	38: "applause",
	39: "eaglehaslanded",
	# top row green
	40: "pewpew",
	41: "fuelcells",
	42: "spec50",
	43: "apolloproblem",
	# bottom row red
	44: null,
	45: null,
	46: null,
	47: null,
	# top row red
	48: null,
	49: null,
	50: null,
	51: null,
}

func _ready():
	OS.open_midi_inputs()


func play(sound: String) -> void:
	sound = sound.replace(" ", "")
	sound = sound.replace("!", "")
	sound = sound.replace(",", "")
	sound = sound.replace(".", "")
	sound = sound.to_lower()
	
	if get("s_" + sound):
		var stream = get("s_" + sound)
		$AudioStreamPlayer.stream = stream
		$AudioStreamPlayer.play()


func _input(event):
	if event is InputEventMIDI:
		event = event as InputEventMIDI
		prints("Ctr:", event.controller_number, "Val:", event.controller_value, "Not:", event.pitch, "Vel:", event.velocity)
		
		if event.velocity > 0 and sound_map.has(event.pitch):
			play(sound_map[event.pitch])
