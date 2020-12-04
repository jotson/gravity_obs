extends Gift

func _ready() -> void:
	# warning-ignore:return_value_discarded
	connect("cmd_no_permission", self, "no_permission")
	# warning-ignore:return_value_discarded
	connect("chat_message", self, "chat_message")
	# warning-ignore:return_value_discarded
	connect("chat_message", Game, "chat_message")
	
	connect_to_twitch()
	yield(self, "twitch_connected")
	
	# Login using your username and an oauth token.
	# You will have to either get a oauth token yourself or use
	# https://twitchapps.com/tokengen/
	# to generate a token with custom scopes.
	var username = ProjectSettings.get("twitch/config/username")
	var token = ProjectSettings.get("twitch/config/token")
	var channel = ProjectSettings.get("twitch/config/channel")
	if token:
		authenticate_oauth(username, token)
		if(yield(self, "login_attempt") == false):
			print("Invalid username or token.")
			return
	join_channel(channel)
	
	add_command("left", self, "command_left")
	add_command("right", self, "command_right")
	add_command("thrust", self, "command_thrust")
	add_command("shoot", self, "command_shoot")
	add_command("destruct", self, "command_destruct")
	
	add_alias("shoot", "zap")
	add_alias("shoot", "bang")
	add_alias("shoot", "kapow")
	add_alias("shoot", "laser")
	add_alias("shoot", "pew")
	add_alias("shoot", "pewpew")
	add_alias("destruct", "selfdestruct")


func chat_message(sender_data, _command, _full_message):
	var username = sender_data.user
	Game.add_ship(username)


func command_left(cmd_info : CommandInfo):
	var username = cmd_info.sender_data.user
	Game.command(username, "left")
	

func command_right(cmd_info : CommandInfo):
	var username = cmd_info.sender_data.user
	Game.command(username, "right")
	
	
func command_thrust(cmd_info : CommandInfo):
	var username = cmd_info.sender_data.user
	Game.command(username, "thrust")
	
	
func command_shoot(cmd_info : CommandInfo):
	var username = cmd_info.sender_data.user
	Game.command(username, "shoot")
	
	
func command_destruct(cmd_info : CommandInfo):
	var username = cmd_info.sender_data.user
	Game.command(username, "destruct")
	
	
