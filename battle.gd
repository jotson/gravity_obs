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


func _ready():
	idle()

	# warning-ignore:return_value_discarded
	Twitch.connect("chat_message", self, "twitch_chat")
	# warning-ignore:return_value_discarded
	Twitch.connect("twitch_disconnected", self, "twitch_disconnect")


func _physics_process(_delta):
	if state == STATE.PLAYING:
		$roundCountdown.text = "Time left: " + str(round($roundTimer.time_left)) + " - Chat to join!"

	active_players = get_tree().get_nodes_in_group("player").size()
	if active_players >= 2 and state == STATE.WAITING:
		last_winner = ""
		high_score = 0
		change_state(STATE.PLAYING)
		
	ai()


func change_state(new_state):
	state = new_state
	
	if state == STATE.IDLE:
		$roundCountdown.text = ""
		$lastWinner.hide()

	if state == STATE.WAITING:
		$roundCountdown.text = "GET READY! Waiting for players..."
		
	if state == STATE.COOLDOWN:
		$cooldownTimer.start()
		if last_winner:
			$lastWinner.text = "%s won with %d kills" % [last_winner, high_score]
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
	if state == STATE.COOLDOWN or state == STATE.IDLE:
		return
		
	command = command.to_lower()
	
	var username = sender_data.user
	add_ship(username)
	yield(get_tree(), 'idle_frame')
	yield(get_tree(), 'idle_frame')
	yield(get_tree(), 'idle_frame')

	if players.has(username):
		var ship = players[username].ship
		if ship != null and ship.get_ref():
			var message = full_message.split(" ")
			message.remove(0)
			message.remove(0)
			message.remove(0)
			message = message.join(" ")
			message = message.substr(1)
			ship.get_ref().say(message)
#		if OS.get_ticks_msec() - players[username].last_action < ACTION_THROTTLE:
#			return
#		players[username].last_action = OS.get_ticks_msec()
#		if ship != null and ship.get_ref() and ship.get_ref().alive:
#			match(command):
#				"l":
#					ship.get_ref().turn_left(0.3)
#					ship.get_ref().shoot()
#				"r":
#					ship.get_ref().turn_right(0.3)
#					ship.get_ref().shoot()
#				"t":
#					ship.get_ref().thrust(10.0)
#					ship.get_ref().shoot()
#				"s":
#					ship.get_ref().shoot(5)
#				"destruct":
#					ship.get_ref().self_destruct()


func idle():
	change_state(STATE.IDLE)


func start_round():
	change_state(STATE.WAITING)


func add_ship(username):
	if state == STATE.COOLDOWN or state == STATE.IDLE:
		return
		
	yield(get_tree(), 'idle_frame')
	
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
			ship = Ship.instance()
			ship.position = Helper.random_position()
			ship.rotation = -PI/2
			ship.username = username
			ship.color = players[username].color
			ship.kills = players[username].kills
			add_child(ship)
			players[username].ship = weakref(ship)
			prints("Respawn", username)
	else:
		var ship = Ship.instance()
		ship.position = Helper.random_position()
		ship.rotation = -PI/2
		ship.username = username
		ship.color = colors[randi() % colors.size()]
		ship.kills = 0
		add_child(ship)
		
		players[username] = {
			"last_action": OS.get_ticks_msec(),
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


func ai():
	for username in players.keys():
		var ship = players[username].ship
		if OS.get_ticks_msec() - players[username].last_action < IDLE_TIMEOUT:
			continue
		if ship != null and ship.get_ref() and ship.get_ref().alive:
			ship.get_ref().ai()


func _on_roundTimer_timeout():
	reset_players()
	

func _on_cooldownTimer_timeout():
	idle()


func burst(position):
	var burst = Burst.instance()
	burst.position = position
	add_child(burst)


func explode(position, velocity, delay = 0.0, secondary = false):
	var explosion = Explosion.instance()
	explosion.position = position
	explosion.velocity = velocity
	explosion.delay = delay
	explosion.secondary = secondary
	add_child(explosion)

	return explosion


func spark(position, velocity):
	var spark = Spark.instance()
	spark.position = position
	spark.velocity = -velocity
	add_child(spark)

	return spark
	

func impactsmoke(position):
	var impactsmoke = ImpactSmoke.instance()
	impactsmoke.position = position
	add_child(impactsmoke)
	
	return impactsmoke
