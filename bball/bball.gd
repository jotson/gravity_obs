extends Control

var red_score: int = 0
var blue_score: int = 0
var overtime: bool = false
var final: bool = false


func _ready() -> void:
	final = false
	overtime = false
	red_score = 0
	blue_score = 0
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
		Twitch.chat("RED WINS!")
	if blue_score > red_score:
		Twitch.chat("BLUE WINS!")
	
	%SfxGameover.play()
	%SfxAmbience.stop()
	
	var t = create_tween()
	t.tween_callback(queue_free).set_delay(3)


func _on_ball_detector_body_entered(body: Node2D) -> void:
	if not final and body.get("team"):
		%SfxGoal.play()
		%BasketParticles.restart()
		%BasketParticles.emitting = true
		if body.team == "red":
			red_score += 1
		if body.team == "blue":
			blue_score += 1
		if overtime:
			gameover()
