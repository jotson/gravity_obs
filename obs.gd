extends Node

var websocket : WebSocketPeer = WebSocketPeer.new()
var websocket_state = -1

enum WebSocketOpCode {
	Hello = 0,
	Identify = 1,
	Identified = 2,
	Reidentify = 3,
	Event = 5,
	Request = 6,
	RequestResponse = 7,
	RequestBatch = 8,
	RequestBatchResponse = 9,
}

enum WebSocketCloseCode {
	# Internal only
	DontClose = 0,
	# Reserved
	UnknownReason = 4000,
	# The server was unable to decode the incoming websocket message
	MessageDecodeError = 4002,
	# A data key is missing but required
	MissingDataKey = 4003,
	# A data key has an invalid type
	InvalidDataKeyType = 4004,
	# The specified `op` was invalid or missing
	UnknownOpCode = 4005,
	# The client sent a websocket message without first sending `Identify` message
	NotIdentified = 4006,
	# The client sent an `Identify` message while already identified
	AlreadyIdentified = 4007,
	# The authentication attempt (via `Identify`) failed
	AuthenticationFailed = 4008,
	# The server detected the usage of an old version of the obs-websocket protocol.
	UnsupportedRpcVersion = 4009,
	# The websocket session has been invalidated by the obs-websocket server.
	SessionInvalidated = 4010,
}

enum EventSubscription {
	# Set subscriptions to 0 to disable all events
	None = 0,
	# Receive events in the `General` category
	General = (1 << 0),
	# Receive events in the `Config` category
	Config = (1 << 1),
	# Receive events in the `Scenes` category
	Scenes = (1 << 2),
	# Receive events in the `Inputs` category
	Inputs = (1 << 3),
	# Receive events in the `Transitions` category
	Transitions = (1 << 4),
	# Receive events in the `Filters` category
	Filters = (1 << 5),
	# Receive events in the `Outputs` category
	Outputs = (1 << 6),
	# Receive events in the `Scene Items` category
	SceneItems = (1 << 7),
	# Receive events in the `MediaInputs` category
	MediaInputs = (1 << 8),
	# Receive all event categories
	All = (1<<0 | 1<<1 | 1<<2 | 1<<3 | 1<<4 | 1<<5 | 1<<6 | 1<<7 | 1<<8),
	# InputVolumeMeters event (high-volume)
	InputVolumeMeters = (1 << 9),
	# InputActiveStateChanged event (high-volume)
	InputActiveStateChanged = (1 << 10),
	# InputShowStateChanged event (high-volume)
	InputShowStateChanged = (1 << 11),
}

enum RequestStatus {
	Unknown = 0,

	# For internal use to signify a successful parameter check
	NoError = 10,
	Success = 100,

	# The `requestType` field is missing from the request data
	MissingRequestType = 203,
	# The request type is invalid or does not exist
	UnknownRequestType = 204,
	# Generic error code (comment required)
	GenericError = 205,

	# A required request parameter is missing
	MissingRequestParameter = 300,
	# The request does not have a valid requestData object.
	MissingRequestData = 301,

	# Generic invalid request parameter message (comment required)
	InvalidRequestParameter = 400,
	# A request parameter has the wrong data type
	InvalidRequestParameterType = 401,
	# A request parameter (float or int) is out of valid range
	RequestParameterOutOfRange = 402,
	# A request parameter (string or array) is empty and cannot be
	RequestParameterEmpty = 403,
	# There are too many request parameters (eg. a request takes two optionals, where only one is allowed at a time)
	TooManyRequestParameters = 404,

	# An output is running and cannot be in order to perform the request (generic)
	OutputRunning = 500,
	# An output is not running and should be
	OutputNotRunning = 501,
	# An output is paused and should not be
	OutputPaused = 502,
	# An output is disabled and should not be
	OutputDisabled = 503,
	# Studio mode is active and cannot be
	StudioModeActive = 504,
	# Studio mode is not active and should be
	StudioModeNotActive = 505,

	# The resource was not found
	ResourceNotFound = 600,
	# The resource already exists
	ResourceAlreadyExists = 601,
	# The type of resource found is invalid
	InvalidResourceType = 602,
	# There are not enough instances of the resource in order to perform the request
	NotEnoughResources = 603,
	# The state of the resource is invalid. For example, if the resource is blocked from being accessed
	InvalidResourceState = 604,
	# The specified input (obs_source_t-OBS_SOURCE_TYPE_INPUT) had the wrong kind
	InvalidInputKind = 605,

	# Creating the resource failed
	ResourceCreationFailed = 700,
	# Performing an action on the resource failed
	ResourceActionFailed = 701,
	# Processing the request failed unexpectedly (comment required)
	RequestProcessingFailed = 702,
	# The combination of request parameters cannot be used to perform an action
	CannotAct = 703,
}

var obs_port = 4455
var obs_pass = ""

func _ready():
	var config = ConfigFile.new()
	var err = config.load("user://obs.ini")
	if err == OK:
		obs_port = config.get_value("obs", "port", null)
		obs_pass = config.get_value("obs", "password", null)


func update_socket_state(state):
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
	return websocket.get_ready_state() == WebSocketPeer.STATE_OPEN


func connect_to_obs():
	# See https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md#connection-steps
	# This might be for a different version of OBS websocket than mine
	if websocket_connected():
		websocket.close()
	var err = websocket.connect_to_url("ws://localhost:%s" % [obs_port])
	print("Connecting to OBS...")
	if err != OK:
		print("OBS error: " + str(err))


func connection_established():
	print("OBS connection established")
	upgrade_connection()


func connection_closed(_clean_close : bool):
	print("Disconnected from OBS")
	

func connection_error():
	print("OBS connection error")
	
	
func upgrade_connection():
	# This might be for a different version of OBS websocket than mine
	print("OBS upgrade connection")

	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.connect("request_completed", Callable(self, "upgrade_request_completed").bind(http)) != OK:
		print_debug("Signal not connected")
	
	var headers = [ "Sec-WebSocket-Protocol: obswebsocket.json" ]
	var err = http.request("http://localhost:%s" % [obs_port], headers)
	if err != OK:
		print("OBS error upgrading connection " + str(err))


func upgrade_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, _body: PackedByteArray, http: HTTPRequest):
	http.queue_free()
	
#	if response_code != 200:
#		print("OBS API Error:", result)
#		print("OBS Response code:", response_code)
#		print(headers)
#		print(body.get_string_from_utf8())
#		return
	
	
func hello(challenge, salt):
	# This might be for a different version of OBS websocket than mine
	prints("OBS hello", challenge, salt)
	
	# See https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md
	var auth = obs_pass + salt
	auth = Marshalls.raw_to_base64(auth.sha256_buffer())
	auth = auth + challenge
	auth = Marshalls.raw_to_base64(auth.sha256_buffer())
	
	send({
		"op": WebSocketOpCode.Identify,
		"d": {
			"rpcVersion": 1,
			"eventSubscriptions": EventSubscription.All,
			"authentication": auth
		}
	})


func data_received() -> void:
	var data : String = websocket.get_peer(1).get_packet().get_string_from_utf8()
	if data:
		var test_json_conv = JSON.new()
		test_json_conv.parse(data)
		var response : Dictionary = test_json_conv.get_data()
		print_debug("OBS: ", response)

		if response.has("error"):
			prints("OBS error:", response.error)
			
		if response.has("op"):
			if response.op == WebSocketOpCode.Hello:
				hello(response.d.authentication.challenge, response.d.authentication.salt)
				
			if response.op == WebSocketOpCode.Event:
				if response.d.eventType == "StreamStateChanged" and response.d.eventData.outputState == "OBS_WEBSOCKET_OUTPUT_STARTING":
					print("Stream STARTED!")
					Discord.post_announcement()
		

func send(message : Dictionary) -> void:
	if not websocket_connected():
		print_debug("Not connected")
		return
		
	websocket.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	var text = JSON.stringify(message)
	print_debug(text)
	var err = websocket.get_peer(1).put_packet(text.to_utf8_buffer())
	if err != OK:
		print_debug("Failed to send message, error: " + str(err))
	
