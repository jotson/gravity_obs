extends Node

var websocket : WebSocketClient = WebSocketClient.new()

var heartbeatTimer : Timer = Timer.new()

signal reward_redemption


func _ready():
	heartbeatTimer.wait_time = 60
	if heartbeatTimer.connect("timeout", self, "heartbeat") != OK:
		print_debug("Signal not connected")
	add_child(heartbeatTimer)
	
	if websocket.connect("data_received", self, "data_received") != OK:
		print_debug("Signal not connected")
	if websocket.connect("connection_established", self, "connection_established") != OK:
		print_debug("Signal not connected")
	if websocket.connect("connection_closed", self, "connection_closed") != OK:
		print_debug("Signal not connected")
	if websocket.connect("connection_error", self, "connection_error") != OK:
		print_debug("Signal not connected")
	#websocket.connect("server_close_request", self, "sever_close_request")


func _process(_delta : float) -> void:
	if websocket_connected():
		websocket.poll()


func websocket_connected() -> bool:
	return websocket.get_connection_status() != NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED


func connect_to_twitch():
	if websocket.get_connection_status() == websocket.CONNECTION_CONNECTED:
		return
		
	var err = websocket.connect_to_url("wss://pubsub-edge.twitch.tv")
	print("Connecting to Twitch PubSub...")
	if err != OK:
		print("Twitch PubSub Error: " + str(err))


func connection_established(protocol : String):
	print("Twitch PubSub connection established " + protocol)
	heartbeatTimer.start()
	heartbeat()
	listen()

	
func listen():
	var message = {
		"type": "LISTEN",
		"data": {
			"topics": ["channel-points-channel-v1." + Twitch.broadcaster_id],
			"auth_token": Helper.get_saved_token()
		}
	}
	print("Twitch PubSub listening for channel points redemptions")
	send(message)


func heartbeat():
	var message = { "type": "PING" }
	print("Twitch PubSub PING")
	send(message)


func connection_closed(_clean_close : bool):
	print("Disconnected from Twitch PubSub")
	

func connection_error():
	print("Twitch PubSub connection error")
	

func data_received() -> void:
	var data : String = websocket.get_peer(1).get_packet().get_string_from_utf8()
	if data:
		var response = parse_json(data)
		
		if response.type == "PONG":
			print("Twitch PubSub PONG")
		
		# {data:{message:{"type":"reward-redeemed","data":{"timestamp":"2021-11-26T18:34:39.977781034Z","redemption":{"id":"c78c2dc2-cd45-4693-9e9f-02552277298b","user":{"id":"80362534","login":"jotson","display_name":"jotson"},"channel_id":"80362534","redeemed_at":"2021-11-26T18:34:39.977781034Z","reward":{"id":"4bf8a5f1-28ba-4480-a5b5-cac1c59c4715","channel_id":"80362534","title":"Posture Check!","prompt":"I straighten up - thanks!","cost":100,"is_user_input_required":false,"is_sub_only":false,"image":null,"default_image":{"url_1x":"https://static-cdn.jtvnw.net/custom-reward-images/clock-1.png","url_2x":"https://static-cdn.jtvnw.net/custom-reward-images/clock-2.png","url_4x":"https://static-cdn.jtvnw.net/custom-reward-images/clock-4.png"},"background_color":"#BEFF00","is_enabled":true,"is_paused":false,"is_in_stock":true,"max_per_stream":{"is_enabled":false,"max_per_stream":1},"should_redemptions_skip_request_queue":false,"template_id":"template:255258f1-642e-4268-815c-fb282178c424","updated_for_indicator_at":"2020-12-04T05:27:21.280847331Z","max_per_user_per_stream":{"is_enabled":false,"max_per_user_per_stream":1},"global_cooldown":{"is_enabled":false,"global_cooldown_seconds":1},"redemptions_redeemed_current_stream":null,"cooldown_expires_at":null},"status":"UNFULFILLED"}}}, topic:channel-points-channel-v1.80362534}, type:MESSAGE}
		if response.type == "MESSAGE":
			# {"type":"reward-redeemed","data":{"timestamp":"2021-11-26T18:36:09.766992406Z","redemption":{"id":"898aef9c-96f1-454a-8d88-b240d069fa85","user":{"id":"80362534","login":"jotson","display_name":"jotson"},"channel_id":"80362534","redeemed_at":"2021-11-26T18:36:09.766992406Z","reward":{"id":"4bf8a5f1-28ba-4480-a5b5-cac1c59c4715","channel_id":"80362534","title":"Posture Check!","prompt":"I straighten up - thanks!","cost":100,"is_user_input_required":false,"is_sub_only":false,"image":null,"default_image":{"url_1x":"https://static-cdn.jtvnw.net/custom-reward-images/clock-1.png","url_2x":"https://static-cdn.jtvnw.net/custom-reward-images/clock-2.png","url_4x":"https://static-cdn.jtvnw.net/custom-reward-images/clock-4.png"},"background_color":"#BEFF00","is_enabled":true,"is_paused":false,"is_in_stock":true,"max_per_stream":{"is_enabled":false,"max_per_stream":1},"should_redemptions_skip_request_queue":false,"template_id":"template:255258f1-642e-4268-815c-fb282178c424","updated_for_indicator_at":"2020-12-04T05:27:21.280847331Z","max_per_user_per_stream":{"is_enabled":false,"max_per_user_per_stream":1},"global_cooldown":{"is_enabled":false,"global_cooldown_seconds":1},"redemptions_redeemed_current_stream":null,"cooldown_expires_at":null},"status":"UNFULFILLED"}}}
			var message = parse_json(response.data.message)
			if message.type == "reward-redeemed":
				var user = message.data.redemption.user.display_name
				var reward_title = message.data.redemption.reward.title
				emit_signal("reward_redemption", user, reward_title)


func send(message : Dictionary) -> void:
	if not websocket_connected():
		print_debug("Twitch PubSub not connected")
		return
		
	websocket.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	var text = JSON.print(message)
	print_debug("Twitch PubSub: ", text)
	var err = websocket.get_peer(1).put_packet(text.to_utf8())
	if err != OK:
		print_debug("Twitch PubSub failed to send message, error: " + str(err))
	
