extends Button

func _on_Button_pressed():
	$"../Gift".chat($"../LineEdit".text)
	$"../LineEdit".text = ""
