extends Node

func _ready():
	pass
	
	
func get_webhook():
	var retval = null
	
	var config = ConfigFile.new()
	var err = config.load("user://discord.ini")
	if err == OK:
		retval = config.get_value("discord", "announce_webhook", null)
		
	return retval


func post_announcement():
	var webhook_url = get_webhook()
	if webhook_url == null:
		return

	await (await Twitch.get_channel_info()).completed
	
	var title = "@everyone %s is streaming %s" % [Twitch.broadcaster_name, Twitch.channel_title]
	title += " [LIVE NOW on Twitch](<https://twitch.tv/%s>)"  % [Twitch.broadcaster_login]
	var discord_json = {
		"content": title
	}

	# url: String
	# custom_headers: PoolStringArray = PoolStringArray(  )
	# ssl_validate_domain: bool = true
	# method: Method = 0
	# request_data: String = "")
	var http = HTTPRequest.new()
	add_child(http)

	if http.connect("request_completed", Callable(self, "request_completed").bind(http)) != OK:
		print_debug("Signal not connected")

	var data = JSON.stringify(discord_json)
	var err = http.request(webhook_url, [ "Content-Type: application/json " ], HTTPClient.METHOD_POST, data)
	if err != OK:
		print("Could not make request to Discord: " + str(err))


func request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest):
	http.queue_free()
	
	if response_code != 200:
		print("Discord API Error:", result)
		print("Discord Response code:", response_code)
		print(headers)
		print(body.get_string_from_utf8())
		return
