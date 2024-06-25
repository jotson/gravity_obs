extends Node

var WINDOW_W = ProjectSettings.get("display/window/size/viewport_width")
var WINDOW_H = ProjectSettings.get("display/window/size/viewport_height")

const SETTINGS_FILE = "user://twitch.ini"

func set_transparent(value : bool):
	get_tree().get_root().set_transparent_background(value)
	
	
func get_saved_channel():
	var channel = null
	var config = ConfigFile.new()
	if config.load(SETTINGS_FILE) == OK:
		# authorized login for reading and chatting
		channel = config.get_value("twitch", "channel", null)

	return channel
	
	
func get_saved_token():
	var token = null
	var config = ConfigFile.new()
	if config.load(SETTINGS_FILE) == OK:
		token = config.get_value("twitch", "token", null)

	return token


func save_channel(channel):	
	var config = ConfigFile.new()
	config.load(SETTINGS_FILE)
	config.set_value("twitch", "channel", channel)
	config.save(SETTINGS_FILE)

	
func _input(_event):
	if Input.is_action_just_pressed("disconnect"):
		Twitch.websocket.close()
		TwitchPS.websocket.close()
		OBS.websocket.close()


func add(object: Node):
	get_tree().current_scene.call_deferred('add_child', object)


func random_position():
	var pos = Vector2(randf_range(64,WINDOW_W-64), randf_range(64,WINDOW_H-64))
	return pos


func get_count(message, needle):
	var MAX = 5
	var count = 0
	var n = message.find(needle)
	while n >= 0 and count < MAX:
		count += 1
		n = message.findn(needle, n+1)
	return count

