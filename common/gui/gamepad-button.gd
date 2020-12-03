tool
extends CenterContainer

enum BUTTON { A, B, X, Y, PAD }

export(NodePath) var shadows = null
export(String) var text = "OK" setget set_text
export(BUTTON) var button = BUTTON.A setget set_button
export(bool) var disabled = false setget set_disabled


func _ready():
	gamepad_ui()


func _input(_event):
	gamepad_ui()

	if is_visible_in_tree():
		if button == BUTTON.A and Input.is_action_just_pressed("ui_accept"):
			$sfxClick.play()
		if button == BUTTON.B and Input.is_action_just_pressed("ui_cancel"):
			$sfxClick.play()
		if button == BUTTON.X and Input.is_action_just_pressed("interact"):
			$sfxClick.play()


func set_text(value):
	text = value
	if is_inside_tree():
		$HBoxContainer/Label.text = text
		
		
func set_button(value):
	button = value
	if not is_inside_tree():
		return

	var icon = $HBoxContainer/TextureRect/Sprite
	if button == BUTTON.A:
		icon.frame = 0
		if disabled: icon.frame = 1
	if button == BUTTON.B:
		icon.frame = 2
		if disabled: icon.frame = 3
	if button == BUTTON.X:
		icon.frame = 4
		if disabled: icon.frame = 5
	if button == BUTTON.Y:
		icon.frame = 6
		if disabled: icon.frame = 7
	if button == BUTTON.PAD:
		icon.frame = 8
		if disabled: icon.frame = 9
		
	if disabled:
		$HBoxContainer/Label.modulate = Color("3a4466")
	else:
		$HBoxContainer/Label.modulate = Color("c0cbdc")


func set_disabled(value):
	disabled = value
	if not is_inside_tree():
		return
	self.set_button(button)
	
	
func gamepad_ui():
	set_text(text)
	set_button(button)
	
	if Engine.editor_hint:
		show()
		if shadows and get_node(shadows):
			get_node(shadows).hide()
		return
	
	if Game.USING_GAMEPAD:
		show()
		if shadows and get_node(shadows):
			get_node(shadows).hide()
	else:
		hide()
		if shadows and get_node(shadows):
			get_node(shadows).show()
