extends Gift

func _ready() -> void:
# warning-ignore:return_value_discarded
	connect("cmd_no_permission", self, "no_permission")
# warning-ignore:return_value_discarded
	connect("unhandled_message", self, "unhandled_message")
# warning-ignore:return_value_discarded
	connect("chat_message", self, "chat_message")
	
	connect_to_twitch()
	yield(self, "twitch_connected")
	
	# Login using your username and an oauth token.
	# You will have to either get a oauth token yourself or use
	# https://twitchapps.com/tokengen/
	# to generate a token with custom scopes.
	var username = ProjectSettings.get("twitch/config/username")
	var token = ProjectSettings.get("twitch/config/token")
	if token:
		authenticate_oauth(username, token)
		if(yield(self, "login_attempt") == false):
			print("Invalid username or token.")
			return
	join_channel("gmhikaru")
	
	# Adds a command with a specified permission flag.
	# All implementations must take at least one arg for the command info.
	# Implementations that recieve args requrires two args,
	# the second arg will contain all params in a PoolStringArray
	# This command can only be executed by VIPS/MODS/SUBS/STREAMER
	add_command("test", self, "command_test")
	
	# Adds a command alias
	add_alias("test","test1")


# Check the CommandInfo class for the available info of the cmd_info.
func command_test(cmd_info : CommandInfo) -> void:
	prints("Test!", cmd_info)


func unhandled_message(_message, _tags):
	#prints(message, tags)
	pass


func chat_message(sender_data, _command):
	var username = sender_data.user
	Game.add_ship(username)
