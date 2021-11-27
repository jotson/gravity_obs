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
	# warning-ignore:return_value_discarded
	Twitch.connect("login_attempt", self, "twitch_login_attempt")
	
	# warning-ignore:return_value_discarded
	TwitchPS.connect("reward_redemption", self, "twitch_reward_redemption")
	
	# commands
	Twitch.add_command("battle", self, "cmd_start_battle", 0, 0, Twitch.PermissionFlag.STREAMER)
	Twitch.add_command("commands", self, "cmd_commands")
	Twitch.add_command("info", self, "cmd_info")
	Twitch.add_command("fod", self, "cmd_fod")
	Twitch.add_command("event", self, "cmd_event")
	Twitch.add_command("meaningoflife", self, "cmd_meaningoflife")


func _on_joinButton_pressed(_text = ""):
	if $login/channel.text:
		$login.hide()
		Helper.set_transparent(true)
		Twitch.join($login/channel.text)


func _on_channel_text_entered(new_text):
	_on_joinButton_pressed(new_text)


func cmd_start_battle(_cmd : CommandInfo):
	Battle.start_round()
	
	
func cmd_info(_cmd : CommandInfo):
	Twitch.chat("Hi, I'm working on Gravity Ace! It's a Godot Engine game and you can find out more at https://gravityace.com")
	

func cmd_fod(_cmd : CommandInfo):
	Twitch.chat("Check out https://flockofdogs.com by Max Clark")
	

func cmd_event(_cmd : CommandInfo):
	Twitch.chat("I am going to be at Ambitious Indies 3.0 in Long Beach on January 12th! More info coming soon!")
	

func cmd_meaningoflife(_cmd : CommandInfo):
	Twitch.chat("42")


func cmd_commands(_cmd : CommandInfo):
	var commands : PoolStringArray = [
		"!info for info about the game",
		"!fod for info about flockofdogs",
		"!event for info about Ambitious Indies 3.0",
		"!commands (you're looking at it)",
		"!meaningoflife"
	]
	
	var chat = "Commands: " + commands.join(" // ")
	print(chat)
	
	Twitch.chat(chat)


func twitch_reward_redemption(who : String, reward : String):
	print("%s redeemed %s" % [who, reward])
	

func twitch_login_attempt(success):
	if (success):
		OS.window_minimized = true
		
		TwitchPS.connect_to_twitch()
		

func twitch_chat(sender_data, command : String, full_message : String):
	var _username = sender_data.user
	
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

	# warning-ignore:return_value_discarded
	OS.shell_open(uri + "?" + qs)
