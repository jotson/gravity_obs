extends Node2D

func _process(_delta: float) -> void:
	if $Timer.time_left < 5:
		$fire.emitting = false


func _on_Timer_timeout():
	queue_free()
