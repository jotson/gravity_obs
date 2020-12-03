extends RigidBody2D


const MAX_SPEED = 50


func _ready():
	#var s = rand_range(1.0, 2.0)
	#$AnimatedSprite.scale = Vector2(s, s)

	var pos = OS.window_size / 2
	pos = pos + Vector2(OS.window_size.x/2 + 50, 0).rotated(randf() * 2 * PI)
	position = pos
	
	$AnimatedSprite.speed_scale = rand_range(0.5, 1.0)
	
	angular_velocity = rand_range(-2, 2)
	
	var target = OS.window_size / 2 + Vector2(100, 0).rotated(rand_range(0, 2 * PI))
	linear_velocity = (target - position).normalized() * rand_range(MAX_SPEED/4.0, MAX_SPEED)
	
	$AnimatedSprite.play("default")

	play_random_wave()
	$Person.frame = randi() % 12


func _on_VisibilityNotifier2D_screen_exited():
	die()


func _on_DeathTimer_timeout():
	die()


func die():
	queue_free()


func play_random_wave():
	match randi() % 3:
		0:
			$Person.play("idle")
		1:
			$Person.play("wave1")
		2:
			$Person.play("wave2")
