extends Control

const Explosion = preload("res://booms/explosion.tscn")
const Spark = preload("res://booms/spark.tscn")
const ImpactSmoke = preload("res://booms/impactsmoke.tscn")
const Burst = preload("res://booms/burst-small.tscn")
const Ship = preload("res://ship/Ship.tscn")

var players = {}

enum STATE { IDLE, WAITING, PLAYING, COOLDOWN }
var state = STATE.WAITING
var active_players = 0
var last_winner = ""
var high_score = 0

var ACTION_THROTTLE = 500 # Minimum time between actions, millis
var IDLE_TIMEOUT = 100 # Milliseconds until AI takes over player control

signal changed_state


func _ready():
	idle()

	if Twitch.connect("chat_message", Callable(self, "twitch_chat")) != OK:
		print_debug("Signal not connected`")
	if Twitch.connect("twitch_disconnected", Callable(self, "twitch_disconnect")) != OK:
		print_debug("Signal not connected")


func _physics_process(_delta):
	if state == STATE.PLAYING:
		$roundCountdown.text = "Time left: " + str(round($roundTimer.time_left))
		$roundCountdown.text += " -- CHAT to join the BATTLE!"

	active_players = get_tree().get_nodes_in_group("player").size()
	if active_players >= 2 and state == STATE.WAITING:
		last_winner = ""
		high_score = 0
		change_state(STATE.PLAYING)


func change_state(new_state):
	state = new_state
	emit_signal("changed_state", state)
	
	if state == STATE.IDLE:
		$roundCountdown.text = ""
		$lastWinner.hide()

	if state == STATE.WAITING:
		$roundCountdown.text = "GET READY! CHAT to join the BATTLE!"
		
	if state == STATE.COOLDOWN:
		$cooldownTimer.start()
		if last_winner:
			var winner_text = "%s won with %d kills" % [last_winner, high_score]
			$lastWinner.text = winner_text
			Twitch.chat(winner_text)
		else:
			$lastWinner.text = ""
		$lastWinner.show()
		$lastWinner/AnimationPlayer.play("default")
	
	if state == STATE.PLAYING:
		$roundTimer.start()


func twitch_disconnect():
	reset_players()
	players = {}
	idle()


func twitch_chat(sender_data, command : String, full_message : String):
	var username = sender_data.user
	if players.has(username):
		command = command.to_lower()
		var ship = players[username].ship
		if ship != null and ship.get_ref():
			var message = full_message.split(" ")
			message.remove_at(0)
			message.remove_at(0)
			message.remove_at(0)
			message = " ".join(message)
			message = message.substr(1)
			ship.get_ref().say(message)

	if state == STATE.COOLDOWN or state == STATE.IDLE:
		return
		
	add_ship(username)


func idle():
	change_state(STATE.IDLE)


func start_round():
	change_state(STATE.WAITING)


func add_ship(username):
	if state == STATE.COOLDOWN or state == STATE.IDLE:
		return
		
	await get_tree().process_frame
	
	var colors = []
	colors.append(Color("#ffffff"))
	colors.append(Color("#111111"))
	colors.append(Color("#e43b44"))
	colors.append(Color("#0095e9"))
	colors.append(Color("#feae34"))
	colors.append(Color("#fe61e1"))
	colors.append(Color("#5a6988"))
	colors.append(Color("#2ce8f5"))
	colors.append(Color("#fee761"))
	colors.append(Color("#e4a672"))
	colors.append(Color("#265c42"))
	
	if players.has(username):
		var ship = players[username].ship
		if ship == null or ship.get_ref() == null:
			ship = Ship.instantiate()
			ship.position = Helper.random_position()
			ship.rotation = -PI/2
			ship.username = username
			ship.color = players[username].color
			ship.kills = players[username].kills
			add_child(ship)
			players[username].ship = weakref(ship)
			prints("Respawn", username)
	else:
		var ship = Ship.instantiate()
		ship.position = Helper.random_position()
		ship.rotation = -PI/2
		ship.username = username
		ship.color = colors[randi() % colors.size()]
		ship.kills = 0
		add_child(ship)
		
		players[username] = {
			"last_action": Time.get_ticks_msec(),
			"color": ship.color,
			"ship": weakref(ship),
			"kills": 0,
			"deaths": 0
		}
		
		prints("New player", username)


func kill_ship(killer, victim):
	if players.has(killer):
		prints(killer, "killed", victim)
		players[killer].kills += 1
		if players[killer].kills > high_score:
			high_score = players[killer].kills
			last_winner = killer
		var ship = players[killer].ship
		if ship != null and ship.get_ref():
			ship.get_ref().kills = players[killer].kills
		
	if players.has(victim):
		players[victim].deaths += 1

		
func reset_players():
	for key in players.keys():
		players[key].kills = 0
		players[key].deaths = 0

	for node in get_tree().get_nodes_in_group("player"):
		node.queue_free()
		
	for node in get_tree().get_nodes_in_group("transient"):
		node.queue_free()
			
	active_players = 0
	change_state(STATE.COOLDOWN)


func _on_roundTimer_timeout():
	reset_players()
	

func _on_cooldownTimer_timeout():
	idle()


@warning_ignore("shadowed_variable_base_class")
func burst(position):
	@warning_ignore("shadowed_variable")
	var burst = Burst.instantiate()
	burst.position = position
	add_child(burst)


@warning_ignore("shadowed_variable_base_class")
func explode(position, velocity, delay = 0.0, secondary = false):
	var explosion = Explosion.instantiate()
	explosion.position = position
	explosion.velocity = velocity
	explosion.delay = delay
	explosion.secondary = secondary
	add_child(explosion)

	return explosion


@warning_ignore("shadowed_variable_base_class")
func spark(position, velocity):
	@warning_ignore("shadowed_variable")
	var spark = Spark.instantiate()
	spark.position = position
	spark.velocity = -velocity
	add_child(spark)

	return spark
	

@warning_ignore("shadowed_variable_base_class")
func impactsmoke(position):
	@warning_ignore("shadowed_variable")
	var impactsmoke = ImpactSmoke.instantiate()
	impactsmoke.position = position
	add_child(impactsmoke)
	
	return impactsmoke
