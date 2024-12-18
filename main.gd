extends Control

var commands : Dictionary

var last_api_request = Time.get_ticks_msec()
var profile_pics = {}
var profile_pic_queue = []
var MAX_CHATTERS = 50
var lastChannel = ""
var dragged = null

const COMMANDS_JSON = "user://commands.json"
const EVENTS_JSON = "user://events.json"

const AstronautChatter = preload("res://chatter/Astronaut.tscn")
const AstronautContainer = preload("res://chatter/AstronautContainer.tscn")
const MarbleChatter = preload("res://chatter/Marble.tscn")
const MarbleContainer = preload("res://chatter/MarbleContainer.tscn")
@onready var Chatter = MarbleChatter
@onready var ChatterContainer = MarbleContainer.instantiate()


func _ready():
	configure_window()
	
	$console.hide()
	$Gamepad.hide()
	$login/channel.grab_focus()
	%Chat.hide()

	Helper.add(ChatterContainer)
	
	var channel = Helper.get_saved_channel()
	if channel:
		$login/channel.text = channel
		
	if Soundboard.midi.connect(self.midi) != OK:
		print_debug("Signal not connected")
	if Twitch.chat_message.connect(twitch_chat) != OK:
		print_debug("Signal not connected")
	if Twitch.unhandled_message.connect(unhandled_message) != OK:
		print_debug("Signal not connected")
	if Twitch.twitch_disconnected.connect(twitch_disconnect) != OK:
		print_debug("Signal not connected")
	if Twitch.login_attempt.connect(twitch_login_attempt) != OK:
		print_debug("Signal not connected")
	if Twitch.got_channel_info.connect(twitch_got_channel_info) != OK:
		print_debug("Signal not connected")

	if TwitchPS.reward_redemption.connect(twitch_reward_redemption) != OK:
		print_debug("Signal not connected")
		
	load_commands()


func configure_window():
	Helper.set_transparent(false)
	#get_window().always_on_top = true
	#get_window().mouse_passthrough = false
	#get_window().mouse_passthrough_polygon = PackedVector2Array([])


func toggle_mouse_passthrough():
	get_window().mouse_passthrough = true
	var t = create_tween()
	t.tween_property(get_window(), "mouse_passthrough", false, 5)
	t.tween_callback(get_window().grab_focus)


func set_mouse_passthrough():
	var polygon = []
	for i in %MouseCapture/Polygon2D.polygon:
		polygon.append(%MouseCapture/Polygon2D.to_global(i))
	get_window().mouse_passthrough_polygon = PackedVector2Array(polygon)


func _on_mouse_capture_toggled(toggled_on: bool) -> void:
	if toggled_on:
		get_window().mouse_passthrough_polygon = PackedVector2Array([])
	else:
		set_mouse_passthrough()


func _unhandled_input(event):
	if $login.visible:
		return
	
	if event.is_action_pressed("show_soundboard"):
		if Soundboard.visible:
			Soundboard.hide()
		else:
			Soundboard.show()
		
	if event.is_action_pressed("toggle_console"):
		if $console.visible:
			$console.hide()
		else:
			$console.show()
			
	if event.is_action_pressed("toggle_gamepad"):
		if $Gamepad.visible:
			$Gamepad.hide()
			$console.text = "Gamepad off\n"
		else:
			$Gamepad.show()
			$console.text = "Gamepad on\n"
			
	if event.is_action_pressed("toggle_heads"):
		if ChatterContainer.visible:
			ChatterContainer.hide()
			$console.text = "Heads off\n"
		else:
			ChatterContainer.show()
			$console.text = "Heads on\n"
	
	if event.is_action_pressed("chat"):
		%Chat.show()
		%Chat.text = ""
		%Chat.grab_focus()
		
	if event.is_action_pressed("toggle_mousepassthru"):
		toggle_mouse_passthrough()
		
	if event.is_action_pressed("add_box"):
		var obj = preload("res://chatter/box.tscn").instantiate()
		obj.global_position = get_global_mouse_position()
		obj.rotation = PI
		Helper.add(obj)
		
	if event.is_action_pressed("note"):
		var obj = preload("res://chatter/note.tscn").instantiate()
		obj.global_position = get_global_mouse_position() + Vector2(randf_range(-100, -50), 90)
		Helper.add(obj)
		create_pin()
		
	if event.is_action_pressed("add_weight"):
		var obj = preload("res://chatter/weight.tscn").instantiate()
		obj.global_position = get_global_mouse_position()
		Helper.add(obj)

	if event.is_action_pressed("add_jail"):
		var obj = preload("res://chatter/jail.tscn").instantiate()
		obj.global_position = get_global_mouse_position()
		Helper.add(obj)

	if event.is_action_pressed("pin"):
		create_pin()
	
	if event.is_action_pressed("move_to_front"):
		if dragged and dragged.find_child("PinJoint2D"):
			get_node(dragged.find_child("PinJoint2D").node_b).move_to_front()
		if dragged:
			dragged.move_to_front()
			for node in get_tree().get_nodes_in_group("freezable"):
				if node.find_child("PinJoint2D"):
					if node.find_child("PinJoint2D").node_b == dragged.get_path():
						node.move_to_front()
			
	if event is InputEventMouseButton:
		event = event as InputEventMouseButton
		if event.button_index == 1 and event.is_pressed():
			var collider = get_object_under_cursor()
			if collider:
				if collider.is_in_group("freezable"):
					collider.freeze = false
				$MouseBody.pin(collider)
				dragged = collider
		if event.button_index == 1 and not event.is_pressed():
			throw()
		if event.button_index == 2 and event.is_pressed():
			var collider = get_object_under_cursor()
			if collider and collider.is_in_group("removable"):
				collider.queue_free()


func create_pin(pos: Vector2 = Vector2(-1,-1)):
	var obj = preload("res://chatter/pin.tscn").instantiate()
	if pos.x == -1:
		obj.global_position = get_global_mouse_position()
	else:
		obj.global_position = pos
	Helper.add(obj)
	if obj.is_in_group("freezable"):
		obj.freeze = true
	var collider = get_object_under_cursor(pos, [obj.get_rid()])
	if collider:
		obj.pin(collider)
	return obj


func get_object_under_cursor(pos: Vector2 = Vector2(-1,-1), exclude = null) -> Node2D:
	var state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	if pos.x == -1:
		query.position = get_global_mouse_position()
	else:
		query.position = pos
	query.collide_with_areas = true
	if exclude:
		query.exclude = exclude
	var collisions = state.intersect_point(query)
	collisions.sort_custom(
		func(a, b): return a.collider.get_index() > b.collider.get_index()
	)
	if collisions.size():
		var collider = collisions[0].collider
		for n in range(3):
			if not (collider is RigidBody2D or collider is StaticBody2D):
				collider = collider.get_parent()
				break
		return collider
	return null


func _process(_delta):
	if not $login/AutoLoginTimer.is_stopped():
		$login/AutoLoginLabel.text = "Automatic login in %d..." % [ceil($login/AutoLoginTimer.time_left)]


func throw() -> void:
	var vel = Input.get_last_mouse_velocity()
	$MouseBody.unpin()
	if is_instance_valid(dragged) and dragged.has_method("apply_central_impulse"):
		if dragged.is_in_group("freezable"):
			dragged.freeze = true
		dragged.apply_central_impulse(vel)
	dragged = null


func load_commands():
	commands.clear()
	Twitch.commands.clear()
	
	var f = FileAccess.open(COMMANDS_JSON, FileAccess.READ)
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
		
		if c.has("action") and c.action == "thisisfine":
			Twitch.add_command(c.command, cmd_thisisfine, 0, 0, perm)
			
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
	

func cmd_chat(cmd : CommandInfo):
	load_commands()
	var chat = ""
	
	if commands[cmd.command].has("text"):
		chat = commands[cmd.command].text
	if commands[cmd.command].has("alias"):
		var alias = commands[cmd.command].alias
		chat = commands[alias].text
		
	Twitch.chat(chat)


func cmd_thisisfine(_cmd: CommandInfo):
	var fire = preload("res://flames/flames.tscn").instantiate()
	Helper.add(fire)


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
		Helper.user_exit = false
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
	print("%s redeemed %s" % [who, reward])

	# Load EVENTS_JSON
	var f = FileAccess.open(EVENTS_JSON, FileAccess.READ)
	if f == null:
		return
		
	var json = f.get_as_text()
	var test_json_conv = JSON.new()
	test_json_conv.parse(json)
	var events = test_json_conv.get_data()
	f.close()
	
	for e in events:
		if e.event != "reward":
			continue
			
		if e.has("pattern") and reward.to_lower().begins_with(e.pattern.to_lower()):
			if e.has("sound"):
				Soundboard.play(e.sound)
			if e.has("action"):
				var action = e.action
				match action:
					"playsound":
						var sound = reward.trim_prefix(e.pattern)
						Soundboard.play_queue(sound)
			


func twitch_login_attempt(success):
	if (success):
		OBS.connect_to_obs()


func twitch_got_channel_info():
	TwitchPS.connect_to_twitch()


func twitch_chat(sender_data, command : String, full_message : String):
	var username = sender_data.user
	
	Soundboard.play("chat")
	
	command = command.to_lower()
	
	var message_array: PackedStringArray = full_message.split(" ")
	message_array.remove_at(0)
	message_array.remove_at(0)
	message_array.remove_at(0)
	var message: String = " ".join(message_array)
	message = message.substr(1)
	
	# Get emotes from sender_data.tags.emotes 443:5-6/555555629:17-19
	# Format is <ID>:<POSITION>/<ID>:<POSITION>/...
	# Emotes image https://static-cdn.jtvnw.net/emoticons/v1/<ID>/2.0
	var tags: Dictionary = sender_data.tags
	var emotes = tags.emotes.split("/")
	emotes.reverse()
	var emote_ids: Dictionary
	for emote in emotes:
		var emote_data = emote.split(":")
		var id = emote_data[0]
		if id:
			emote_ids[id] = id
	for id in emote_ids.keys():
		var image_url = "https://static-cdn.jtvnw.net/emoticons/v1/%s/2.0" % id
		var o = load("res://smiley/emote.tscn").instantiate()
		Helper.add(o)
		await o.fetch(id, image_url)
	
	# Render message in bbcode
	var new_message: String = ""
	var i = 0
	while i < len(message):
		var c = message.substr(i, 1)
		var bbimg = ""
		for emote in emotes:
			var emote_data = emote.split(":")
			var id = emote_data[0]
			if not id:
				continue
			var pos = emote_data[1].split(",")
			for p in pos:
				var start_end = str(p).split("-")
				var start = int(start_end[0])
				var end = int(start_end[1])
				if start == i:
					bbimg = "[img=16]%s[/img]" % Twitch.emotes[id].resource_path
					new_message += bbimg
					i = end + 1
					break
			if bbimg:
				break
		if bbimg == "":
			new_message += c
			i += 1
	message = new_message
	
	if message.contains("?"):
		var o = load("res://chatter/quote.tscn").instantiate()
		var p = Helper.random_position()
		o.position = p + Vector2(randi_range(-60, 60), 30)
		Helper.add(o)
		o.set_message("[center][i][wave amp=20.0 freq=10.0 connected=1][b]%s:[/b] %s[/wave][/i][/center]" % [username, message])
		
	var hearts = Helper.get_count(full_message, "<3")
	if hearts > 0:
		for _n in range(10):
			var o = load("res://heart/heart.tscn").instantiate()
			o.position = Helper.random_position()
			Helper.add(o)
		
	var smiles = Helper.get_count(full_message, ":-)")
	smiles += Helper.get_count(full_message, ":)")
	smiles += Helper.get_count(full_message, ":D")
	if smiles > 0:
		for _n in range(10):
			var o = load("res://smiley/smiley.tscn").instantiate()
			o.position = Helper.random_position()
			Helper.add(o)

	add_head(username, message)
	
	
func add_head(username, message):
	var ignore = []
	var config = ConfigFile.new()
	if config.load("user://ignore.ini") == OK:
		ignore = config.get_value("ignore", "ignore", [])

	if ignore.has(username):
		return
		
	if not profile_pics.has(username) and not profile_pic_queue.has(username):
		if profile_pics.size() > MAX_CHATTERS:
			for _j in range(profile_pics.size() - MAX_CHATTERS):
				var i = randi() % MAX_CHATTERS
				var keys = profile_pics.keys()
				var key = keys[i]
				var c = profile_pics[key]
				if c["ready"]:
					c["node"].queue_free()
					profile_pics.erase(key)
					print("killed %s" % key)
			
		profile_pics[username] = {
			"url": null,
			"node": null,
			"ready": false
		}
		var first = false
		if profile_pics.size() == 1:
			first = true
		var chatter = Chatter.instantiate()
		profile_pics[username]["node"] = chatter
		chatter.add_head(null, username, first)
		ChatterContainer.add_child(chatter)
		chatter.say(message)
		
		profile_pic_queue.append(username)
	elif profile_pics.has(username):
			profile_pics[username]["node"].say(message)

	if profile_pic_queue.size() and Time.get_ticks_msec() > last_api_request + 500:
		get_profile_pic(profile_pic_queue)


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


func twitch_disconnect():
	if Helper.user_exit:
		$login.show()
		$SoundButtonConfig.show()
		Helper.set_transparent(false)
	else:
		%AutoLoginTimer.wait_time = 1.0
		%AutoLoginTimer.start()


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
	if http.request_completed.connect(received_profile_pic.bind(http)) != OK:
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
		if profile_pics.has(user.login):
			profile_pics[user.login]["url"] = user.profile_image_url
		get_profile_image(user.login, user.profile_image_url)


func get_profile_image(login:String, url:String):
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.request_completed.connect(profile_image_received.bind(http, login, url)) != OK:
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
	
	if profile_pics.has(login):
		profile_pics[login]["node"].add_head(image, login)
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
		c.apply_central_impulse(Vector2(0, -3000).rotated(randf() * TAU))
		var explosion = preload("res://booms/explosion.tscn").instantiate()
		explosion.position = c.position
		Helper.add(explosion)

		return explosion


func _on_AutoLoginTimer_timeout():
	_on_joinButton_pressed()
	$login/AutoLoginLabel.hide()


func _on_chat_text_submitted(new_text: String) -> void:
	if len(new_text) > 0:
		Twitch.chat(new_text)
		
	%Chat.hide()


func _on_auto_command_timer_timeout() -> void:
	var auto: Array = []
	for i in commands:
		var command = commands[i]
		if command.has("auto") and command.auto:
			auto.append(command)
	
	if auto.size() == 0:
		return
		
	var auto_command = auto.pick_random()
	
	if auto_command.action == "chat":
		var cmd: CommandInfo = CommandInfo.new(null, auto_command.command, false)
		Twitch.chat("!%s" % auto_command.command)
		cmd_chat(cmd)
