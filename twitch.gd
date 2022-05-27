extends Gift

signal got_channel_info
signal response_received

var broadcaster_id = "80362534"
var broadcaster_login = null
var broadcaster_name = null
var channel_title = null
var channel_game_id = null
var channel_game_name = null


func api_request(endpoint: String, parameters: Dictionary, receiver: FuncRef, method = HTTPClient.METHOD_GET):
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.connect("request_completed", self, "response_received", [http, receiver]) != OK:
		print_debug("Signal not connected")

	var client = HTTPClient.new()
	var params = client.query_string_from_dict(parameters)
	var request_url = "https://api.twitch.tv/%s?%s" % [endpoint, params]
	var err = http.request(request_url, ["Authorization: Bearer " + Helper.get_saved_token(), "Client-Id: " + ProjectSettings.get("twitch/client_id")], false, method)
	if err != OK:
		print("Error getting stream info " + str(err))


func response_received(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray, http: HTTPRequest, receiver: FuncRef):
	http.queue_free()
	if response_code != 200:
		print("Twitch API Error:", result)
		print("Twitch Response code:", response_code)
		print(headers)
		print(body.get_string_from_utf8())
		return

	var data = body.get_string_from_utf8()
	var message = parse_json(data)

	receiver.call_func(message)
	
	emit_signal("response_received")


func join(channel):
	connect_to_twitch()
	yield(Twitch, "twitch_connected")
	
	var token = Helper.get_saved_token()
	if token:
		# authorized login for reading and chatting
		authenticate_oauth(channel, "oauth:" + token)
	else:
		# Anonymous login just for reading
		print("Anonymous! No Oauth token available!")
		var username = "justinfan" + str(int(rand_range(100000,999999)))
		authenticate_oauth(username, str(randi()))
	
	Helper.save_channel(channel)
	join_channel(channel)
	get_channel_info()


func update_reward_redemption_status(redemption_id: String, reward_id: String):
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	var err = http.request("https://api.twitch.tv/helix/channel_points/custom_rewards/redemptions?broadcaster_id=%s&id=%s&reward_id=%s&status=FULFILLED" % [str(broadcaster_id), redemption_id, reward_id], ["Authorization: Bearer " + Helper.get_saved_token(), "Client-Id: " + ProjectSettings.get("twitch/client_id")], false, HTTPClient.METHOD_PATCH)
	if err != OK:
		print("Error getting stream info " + str(err))
	yield(http, "request_completed")
	http.queue_free()


func get_user(login: String):
	api_request("helix/users", {"login": login}, funcref(self, "got_user"))


func got_user(message: Dictionary):
	var user_id = message.data[0].id
	return user_id


func get_videos(user_id: String):
	api_request("helix/videos", {"user_id": user_id}, funcref(self, "got_videos"))
	

func got_videos(message: Dictionary) -> Array:
	return message.data


func get_channel_info():
	api_request("helix/channels", {"broadcaster_id": str(broadcaster_id)}, funcref(self, "store_channel_info"))
	get_videos("80362534")


func store_channel_info(message: Dictionary):
	broadcaster_id = message.data[0].broadcaster_id
	broadcaster_login = message.data[0].broadcaster_login
	broadcaster_name = message.data[0].broadcaster_name
	channel_title = message.data[0].title
	channel_game_id = message.data[0].game_id
	channel_game_name = message.data[0].game_name
	emit_signal("got_channel_info")
