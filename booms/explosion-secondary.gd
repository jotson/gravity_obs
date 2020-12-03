extends Node2D

var delay = 0.0


func _ready():
	if delay == 0:
		delay = 0.001
	$Timer.wait_time = delay
	$Timer.one_shot = true
	$Timer.start()


func explode():
	#$explosionSfx.play()
	$explosion.rotation = randf() * 2 * PI
	$AnimationPlayer.play('default')


func die():
	queue_free()
