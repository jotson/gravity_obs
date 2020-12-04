extends Control

const Explosion = preload("res://booms/explosion.tscn")
const Spark = preload("res://booms/spark.tscn")
const ImpactSmoke = preload("res://booms/impactsmoke.tscn")
const Burst = preload("res://booms/burst-small.tscn")
const Bonus = preload("res://common/bonus.tscn")

const Ship = preload("res://ship/Ship.tscn")

var players = {}

enum STATE { WAITING, PLAYING, COOLDOWN }
var state = STATE.WAITING
var active_players = 0
var last_winner = ""
var high_score = 0

var ACTION_THROTTLE = 500 # Minimum time between actions, millis
var IDLE_TIMEOUT = 5000 # Milliseconds until AI takes over player control

signal state_changed

func _ready():
	$console.hide()
	
	start_round()


func _input(_event):
	if Input.is_action_just_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
		
	if Input.is_action_just_pressed("toggle_console"):
		if $console.visible:
			$console.hide()
		else:
			$console.show()
		

func start_round():
	state = STATE.WAITING
	emit_signal("state_changed")


func _physics_process(_delta):
	active_players = get_tree().get_nodes_in_group("player").size()
	
	if active_players >= 2 and state == STATE.WAITING:
		last_winner = ""
		high_score = 0
		state = STATE.PLAYING
		emit_signal("state_changed")
		
	ai()


func add_child(object, _default=false):
	get_tree().current_scene.call_deferred('add_child', object)


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
	

func add_ship(username):
	if state == STATE.COOLDOWN:
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
	
	var width = ProjectSettings.get("display/window/size/width")
	var height = ProjectSettings.get("display/window/size/height")
	if players.has(username):
		var ship = players[username].ship
		if ship == null or ship.get_ref() == null:
			ship = Ship.instance()
			ship.position = Vector2(rand_range(64,width-64), rand_range(64,height-64))
			ship.rotation = -PI/2
			ship.username = username
			ship.color = players[username].color
			ship.kills = players[username].kills
			add_child(ship)
			players[username].ship = weakref(ship)
			prints("Respawn", username)
	else:
		var ship = Ship.instance()
		ship.position = Vector2(rand_range(64,width-64), rand_range(64,height-64))
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
	state = STATE.COOLDOWN
	emit_signal("state_changed")


func command(username, command):
	if players.has(username):
		var ship = players[username].ship
		if OS.get_ticks_msec() - players[username].last_action < ACTION_THROTTLE:
			return
		players[username].last_action = OS.get_ticks_msec()
		if ship != null and ship.get_ref() and ship.get_ref().alive:
			match(command):
				"left": ship.get_ref().turn_left()
				"right": ship.get_ref().turn_right()
				"thrust": ship.get_ref().thrust()
				"shoot": ship.get_ref().shoot()
				"destruct": ship.get_ref().self_destruct()


func ai():
	for username in players.keys():
		var ship = players[username].ship
		if OS.get_ticks_msec() - players[username].last_action < IDLE_TIMEOUT:
			continue
		if ship != null and ship.get_ref() and ship.get_ref().alive:
			ship.get_ref().ai()


func chat_message(ender_data, command, full_message):
	var MAX_LENGTH = 1000
	$console.text += "\n" + full_message
	var text_size = $console.text.length()
	if text_size > MAX_LENGTH:
		$console.text = $console.text.substr(text_size - MAX_LENGTH)
	$console.scroll_vertical = MAX_LENGTH
	$console.cursor_set_line($console.get_line_count())
