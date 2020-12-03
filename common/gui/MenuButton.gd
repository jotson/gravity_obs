extends Button

func _ready():
	pass


func _on_MenuButton_focus_entered():
	$Tween.interpolate_property(self, "anchor_left", 0, -0.1, 0.25, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.interpolate_property(self, "anchor_right", 0, 0.1, 0.25, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.start()

	$sfxHover.play()


func _on_MenuButton_focus_exited():
	$Tween.interpolate_property(self, "anchor_left", -0.1, 0, 0.25, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.interpolate_property(self, "anchor_right", 0.1, 0, 0.25, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.start()


func _on_MenuButton_mouse_entered():
	grab_focus()


func _on_MenuButton_mouse_exited():
	grab_focus()


func _on_MenuButton_pressed():
	$sfxClick.play()


func _on_MenuButton_visibility_changed():
	if not is_visible_in_tree():
		return

	if not visible:
		return

	$appearTimer.start()


func _on_appearTimer_timeout():
	pass
