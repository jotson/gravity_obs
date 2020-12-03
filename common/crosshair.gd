extends Sprite


func _ready():
	$AnimationPlayer.play("idle")


func shoot():
	if $AnimationPlayer.current_animation != "firing":
		$AnimationPlayer.play("firing")
		$AnimationPlayer.queue("idle")


func target():
	var dir = (global_position - Game.player.global_position).normalized() * 500
	var angle = Vector2(1,0).angle_to(dir)
	$RayCast2D.global_position = Game.player.global_position
	$RayCast2D.global_rotation = angle

	if $RayCast2D.is_colliding():
		var collider = null
		if $RayCast2D.get_collider():
			collider = weakref($RayCast2D.get_collider())
			#print(collider.get_ref().name)
		# TODO Need to add an "Other" collision layer instead of grouping
		# things in Player (people) and World (asteroids) when they aren't
		# those things
		if $AnimationPlayer.current_animation != "target-ok" and $AnimationPlayer.current_animation != "target-bad":
			if collider and collider.get_ref() and collider.get_ref().is_in_group('friendly'):
				$AnimationPlayer.play("target-bad")
			else:
				$AnimationPlayer.play("target-ok")

			$AnimationPlayer.queue("idle")


#func _draw():
#	if not Game.player:
#		return
#
#	# It's calculated in this weird way because the crosshair is in a canvaslayer
#	draw_set_transform(-global_position + $RayCast2D.global_position, 0, Vector2(1,1))
#	draw_line(Vector2(0,0), $RayCast2D.cast_to.rotated($RayCast2D.global_rotation), Color("00ff00"))
