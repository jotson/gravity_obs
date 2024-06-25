extends Gift

signal got_channel_info

var broadcaster_id = "80362534"
var broadcaster_login = null
var broadcaster_name = null
var channel_title = null
var channel_game_id = null
var channel_game_name = null


func _ready():
	pass


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
	if http.connect("request_completed", Callable(self, "received_channel_info").bind(http)) != OK:
		print_debug("Signal not connected")

	var err = http.request("https://api.twitch.tv/helix/channel_points/custom_rewards/redemptions?broadcaster_id=%s&id=%s&reward_id=%s&status=FULFILLED" % [str(broadcaster_id), redemption_id, reward_id], ["Authorization: Bearer " + Helper.get_saved_token(), "Client-Id: " + ProjectSettings.get("twitch/client_id")], HTTPClient.METHOD_PATCH)
	if err != OK:
		print("Error getting stream info " + str(err))
	await http.request_completed
	http.queue_free()


func get_channel_info():
	# Get channel_info
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.connect("request_completed", Callable(self, "received_channel_info").bind(http)) != OK:
		print_debug("Signal not connected")
	
	var err = http.request("https://api.twitch.tv/helix/channels?broadcaster_id=%s" % str(broadcaster_id), ["Authorization: Bearer " + Helper.get_saved_token(), "Client-Id: " + ProjectSettings.get("twitch/client_id")], HTTPClient.METHOD_GET)
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
	
	emit_signal("got_channel_info")
