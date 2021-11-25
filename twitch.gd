extends Gift

func _ready():
	pass


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
	
	yield(get_tree().create_timer(2.0), "timeout")
