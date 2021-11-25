extends Control


func _ready():
	Helper.set_transparent(false)
	$console.hide()
	$login/channel.grab_focus()

	var channel = Helper.get_saved_channel()
	if channel:
		$login/channel.text = channel

	# warning-ignore:return_value_discarded
	Twitch.connect("chat_message", self, "twitch_chat")
	# warning-ignore:return_value_discarded
	Twitch.connect("twitch_disconnected", self, "twitch_disconnect")
	
	# commands
	Twitch.add_command("battle", self, "cmd_start_battle", 0, 0, Twitch.PermissionFlag.STREAMER)
	Twitch.add_command("commands", self, "cmd_commands")
	Twitch.add_command("info", self, "cmd_info")


func _on_joinButton_pressed(_text = ""):
	if $login/channel.text:
		$login.hide()
		Helper.set_transparent(true)
		Twitch.join($login/channel.text)


func _on_channel_text_entered(new_text):
	_on_joinButton_pressed(new_text)


func cmd_start_battle(cmd : CommandInfo):
	Battle.start_round()
	Twitch.chat("The battle is starting! Chat to join!")
	
func cmd_commands(cmd : CommandInfo):
	pass

func cmd_info(cmd : CommandInfo):
	pass
	

func twitch_chat(sender_data, command : String, full_message : String):
	var username = sender_data.user
	
	command = command.to_lower()
	
	var hearts = Helper.get_count(full_message, "<3")
	if hearts >= 0:
		for _n in range(hearts):
			var o = load("res://heart/heart.tscn").instance()
			o.position = Helper.random_position()
			Helper.add_child(o)
		
	var smiles = Helper.get_count(full_message, ":-)")
	smiles += Helper.get_count(full_message, ":)")
	smiles += Helper.get_count(full_message, ":D")
	if smiles > 3:
		smiles = 3
	if smiles >= 0:
		for _n in range(smiles):
			var o = load("res://smiley/smiley.tscn").instance()
			o.position = Helper.random_position()
			Helper.add_child(o)


func twitch_disconnect():
	$login.show()
	Helper.set_transparent(false)


func _on_authButton_pressed():
	var uri = "https://id.twitch.tv/oauth2/authorize"
	var client = HTTPClient.new()
	var fields = {
		"client_id": ProjectSettings.get("twitch/client_id"),
		"redirect_uri": "http://localhost:8080",
		"response_type": "token",
		"force_verify": "true",
		"scope": "chat:read chat:edit channel:read:redemptions"
	}
	var qs = client.query_string_from_dict(fields)

	OS.shell_open(uri + "?" + qs)
