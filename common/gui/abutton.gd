extends Control

signal pressed


func _ready():
	if Game.USING_GAMEPAD:
		$A.show()
		$OK.hide()
	else:
		$A.hide()
		$OK.show()
		
	# warning-ignore:return_value_discarded
	$A.connect("pressed", self, "pressed")
	# warning-ignore:return_value_discarded
	$OK.connect("pressed", self, "pressed")
	

func pressed():
	emit_signal("pressed")


func grab_focus():
	if Game.USING_GAMEPAD:
		$A.grab_focus()
	else:
		$OK.grab_focus()
	
