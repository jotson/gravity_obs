extends Node2D

var velocity = Vector2()


func _ready():
	$Timer.start()
	$GPUParticles2D.rotate(velocity.angle())
	$GPUParticles2D.emitting = true


func _on_Timer_timeout():
	queue_free()
