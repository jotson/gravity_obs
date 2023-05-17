extends RigidBody2D

func _ready():
	angular_velocity = randf_range(-PI*3,PI*3)
	$deathTimer.wait_time += randf_range(-0.2,0.2)
	$Sprite2D.scale = Vector2(0.5, 0.5)
	$CollisionShape2D.scale = Vector2(0.2, 0.2)
	var max_scale = Vector2(1.0,1.0)
	var starting_color = $Sprite2D.modulate
	var ending_color = Color(0,0,0,0)
	$Tween.interpolate_property($distortion, 'modulate', Color(1,1,1,0), Color(1,1,1,1), $deathTimer.wait_time/4, Tween.TRANS_SINE, Tween.EASE_IN_OUT, $deathTimer.wait_time/8)
	$Tween.interpolate_property($Sprite2D, 'scale', Vector2(0.1,0.1), max_scale, $deathTimer.wait_time/4 * 2, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.interpolate_property($Sprite2D, 'scale', max_scale, Vector2(0,0), $deathTimer.wait_time/4 * 2, Tween.TRANS_SINE, Tween.EASE_IN_OUT, $deathTimer.wait_time/4 * 2)
	$Tween.interpolate_property($Sprite2D, 'modulate', starting_color, Color(1,1,1,1), $deathTimer.wait_time/8, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.start()


func _on_deathTimer_timeout():
	queue_free()
