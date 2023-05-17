extends TextureButton

@export var note: int


func _ready():
	pass


func _on_SoundButton_pressed():
	Soundboard.play_midi(note)


func _input(event):
	if event is InputEventMIDI:
		event = event as InputEventMIDI
		
		if event.velocity > 0 and event.pitch == note:
			set_pressed_no_signal(true)
		else:
			set_pressed_no_signal(false)
