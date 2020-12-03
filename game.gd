extends Node

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

signal state_changed

func _ready():
	start_round()


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
	colors.append(Color("#000000"))
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
		players[username].updated = OS.get_ticks_msec()
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
			"updated": OS.get_ticks_msec(),
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
	last_winner = ""
	high_score = 0
	
	for key in players.keys():
		if players[key].kills >= high_score:
			high_score = players[key].kills
			last_winner = key
			
		players[key].kills = 0
		players[key].deaths = 0

	for node in get_tree().get_nodes_in_group("player"):
		node.queue_free()
		
	for node in get_tree().get_nodes_in_group("transient"):
		node.queue_free()
			
	active_players = 0
	state = STATE.COOLDOWN
	emit_signal("state_changed")
