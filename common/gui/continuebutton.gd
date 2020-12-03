extends Control

signal pressed

enum ACCEPT { a, interact, both }
export(ACCEPT) var ACCEPT_KEYS = ACCEPT.both


func _ready():
	pass
	

func check_input():	
	if Input.is_action_just_pressed("ui_cancel"):
		emit_signal("pressed")
		
	if Input.is_action_just_pressed("interact") and (ACCEPT_KEYS == ACCEPT.both or ACCEPT_KEYS == ACCEPT.interact):
		emit_signal("pressed")

	if Input.is_action_just_pressed("ui_accept") and (ACCEPT_KEYS == ACCEPT.both or ACCEPT_KEYS == ACCEPT.a):
		emit_signal("pressed")


# In game mode, all inputs are accepted so that players can click
# anywhere on the screen to advance the dialog... but that doesn't
# work in edit mode so _gui_input() is used as well.
func _input(_event):
	if Game.is_edit_mode():
		return
	check_input()


# In the dialog editor, other inputs shouldn't affect the dialog preview.
# So _gui_input() is used to only respond to events directly on the continue
# button itself.
func _gui_input(_event):
	if not Game.is_edit_mode():
		return
	check_input()	
