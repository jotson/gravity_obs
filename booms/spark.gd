extends Node2D

var velocity = Vector2()


func _ready():
	$Timer.start()
	$Particles2D.rotate(velocity.angle())
	$Particles2D.emitting = true


func _on_Timer_timeout():
	queue_free()
