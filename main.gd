extends Control

var commands : Dictionary

var last_api_request = Time.get_ticks_msec()
var profile_pics = {}
var profile_pic_queue = []
var MAX_CHATTERS = 50
var lastChannel = ""

const AstronautChatter = preload("res://chatter/Astronaut.tscn")
const AstronautContainer = preload("res://chatter/AstronautContainer.tscn")
const MarbleChatter = preload("res://chatter/Marble.tscn")
const MarbleContainer = preload("res://chatter/MarbleContainer.tscn")
@onready var Chatter = MarbleChatter
@onready var ChatterContainer = MarbleContainer.instantiate()


func _ready():
	Helper.set_transparent(false)
	$console.hide()
	$Gamepad.hide()
	$login/channel.grab_focus()

	add_child(ChatterContainer)
	
	var channel = Helper.get_saved_channel()
	if channel:
		$login/channel.text = channel
		
	if Soundboard.connect("midi", self.midi) != OK:
		print_debug("Signal not connected")
	if Twitch.connect("chat_message", Callable(self, "twitch_chat")) != OK:
		print_debug("Signal not connected")
	if Twitch.connect("unhandled_message", self.unhandled_message) != OK:
		print_debug("Signal not connected")
	if Twitch.connect("twitch_disconnected", Callable(self, "twitch_disconnect")) != OK:
		print_debug("Signal not connected")
	if Twitch.connect("login_attempt", Callable(self, "twitch_login_attempt")) != OK:
		print_debug("Signal not connected")
	if Twitch.connect("got_channel_info", Callable(self, "twitch_got_channel_info")) != OK:
		print_debug("Signal not connected")

	if TwitchPS.connect("reward_redemption", Callable(self, "twitch_reward_redemption")) != OK:
		print_debug("Signal not connected")
		
	load_commands()


func _input(_event):
	if Input.is_action_just_pressed("toggle_console"):
		if $console.visible:
			$console.hide()
		else:
			$console.show()
			
	if Input.is_action_just_pressed("toggle_gamepad"):
		if $Gamepad.visible:
			$Gamepad.hide()
			$console.text = "Gamepad off\n"
		else:
			$Gamepad.show()
			$console.text = "Gamepad on\n"
			
	if Input.is_action_just_pressed("toggle_heads"):
		if ChatterContainer.visible:
			ChatterContainer.hide()
			$console.text = "Heads off\n"
		else:
			ChatterContainer.show()
			$console.text = "Heads on\n"
			

func load_commands():
	commands.clear()
	Twitch.commands.clear()
	
	var f = FileAccess.open("user://commands.json", FileAccess.READ)
	if f == null:
		return
	var test_json_conv = JSON.new()
	test_json_conv.parse(f.get_as_text())
	var command_data : Array = test_json_conv.get_data()
	f.close()
	
	for c in command_data:
		commands[c.command] = c
		
		var perm = Twitch.PermissionFlag.EVERYONE
		if c.has("streamer") and c.streamer:
			perm = Twitch.PermissionFlag.STREAMER
			
		if c.has("action") and c.action == "battle":
			Twitch.add_command(c.command, cmd_battle, 0, 0, perm)
	
		if c.has("action") and c.action == "reload_commands":
			Twitch.add_command(c.command, cmd_reload_commands, 0, 0, perm)
	
		if c.has("action") and c.action == "commands":
			Twitch.add_command(c.command, cmd_commands, 0, 0, perm)

		if c.has("action") and c.action == "shoutout":
			Twitch.add_command(c.command, cmd_shoutout, 1, 0, perm)
	
		if c.has("action") and c.action == "chat":
			Twitch.add_command(c.command, cmd_chat, 0, 0, perm)

		if c.has("action") and c.action == "addtocredits":
			Twitch.add_command(c.command, cmd_addtocredits, 0, 0, perm)
			
		if c.has("action") and c.action == "greeting":
			Twitch.add_command(c.command, cmd_greeting, 0, 0, perm)
			
		if c.has("aliases"):
			for alias in c.aliases:
				Twitch.add_alias(c.command, alias)
				commands[alias] = {
					"alias": c.command
				}


func cmd_shoutout(_cmd : CommandInfo, username):
	load_commands()
	Twitch.chat("Go check out https://twitch.tv/%s because they are awesome!" % username[0])


func cmd_commands(_cmd : CommandInfo):
	load_commands()
	var response = "Commmand list:"
	for key in commands.keys():
		var c = commands[key]
		if c.has("streamer") && c.streamer == true:
			continue
		if c.has("alias"):
			continue
		response += " !%s" % [c.command]
		
	Twitch.chat(response)


func cmd_reload_commands(_cmd : CommandInfo):
	load_commands()
	

func cmd_battle(_cmd : CommandInfo):
	load_commands()
	Battle.start_round()
	
	
func cmd_chat(_cmd : CommandInfo):
	load_commands()
	var chat = ""
	
	if commands[_cmd.command].has("text"):
		chat = commands[_cmd.command].text
	if commands[_cmd.command].has("alias"):
		var alias = commands[_cmd.command].alias
		chat = commands[alias].text
		
	Twitch.chat(chat)


func cmd_greeting(_cmd : CommandInfo):
	load_commands()
	var username = _cmd.sender_data.user
	var sound = "greeting_" + username
	Soundboard.play_queue(sound)


func cmd_addtocredits(_cmd : CommandInfo):
	load_commands()
	var filename = "user://twitch-credits.txt"
	var f = FileAccess.open(filename, FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_line(_cmd.sender_data.user)
	f.close()
	

func _on_joinButton_pressed(_text = ""):
	$login/AutoLoginTimer.stop()
	var thisChannel = $login/channel.text
	if thisChannel:
		$login.hide()
		$SoundButtonConfig.hide()
		Helper.set_transparent(true)
		Twitch.join($login/channel.text)
		
		#profile_pics.clear()
		#profile_pic_queue.clear()
		
		if thisChannel != lastChannel:
			# Only clear chatters if NOT reconnecting to same channel
			for c in get_tree().get_nodes_in_group("chatter"):
				c.queue_free()
		
		lastChannel = thisChannel


func _on_channel_text_entered(new_text):
	_on_joinButton_pressed(new_text)


func twitch_reward_redemption(who : String, reward : String):
	var notify = true
	
	print("%s redeemed %s" % [who, reward])
	if reward.to_lower() == "this is fine":
		var fire = preload("res://flames/flames.tscn").instantiate()
		Helper.add_child(fire)
		
	if reward.begins_with("Play sound: "):
		notify = false
		var sound = reward.trim_prefix("Play sound: ")
		Soundboard.play_queue(sound)
	
	if notify:
		@warning_ignore("shadowed_variable_base_class")
		var notification = preload("res://reward/reward.tscn").instantiate()
		notification.who = who
		notification.reward = reward
		Helper.add_child(notification)
	

func twitch_login_attempt(success):
	if (success):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
		OBS.connect_to_obs()


func twitch_got_channel_info():
	TwitchPS.connect_to_twitch()


func twitch_chat(sender_data, command : String, full_message : String):
	var username = sender_data.user
	
	Soundboard.play("chat")
	
	command = command.to_lower()
	
	var message = full_message.split(" ")
	message.remove_at(0)
	message.remove_at(0)
	message.remove_at(0)
	message = " ".join(message)
	message = message.substr(1)
	
	var hearts = Helper.get_count(full_message, "<3")
	if hearts >= 0:
		for _n in range(hearts):
			var o = load("res://heart/heart.tscn").instantiate()
			o.position = Helper.random_position()
			Helper.add_child(o)
		
	var smiles = Helper.get_count(full_message, ":-)")
	smiles += Helper.get_count(full_message, ":)")
	smiles += Helper.get_count(full_message, ":D")
	if smiles > 3:
		smiles = 3
	if smiles >= 0:
		for _n in range(smiles):
			var o = load("res://smiley/smiley.tscn").instantiate()
			o.position = Helper.random_position()
			Helper.add_child(o)

	add_head(username, message)
	
	
func add_head(username, message):
	if not profile_pics.has(username) and not profile_pic_queue.has(username):
		if profile_pics.size() > MAX_CHATTERS:
			for _j in range(profile_pics.size() - MAX_CHATTERS):
				var i = randi() % MAX_CHATTERS
				var keys = profile_pics.keys()
				var key = keys[i]
				var c = profile_pics[key]
				if c["ready"]:
					c["sprite"].queue_free()
					profile_pics.erase(key)
					print("killed %s" % key)
			
		profile_pics[username] = {
			"url": null,
			"sprite": null,
			"ready": false
		}
		var first = false
		if profile_pics.size() == 1:
			first = true
		var chatter = Chatter.instantiate()
		profile_pics[username]["sprite"] = chatter
		chatter.add_head(null, username, first)
		ChatterContainer.add_child(chatter)
		chatter.say(message)
		
		profile_pic_queue.append(username)
	
	if profile_pic_queue.size() and Time.get_ticks_msec() > last_api_request + 500:
		get_profile_pic(profile_pic_queue)
		
	if profile_pics.has(username):
		profile_pics[username]["sprite"].say(message)


func unhandled_message(message : String, tags : Dictionary) -> void:
	var ignore = []
	var config = ConfigFile.new()
	if config.load("user://ignore.ini") == OK:
		ignore = config.get_value("ignore", "ignore", [])

	var msg : PackedStringArray = message.split(" ", true, 4)
	match msg[1]:
		"JOIN":
			var sender_data : SenderData = SenderData.new(Twitch.user_regex.search(msg[0]).get_string(), msg[2], tags)
			if ignore.has(sender_data.user):
				prints(sender_data.user, "joined channel! [IGNORED]")
			else:
				prints(sender_data.user, "joined channel!")
				#add_head(sender_data.user, "")


func twitch_disconnect():
	$login.show()
	$SoundButtonConfig.show()
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

	if OS.shell_open(uri + "?" + qs) != OK:
		print_debug("Can't open browser")


func get_profile_pic(login:Array):
	last_api_request = Time.get_ticks_msec()
	
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.connect("request_completed", Callable(self, "received_profile_pic").bind(http)) != OK:
		print_debug("Signal not connected")
	
	var url = "https://api.twitch.tv/helix/users?"
	for l in login:
		url += "login=%s&" % l
	var err = http.request(url, ["Authorization: Bearer " + Helper.get_saved_token(), "Client-Id: " + ProjectSettings.get("twitch/client_id")], HTTPClient.METHOD_GET)
	if err != OK:
		print("Error getting profile pic " + str(err))


func received_profile_pic(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest):
	http.queue_free()
	
	var data = body.get_string_from_utf8()
	var test_json_conv = JSON.new()
	test_json_conv.parse(data)
	var message = test_json_conv.get_data()
	for user in message.data:
		profile_pics[user.login]["url"] = user.profile_image_url
		get_profile_image(user.login, user.profile_image_url)


func get_profile_image(login:String, url:String):
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.connect("request_completed", Callable(self, "profile_image_received").bind(http, login, url)) != OK:
		print_debug("Signal not connected")
		
	var err = http.request(url)
	if err != OK:
		print("Error getting profile image " + str(err))
	
	
func profile_image_received(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest, login: String, url: String):
	http.queue_free()
	
	var image = Image.new()
	if url.ends_with("png"):
		image.load_png_from_buffer(body)
	else:
		image.load_jpg_from_buffer(body)

	profile_pics[login]["sprite"].add_head(image, login)
	profile_pics[login]["ready"] = true
	profile_pic_queue.erase(login)


func _on_MIDIButton_pressed():
	if $login/MIDIButton.pressed:
		print("MIDI ON")
		OS.open_midi_inputs()
	else:
		print("MIDI OFF")
		OS.close_midi_inputs()

func midi(_pitch):
	var chatters = get_tree().get_nodes_in_group("chatter")

	if chatters.size() == 0:
		return
		
	chatters.shuffle()
	for c in chatters:
		if c.linear_velocity.length() > 100:
			continue
		c.apply_central_impulse(Vector2(0, -200).rotated(randf() * PI/2 - PI/4))
		var explosion = preload("res://booms/explosion.tscn").instance()
		explosion.position = c.position
		add_child(explosion)

		return explosion


func _on_AutoLoginTimer_timeout():
	_on_joinButton_pressed()
	$login/AutoLoginLabel.hide()


func _process(_delta):
	if not $login/AutoLoginTimer.is_stopped():
		$login/AutoLoginLabel.text = "Automatic login in %d..." % [ceil($login/AutoLoginTimer.time_left)]
		
