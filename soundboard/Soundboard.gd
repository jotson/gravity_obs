extends Control

func _ready():
	pass


func play(sound : String) -> void:
	sound = sound.trim_prefix(" ")
	sound = sound.trim_suffix(" ")

	var audio = find_node("sound_" + sound)
	if audio:
		audio.play()
