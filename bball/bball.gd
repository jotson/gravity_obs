class_name Bball
extends Control

var red_score: int = 0
var blue_score: int = 0
var overtime: bool = false
var final: bool = false

var players: Dictionary


func _ready() -> void:
	final = false
	overtime = false
	red_score = 0
	blue_score = 0
	players = {}
	%ShotClockTimer.wait_time = 180
	%ShotClockTimer.start()
	%SfxAmbience.play()
	

func _process(_delta: float) -> void:
	if final:
		%ShotClock.text = "FINAL"
	elif overtime:
		%ShotClock.text = "OVERTIME"
	else:
		%ShotClock.text = str(int(ceil(%ShotClockTimer.time_left)))
	%RedScore.text = str(red_score)
	%BlueScore.text = str(blue_score)
	

func _on_shot_clock_timer_timeout() -> void:
	if red_score == blue_score:
		sudden_death()
	else:
		gameover()
		

func sudden_death():
	overtime = true
	Twitch.chat("SUDDEN DEATH OVERTIME!!")
	
	
func gameover():
	final = true
	Twitch.chat("GAME OVER!")
	if red_score > blue_score:
		Twitch.chat("RED WINS %d to %d!" % [red_score, blue_score])
	if blue_score > red_score:
		Twitch.chat("BLUE WINS %d to %d!" % [blue_score, red_score])
	
	for username in players:
		var player = players[username]
		Twitch.chat("%s scored %d points %d%% accuracy" % [username, player.goals, player.goals*100/player.shots])
	Twitch.chat("gg")
	
	%SfxGameover.play()
	%SfxAmbience.stop()
	
	var t = create_tween()
	t.tween_callback(queue_free).set_delay(3)


func init_player(username):
	if not players.has(username):
		players[username] = {
			"shots": 0,
			"goals": 0,
		}


func shoot(username):
	if not players.has(username):
		players[username] = {
			"shots": 0,
			"goals": 0,
		}
	players[username].shots += 1
	

func _on_ball_detector_body_entered(body: Node2D) -> void:
	if not final and body.get("team"):
		%SfxGoal.play()
		%BasketParticles.restart()
		%BasketParticles.emitting = true
		var username = body.username
		Twitch.chat("%s scores!" % username)
		init_player(username)
		players[username].goals += 1
		if body.team == "red":
			red_score += 1
		if body.team == "blue":
			blue_score += 1
		if overtime:
			gameover()
