extends CanvasLayer

signal finished

var pos = Vector2()


func _ready():
	if Game.stats.size() == 0:
		start('Level name', 'The subtext goes here')


func _process(delta):
	pos.x += 2000 * delta
	$bg.material = $bg.material.duplicate()
	$bg.material.set_shader_param('position', pos)

	if Input.is_action_just_pressed('ui_accept') or Input.is_action_just_pressed('ui_cancel') or Input.is_action_just_pressed('interact'):		if $AnimationPlayer.current_animation != "end":
		$ContinueButton.hide()
		$AnimationPlayer.play("end")


func start(text, subtext = ''):
	# This animation also pauses the game after a tiny delay
	# so that the game gets a couple of frames to finish setup
	# after the level is loaded
	find_node('Label1').text = text
	find_node('Label2').text = subtext
	$AnimationPlayer.play("start")
	$AnimationPlayer.queue("loop")


func _on_AnimationPlayer_animation_finished(_anim_name):
	emit_signal('finished')
	queue_free()


func _on_letterbox_tree_exiting():
	get_tree().paused = false


func pause_game():
	get_tree().paused = true
	
