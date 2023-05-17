extends Node2D


func _ready():
	hide()
	$spawnTimer.wait_time = randf()
	$spawnTimer.start()


func _on_spawnTimer_timeout():
	show()
	$AnimatedSprite2D.play("default")
	$AnimationPlayer.play("default")
