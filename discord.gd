extends Node

var http : HTTPRequest = null
var webhook_url = null


func _ready():
	http = HTTPRequest.new()
	add_child(http)
	webhook_url = get_webhook()
	
	
func get_webhook():
	var retval = null
	
	var config = ConfigFile.new()
	var err = config.load("user://discord.ini")
	if err == OK:
		retval = config.get_value("discord", "announce_webhook", null)
		
	return retval


func post_announcement():
	if webhook_url == null:
		return
		
	var title = "jotson is streaming Gravity Ace game dev with Godot Engine! [LIVE NOW on Twitch](<https://twitch.tv/jotson>)"
	var discord_json = {
		"content": title
	}

	# url: String
	# custom_headers: PoolStringArray = PoolStringArray(  )
	# ssl_validate_domain: bool = true
	# method: Method = 0
	# request_data: String = "")
	var data = JSON.print(discord_json)
	var err = http.request(webhook_url, [ "Content-Type: application/json " ], false, HTTPClient.METHOD_POST, data)
	if err != OK:
		print("Could not make request to Discord: " + str(err))
