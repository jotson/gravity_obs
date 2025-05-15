extends Node

var websocket : WebSocketPeer = WebSocketPeer.new()
var websocket_state = -1
var session_id
var websocket_url = "wss://eventsub.wss.twitch.tv/ws"

signal reward_redemption


func _ready():
	#if websocket.connect("data_received", Callable(self, "data_received")) != OK:
	#	print_debug("Signal not connected")
	#websocket.peer_connected.connect(connection_established)
	#websocket.peer_disconnected.connect(connection_closed)
	#if websocket.connect("connection_error", Callable(self, "connection_error")) != OK:
	#	print_debug("Signal not connected")
	pass


func update_socket_state(state):
#	websocket.connect("data_received", Callable(self, "data_received"))
#	websocket.connect("connection_established", Callable(self, "connection_established"))
#	websocket.connect("connection_closed", Callable(self, "connection_closed"))
#	websocket.connect("connection_error", Callable(self, "connection_error"))
	if websocket_state != state:
		websocket_state = state
		
		match websocket_state:
			WebSocketPeer.STATE_CLOSED:
				connection_closed(false)
			WebSocketPeer.STATE_CLOSING:
				pass
			WebSocketPeer.STATE_CONNECTING:
				pass
			WebSocketPeer.STATE_OPEN:
				connection_established()
				
				
func _process(_delta : float) -> void:
	websocket.poll()
	var state = websocket.get_ready_state()
	update_socket_state(state)
	if state == WebSocketPeer.STATE_OPEN:
		while websocket.get_available_packet_count():
			data_received()


func websocket_connected() -> bool:
	return websocket.get_ready_state() != WebSocketPeer.STATE_CLOSED


func connect_to_twitch():
	if websocket_connected():
		return
		
	var err = websocket.connect_to_url(websocket_url)
	print("Connecting to Twitch EventSub...")
	if err != OK:
		print("Twitch EventSub Error: " + str(err))


func connection_established():
	print("Twitch EventSub connection established")
	
	
func listen():
	var http = HTTPRequest.new()
	add_child(http)

	if http.connect("request_completed", listen_response.bind(http)) != OK:
		print_debug("Signal not connected")

	var headers = [
		"Authorization: Bearer %s" % Helper.get_saved_token(),
		"Client-Id: %s" % ProjectSettings.get("twitch/client_id"),
		"Content-Type: application/json",
	]
	var data = JSON.stringify(
		{
			"type": "channel.channel_points_custom_reward_redemption.add",
			"version": "1",
			"condition": { "broadcaster_user_id": Twitch.broadcaster_id },
			"transport": {
				"method": "websocket",
				"session_id": session_id,
			}
		}
	)
	
	var url = "https://api.twitch.tv/helix/eventsub/subscriptions"
	var err = http.request(url, headers, HTTPClient.METHOD_POST, data)
	if err != OK:
		print("Could not create EventSub subscription: " + str(err))


func listen_response(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray, http: HTTPRequest):
	http.queue_free()
	if response_code != 200:
		return


func connection_closed(_clean_close : bool):
	print("Disconnected from Twitch EventSub")
	

func connection_error():
	print("Twitch EventSub connection error")
	

func data_received() -> void:
	var data : String = websocket.get_packet().get_string_from_utf8()
	if data:
		var test_json_conv = JSON.new()
		test_json_conv.parse(data)
		var response = test_json_conv.get_data()
		var msg = response.metadata.message_type
		
		# {data:{message:{"type":"reward-redeemed","data":{"timestamp":"2021-11-26T18:34:39.977781034Z","redemption":{"id":"c78c2dc2-cd45-4693-9e9f-02552277298b","user":{"id":"80362534","login":"jotson","display_name":"jotson"},"channel_id":"80362534","redeemed_at":"2021-11-26T18:34:39.977781034Z","reward":{"id":"4bf8a5f1-28ba-4480-a5b5-cac1c59c4715","channel_id":"80362534","title":"Posture Check!","prompt":"I straighten up - thanks!","cost":100,"is_user_input_required":false,"is_sub_only":false,"image":null,"default_image":{"url_1x":"https://static-cdn.jtvnw.net/custom-reward-images/clock-1.png","url_2x":"https://static-cdn.jtvnw.net/custom-reward-images/clock-2.png","url_4x":"https://static-cdn.jtvnw.net/custom-reward-images/clock-4.png"},"background_color":"#BEFF00","is_enabled":true,"is_paused":false,"is_in_stock":true,"max_per_stream":{"is_enabled":false,"max_per_stream":1},"should_redemptions_skip_request_queue":false,"template_id":"template:255258f1-642e-4268-815c-fb282178c424","updated_for_indicator_at":"2020-12-04T05:27:21.280847331Z","max_per_user_per_stream":{"is_enabled":false,"max_per_user_per_stream":1},"global_cooldown":{"is_enabled":false,"global_cooldown_seconds":1},"redemptions_redeemed_current_stream":null,"cooldown_expires_at":null},"status":"UNFULFILLED"}}}, topic:channel-points-channel-v1.80362534}, type:MESSAGE}
		if msg == "session_welcome":
			session_id = response.payload.session.id
			listen()
			
		if msg == "session_keepalive":
			print("Twitch EventSub still alive")
			
		if msg == "session_reconnect":
			websocket_url = response.payload.session.reconnect_url
			await get_tree().create_timer(3).timeout
			connect_to_twitch()
			
		if msg == "notification":
			var sub = response.payload.subscription.type
			if sub == "channel.channel_points_custom_reward_redemption.add":
				var user = response.payload.event.user_name
				var reward_title = response.payload.event.reward.title
				reward_redemption.emit(user, reward_title)


func send(message : Dictionary) -> void:
	if not websocket_connected():
		print_debug("Twitch EventSub not connected")
		return
		
	var text = JSON.stringify(message)
	print_debug("Twitch EventSub: ", text)
	var err = websocket.send_text(text)
	if err != OK:
		print_debug("Twitch EventSub failed to send message, error: " + str(err))
	
