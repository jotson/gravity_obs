extends Node2D

export var MAX_RANGE = 1000


func _ready():
	pass


func _physics_process(_delta):
	var player = Game.player
	var parent = get_parent()

	var distance_to_player = MAX_RANGE + 1

	if player and !player.is_inside_tree():
		return

	if player and not player.visible:
		hide()
		return

	if player and not Game.is_edit_mode():
		var angle = parent.position.angle_to_point(player.position)
		$Sprite.global_position = player.global_position
		$Sprite.rotation = angle - parent.rotation
		distance_to_player = parent.position.distance_to(player.position)

	if distance_to_player > MAX_RANGE:
		hide()
	else:
		show()


func _on_waypoint_visibility_changed():
	if visible:
		var start_color = modulate
		var end_color = modulate
		start_color.a = 0
		$Tween.interpolate_property($Sprite, 'modulate', start_color, end_color, 0.2, Tween.TRANS_SINE, Tween.EASE_IN)
		$Tween.interpolate_property($Sprite, 'scale', Vector2(3,3), Vector2(2,2), 0.2, Tween.TRANS_SINE, Tween.EASE_IN)
		$Tween.interpolate_property($Sprite, 'scale', Vector2(2,2), Vector2(1,1), 0.3, Tween.TRANS_BOUNCE, Tween.EASE_OUT, 0.2)
		$Tween.start()

		$AnimationPlayer.play('appear')


func disable():
	set_physics_process(false)
	call_deferred('hide')


func enable():
	set_physics_process(true)
	show()
