extends RigidBody2D

var texture:
	set(value):
		texture = value
		$Timer.wait_time = randf_range(3,8)
		$Timer.start()
		apply_central_impulse(randf_range(500, 1200) * Vector2(0,-1).rotated(randf_range(deg_to_rad(-30), deg_to_rad(30))))
		$Sprite2D.texture = texture
