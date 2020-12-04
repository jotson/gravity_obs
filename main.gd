extends Node2D


func _ready():
	$roundTimer.start()
	
	# warning-ignore:return_value_discarded
	Game.connect("state_changed", self, "state_changed")


func _physics_process(_delta):
	if Game.state == Game.STATE.WAITING:
		$roundCountdown.text = "GET READY! Waiting for players..."
	
	if Game.state == Game.STATE.PLAYING:
		$roundCountdown.text = "Time left: " + str(round($roundTimer.time_left))

	if Game.state == Game.STATE.COOLDOWN:
		$roundCountdown.text = "Next round starting in %d..." % int($cooldownTimer.time_left)


func _on_roundTimer_timeout():
	Game.reset_players()


func state_changed():
	if Game.state == Game.STATE.COOLDOWN:
		$cooldownTimer.start()
		if Game.last_winner:
			$lastWinner.text = "%s won with %d kills" % [Game.last_winner, Game.high_score]
		else:
			$lastWinner.text = ""
		$lastWinner.show()
		$lastWinner/AnimationPlayer.play("default")
	
	if Game.state == Game.STATE.PLAYING:
		$roundTimer.start()


func _on_cooldownTimer_timeout():
	Game.start_round()
