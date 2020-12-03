extends Control

var dialog_tree = null
var active_node = null
var pause setget set_pause

onready var DialogNode = preload("res://editor/dialog/dialognode.gd").new()


func _ready():
	var start = $HBoxContainer.rect_position + Vector2(0, 200)
	var end = $HBoxContainer.rect_position
	$HBoxContainer.rect_position = start
	$Tween.interpolate_property($HBoxContainer, 'modulate', Color(1,1,1,0), Color(1,1,1,1), 1.0, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.interpolate_property($HBoxContainer, 'rect_position', start, end, 0.5, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	$Tween.start()
	$AnimationPlayer.play('change-text')


func set_tree(json):
	dialog_tree = parse_json(json)


func say(starting_node = 'dialogroot'):
	$sfxTyping.stop()

	if not dialog_tree:
		return

	active_node = starting_node

	if not dialog_tree.connections:
		queue_free()
		return

	if not dialog_tree.nodes:
		queue_free()
		return

	# Find default starting node
	if active_node == 'dialogroot':
		for c in dialog_tree.connections:
			if c.from == 'dialogroot':
				active_node = c.to
				break

	if active_node == 'dialogroot':
		# First dialog node was not found
		# This could be because there is no node
		# or no connection from the dialogroot
		queue_free()
		return
		
	if not Game.is_edit_mode() and pause:
		get_tree().paused = true

	# Find the active node
	for n in dialog_tree.nodes:
		if n.name == active_node:
			var text : String  = n.text.replace("\r", "").replace("\n", " ").strip_edges()
			text = text.to_upper()
			
			var highlight_begin = "[wave amp=15 freq=9][color=#0095e9][b]"
			var highlight_end = "[/b][/color][/wave]"
			
			# Emphasis
			text = text.replace("[B]", "[color=#e43b44][b]")
			text = text.replace("[/B]", "[/b][/color]")

			# Wavy
			text = text.replace("[W]", highlight_begin)
			text = text.replace("[/W]", highlight_end)

			# Good!
			text = text.replace("[G]", "[tornado radius=2 freq=6][color=#63c74d][b]")
			text = text.replace("[/G]", "[/b][/color][/tornado]")

			# DANGER!
			text = text.replace("[D]", "[shake rate=6 level=6][color=#e43b44][b]")
			text = text.replace("[/D]", "[/b][/color][/shake]")

			# Fade
			text = text.replace("[F]", "[fade][b]")
			text = text.replace("[/F]", "[/b][/fade]")
			
			if Config.get('controls') == Config.CONTROLS_MODERN:
				if Game.USING_GAMEPAD:
					text = text.replace("@MOVE", highlight_begin + "Left Stick" + highlight_end)
					text = text.replace("@AIM", highlight_begin + "Right Stick" + highlight_end)
					text = text.replace("@FIRE", highlight_begin + "Right Trigger" + highlight_end)
					text = text.replace("@BEAM", highlight_begin + "Left Trigger" + highlight_end)
				else:
					text = text.replace("@MOVE", highlight_begin + "WASD or arrow keys" + highlight_end)
					text = text.replace("@AIM", highlight_begin + "Mouse" + highlight_end)
					text = text.replace("@FIRE", highlight_begin + "Left Mouse Button" + highlight_end)
					text = text.replace("@BEAM", highlight_begin + "Right Mouse Button" + highlight_end)
			else:
				if Game.USING_GAMEPAD:
					text = text.replace("@MOVE", highlight_begin + "Left Stick and A" + highlight_end)
					text = text.replace("@AIM", highlight_begin + "Left Stick" + highlight_end)
					text = text.replace("@FIRE", highlight_begin + "Right Trigger" + highlight_end)
					text = text.replace("@BEAM", highlight_begin + "Left Trigger" + highlight_end)
				else:
					text = text.replace("@MOVE", highlight_begin + "WASD or arrow keys" + highlight_end)
					text = text.replace("@AIM", highlight_begin + "A and D or arrow keys" + highlight_end)
					text = text.replace("@FIRE", highlight_begin + "SHIFT or ENTER" + highlight_end)
					text = text.replace("@BEAM", highlight_begin + "Z key" + highlight_end)
			set_text(text)
			set_portrait(n.portrait)
			set_response1(n.response1.strip_edges())
			set_response2(n.response2.strip_edges())
			set_response3(n.response3.strip_edges())
			break

	$sfxTyping.play()
	$autoAdvanceTimer.stop()
	$autoAdvanceTimer.start()


func set_pause(value):
	pause = value


func set_text(value):
	$AnimationPlayer.play('change-text')
	$HBoxContainer/Panel/text.percent_visible = 0
	$HBoxContainer/Panel/text.bbcode_enabled = true
	$HBoxContainer/Panel/text.bbcode_text = value
	$HBoxContainer/Panel/text.show()
	$HBoxContainer/ContinueButton.show()
	$responseContainer.hide()
	$responseContainer/response1.hide()
	$responseContainer/response2.hide()
	$responseContainer/response3.hide()


func set_portrait(value):
	for p in DialogNode.PORTRAITS:
		if p.id == value:
			$HBoxContainer/portrait.texture = p.portrait


func set_response1(value):
	$responseContainer/response1.text = value


func set_response2(value):
	$responseContainer/response2.text = value


func set_response3(value):
	$responseContainer/response3.text = value


func _input(_event):
	if not is_visible_in_tree():
		return

	if Input.is_action_just_pressed("interact"):
		get_tree().set_input_as_handled()
		goto_next_dialog()


func _on_response1_pressed():
	goto_next_dialog(1)


func _on_response2_pressed():
	goto_next_dialog(2)


func _on_response3_pressed():
	goto_next_dialog(3)


func goto_next_dialog(choice : int = 0):
	# When a dialog with responses was shown, if the
	# player advances the dialog, that same input event
	# would be used again on the response buttons. The
	# effect is that a single click would advance to the
	# next node and click one of the responses which would
	# advance to the next node after that. I think that
	# was happening because the click and the buttons being
	# shown all happens in the same frame. This timer
	# prevents the click event from being used twice by
	# adding a short delay before each node is shown
	yield(get_tree().create_timer(0.1), 'timeout')
	
	$sfxTyping.stop()

	if not dialog_tree.connections:
		return

	if not dialog_tree.nodes:
		return

	# Find next node
	var found = false
	var responses = []
	for c in dialog_tree.connections:
		if c.from == active_node:
			if choice == 0:
				responses.append(c.to)
				found = true
			if choice == 1 and c.from_port == 0 or choice == 2 and c.from_port == 1 or choice == 3 and c.from_port == 2:
				say(c.to)
				found = true
				break
			
	if found and choice == 0:
		if responses.size() == 1 and $responseContainer/response1.text == "":
			say(responses[0])
		else:
			$HBoxContainer/Panel/text.hide()
			$HBoxContainer/ContinueButton.hide()
			$responseContainer.show()
			
			if responses.size() == 1:
				$responseContainer/response1.show()
				$responseContainer/response2.hide()
				$responseContainer/response3.hide()
			if responses.size() == 2:
				$responseContainer/response1.show()
				$responseContainer/response2.show()
				$responseContainer/response3.hide()
			if responses.size() == 3:
				$responseContainer/response1.show()
				$responseContainer/response2.show()
				$responseContainer/response3.show()
				
			if not Game.is_edit_mode():
				$responseContainer/response1.grab_focus()

	if not found:
		# This must be the end of the tree
		# Wait just a split second so that the
		# Button presses don't trigger shooting
		$closeTimer.start()


func _on_autoAdvanceTimer_timeout():
	if Game.is_edit_mode():
		return

	if not pause:
		goto_next_dialog()


func _on_closeTimer_timeout():
	if not $"/root/game/pauseLayer/pause".visible:
		get_tree().paused = false
	queue_free()
