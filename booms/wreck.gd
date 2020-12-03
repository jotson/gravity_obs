extends Node2D

func _ready():
	$sparks.one_shot = true
	pass


func _on_Timer_timeout():
	$sparks.position = Vector2(randi() % 16, 0).rotated(randf() * 2 * PI)
	$sparks.emitting = true

	$Timer.wait_time = randf() * 2.0 + 0.5
	$Timer.start()
