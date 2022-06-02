extends Control

var commands : Dictionary

var last_api_request = OS.get_ticks_msec()
var profile_pics = {}
var profile_pic_queue = []
var MAX_CHATTERS = 50


func _ready():
	Helper.set_transparent(false)
	$console.hide()
	$login/channel.grab_focus()

	var channel = Helper.get_saved_channel()
	if channel:
		$login/channel.text = channel

	if Twitch.connect("chat_message", self, "twitch_chat") != OK:
		print_debug("Signal not connected")
	if Twitch.connect("twitch_disconnected", self, "twitch_disconnect") != OK:
		print_debug("Signal not connected")
	if Twitch.connect("login_attempt", self, "twitch_login_attempt") != OK:
		print_debug("Signal not connected")
	if Twitch.connect("got_channel_info", self, "twitch_got_channel_info") != OK:
		print_debug("Signal not connected")

	if TwitchPS.connect("reward_redemption", self, "twitch_reward_redemption") != OK:
		print_debug("Signal not connected")

	load_commands()


func load_commands():
	commands.clear()
	Twitch.commands.clear()
	
	var f = File.new()	
	if f.open("user://commands.json", File.READ) != OK:
		return
	var command_data : Array = parse_json(f.get_as_text())
	f.close()
	
	for c in command_data:
		commands[c.command] = c
		
		var perm = Twitch.PermissionFlag.EVERYONE
		if c.has("streamer") and c.streamer:
			perm = Twitch.PermissionFlag.STREAMER
			
		if c.has("action") and c.action == "battle":
			Twitch.add_command(c.command, self, "cmd_battle", 0, 0, perm)
	
		if c.has("action") and c.action == "reload_commands":
			Twitch.add_command(c.command, self, "cmd_reload_commands", 0, 0, perm)
	
		if c.has("action") and c.action == "commands":
			Twitch.add_command(c.command, self, "cmd_commands", 0, 0, perm)

		if c.has("action") and c.action == "shoutout":
			Twitch.add_command(c.command, self, "cmd_shoutout", 1, 0, perm)
	
		if c.has("action") and c.action == "chat":
			Twitch.add_command(c.command, self, "cmd_chat", 0, 0, perm)

		if c.has("action") and c.action == "addtocredits":
			Twitch.add_command(c.command, self, "cmd_addtocredits", 0, 0, perm)
	
			
		if c.has("aliases"):
			for alias in c.aliases:
				Twitch.add_alias(c.command, alias)
				commands[alias] = {
					"alias": c.command
				}


func cmd_shoutout(_cmd : CommandInfo, username):
	Twitch.chat("Go check out https://twitch.tv/%s because they are awesome!" % username[0])


func cmd_commands(_cmd : CommandInfo):
	Twitch.chat("Here's what you can do:")
	
	var chat = ""
	for key in commands.keys():
		var c = commands[key]
		if c.has("streamer") && c.streamer == true:
			continue
		if c.has("alias"):
			continue
		
		chat = "!%s: %s" % [c.command, c.help]
		Twitch.chat(chat)


func cmd_reload_commands(_cmd : CommandInfo):
	load_commands()
	

func cmd_battle(_cmd : CommandInfo):
	Battle.start_round()
	
	
func cmd_chat(_cmd : CommandInfo):
	var chat = ""
	
	if commands[_cmd.command].has("text"):
		chat = commands[_cmd.command].text
	if commands[_cmd.command].has("alias"):
		var alias = commands[_cmd.command].alias
		chat = commands[alias].text
		
	Twitch.chat(chat)


func cmd_addtocredits(_cmd : CommandInfo):
	var filename = "user://twitch-credits.txt"
	var f = File.new()
	if f.open(filename, File.READ_WRITE) == OK:
		f.seek_end()
		f.store_line(_cmd.sender_data.user)
	f.close()
	

func _on_joinButton_pressed(_text = ""):
	if $login/channel.text:
		$login.hide()
		Helper.set_transparent(true)
		Twitch.join($login/channel.text)
		
		profile_pics.clear()
		profile_pic_queue.clear()
		for c in $chatters.get_children():
			c.queue_free()


func _on_channel_text_entered(new_text):
	_on_joinButton_pressed(new_text)


func twitch_reward_redemption(who : String, reward : String):
	var notify = true
	
	print("%s redeemed %s" % [who, reward])
	if reward.to_lower() == "this is fine":
		var fire = preload("res://flames/flames.tscn").instance()
		Helper.add_child(fire)
		
	if reward.begins_with("Play sound: "):
		notify = false
		var sound = reward.trim_prefix("Play sound: ")
		Soundboard.play(sound)
	
	if notify:
		var notification = preload("res://reward/reward.tscn").instance()
		notification.who = who
		notification.reward = reward
		Helper.add_child(notification)
	

func twitch_login_attempt(success):
	if (success):
		#OS.window_minimized = true
		OBS.connect_to_obs()


func twitch_got_channel_info():
	TwitchPS.connect_to_twitch()


func twitch_chat(sender_data, command : String, full_message : String):
	var username = sender_data.user
	
	command = command.to_lower()
	
	var message = full_message.split(" ")
	message.remove(0)
	message.remove(0)
	message.remove(0)
	message = message.join(" ")
	message = message.substr(1)
	
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

	if not profile_pics.has(username) and not profile_pic_queue.has(username):
		if profile_pics.size() > MAX_CHATTERS:
			for j in range(profile_pics.size() - MAX_CHATTERS):
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
		var chatter = preload("res://chatter/chatter.tscn").instance()
		profile_pics[username]["sprite"] = chatter
		chatter.add_head(null, username, first)
		$chatters.add_child(chatter)
		chatter.say(message)
		
		profile_pic_queue.append(username)
	
	if profile_pic_queue.size() and OS.get_ticks_msec() > last_api_request + 3000:
		get_profile_pic(profile_pic_queue)
		profile_pic_queue.clear()
		
	if profile_pics.has(username):
		profile_pics[username]["sprite"].say(message)


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

	if OS.shell_open(uri + "?" + qs) != OK:
		print_debug("Can't open browser")


func get_profile_pic(login:Array):
	last_api_request = OS.get_ticks_msec()
	
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.connect("request_completed", self, "received_profile_pic", [http]) != OK:
		print_debug("Signal not connected")
	
	var url = "https://api.twitch.tv/helix/users?"
	for l in login:
		url += "login=%s&" % l
	var err = http.request(url, ["Authorization: Bearer " + Helper.get_saved_token(), "Client-Id: " + ProjectSettings.get("twitch/client_id")], false, HTTPClient.METHOD_GET)
	if err != OK:
		print("Error getting profile pic " + str(err))


func received_profile_pic(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray, http: HTTPRequest):
	http.queue_free()
	
	var data = body.get_string_from_utf8()
	var message = parse_json(data)
	for user in message.data:
		profile_pics[user.login]["url"] = user.profile_image_url
		get_profile_image(user.login, user.profile_image_url)


func get_profile_image(login:String, url:String):
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.connect("request_completed", self, "profile_image_received", [http, login, url]) != OK:
		print_debug("Signal not connected")
		
	var err = http.request(url)
	if err != OK:
		print("Error getting profile image " + str(err))
	
	
func profile_image_received(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray, http: HTTPRequest, login: String, url: String):
	http.queue_free()
	
	var image = Image.new()
	if url.ends_with("png"):
		image.load_png_from_buffer(body)
	else:
		image.load_jpg_from_buffer(body)

	profile_pics[login]["sprite"].add_head(image, login)
	profile_pics[login]["ready"] = true
