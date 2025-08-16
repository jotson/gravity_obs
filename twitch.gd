extends Gift

signal got_channel_info

var broadcaster_id = "80362534"
var broadcaster_login = null
var broadcaster_name = null
var channel_title = null
var channel_game_id = null
var channel_game_name = null
var emotes: Dictionary

var server: TCPServer = TCPServer.new()
var server_peer: StreamPeerTCP


func _ready():
	pass


func register_emote(id, image: Image = null) -> ImageTexture:
	if emotes.has(id):
		return emotes[id]
	
	var path = "user://emotes/%s.png" % id
	
	if image == null:
		if FileAccess.file_exists(path):
			image = Image.load_from_file(path)
	else:
		image.save_png(path)
		prints("Register emote", image.resource_path)
	
	if image:
		var texture = ImageTexture.create_from_image(image)
		texture.take_over_path(path)
		emotes[id] = texture
		return texture
		
	return null
	

func join(channel):
	connect_to_twitch()
	await Twitch.twitch_connected
	
	var token = Helper.get_saved_token()
	if token:
		# authorized login for reading and chatting
		authenticate_oauth(channel, "oauth:" + token)
	else:
		# Anonymous login just for reading
		print("Anonymous! No Oauth token available!")
		var username = "justinfan" + str(int(randf_range(100000,999999)))
		authenticate_oauth(username, str(randi()))
	
	Helper.save_channel(channel)
	join_channel(channel)
	get_channel_info()


func update_reward_redemption_status(redemption_id: String, reward_id: String):
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.request_completed.connect(received_channel_info.bind(http)) != OK:
		print_debug("Signal not connected")

	var err = http.request("https://api.twitch.tv/helix/channel_points/custom_rewards/redemptions?broadcaster_id=%s&id=%s&reward_id=%s&status=FULFILLED" % [str(broadcaster_id), redemption_id, reward_id], ["Authorization: Bearer " + Helper.get_saved_token(), "Client-Id: " + Helper.get_client_id()], HTTPClient.METHOD_PATCH)
	if err != OK:
		print("Error getting stream info " + str(err))
	await http.request_completed
	http.queue_free()


func get_channel_info():
	# Get channel_info
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.request_completed.connect(received_channel_info.bind(http)) != OK:
		print_debug("Signal not connected")
	
	var err = http.request("https://api.twitch.tv/helix/channels?broadcaster_id=%s" % str(broadcaster_id), ["Authorization: Bearer " + Helper.get_saved_token(), "Client-Id: " + Helper.get_client_id()], HTTPClient.METHOD_GET)
	if err != OK:
		print("Error getting stream info " + str(err))
	await http.request_completed


func received_channel_info(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest):
	http.queue_free()
	
	if response_code != 200:
		print("Twitch API Error:", result)
		print("Twitch Response code:", response_code)
		print(headers)
		print(body.get_string_from_utf8())
		if response_code == 401:
			refresh_access_token()
		return
		
	var data = body.get_string_from_utf8()
	var test_json_conv = JSON.new()
	test_json_conv.parse(data)
	var message = test_json_conv.get_data()
	broadcaster_id = message.data[0].broadcaster_id
	broadcaster_login = message.data[0].broadcaster_login
	broadcaster_name = message.data[0].broadcaster_name
	channel_title = message.data[0].title
	channel_game_id = message.data[0].game_id
	channel_game_name = message.data[0].game_name
	
	got_channel_info.emit()


func auth():
	server.stop()
	server.listen(8080)
	
	var uri = "https://id.twitch.tv/oauth2/authorize"
	var client = HTTPClient.new()
	var fields = {
		"client_id": Helper.get_client_id(),
		"redirect_uri": "http://localhost:8080",
		"response_type": "code",
		"force_verify": "true",
		"scope": "chat:read chat:edit channel:read:redemptions moderator:read:followers"
	}
	var qs = client.query_string_from_dict(fields)

	if OS.shell_open(uri + "?" + qs) != OK:
		print_debug("Can't open browser")


func _process(delta: float) -> void:
	super(delta)
	
	if server:
		if server_peer:
			server_peer.poll()
			var data: String = server_peer.get_utf8_string(server_peer.get_available_bytes())
			if data.contains("GET /?code="):
				var lines = data.split("\r\n")
				var request = lines[0]
				var params = request.replace("GET /?", "").split("&")
				var code: String = ""
				for p in params:
					if p.begins_with("code="):
						code = p.split("=")[1]
				if code:
					convert_auth_code_to_access_token(code)
				server_peer.disconnect_from_host()
				server.stop()
				server = null
				server_peer = null
		elif server.is_connection_available():
			server_peer = server.take_connection()


func convert_auth_code_to_access_token(code):
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.request_completed.connect(got_access_token.bind(http)) != OK:
		print_debug("Signal not connected")
	
	var url = "https://id.twitch.tv/oauth2/token"
	var data = "client_id=%s&client_secret=%s&code=%s&grant_type=authorization_code&redirect_uri=http://localhost:8080" % [Helper.get_client_id(), Helper.get_client_secret(), code]
	prints("Converting auth code", url, data)
	http.request(url, [ "Content-Type: application/x-www-form-urlencoded" ], HTTPClient.METHOD_POST, data)


func got_access_token(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray, _http: HTTPRequest):
	var data = body.get_string_from_utf8()
	var test_json_conv = JSON.new()
	test_json_conv.parse(data)
	var message = test_json_conv.get_data()
	prints("Got auth token", message.access_token, message.refresh_token)
	Helper.save_access_token(message.access_token, message.refresh_token)


func refresh_access_token() -> void:
	close_all_connections()

	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.request_completed.connect(got_access_token.bind(http)) != OK:
		print_debug("Signal not connected")
	
	var url = "https://id.twitch.tv/oauth2/token"
	var data = "client_id=%s&client_secret=%s&refresh_token=%s&grant_type=refresh_token" % [Helper.get_client_id(), Helper.get_client_secret(), Helper.get_refresh_token().uri_encode()]
	prints("Converting auth code", url, data)
	http.request(url, [ "Content-Type: application/x-www-form-urlencoded" ], HTTPClient.METHOD_POST, data)


func close_all_connections():
	Helper.user_exit = true
	Twitch.websocket.close()
	TwitchPS.websocket.close()
	OBS.websocket.close()
	Twitch.server = null
	Twitch.server_peer = null
