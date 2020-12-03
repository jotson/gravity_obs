extends Node2D

var pos = Vector2()


func _ready():
	pass


func _process(delta):
	pos.y -= 50 * delta
	$bg.material = $bg.material.duplicate()
	$bg.material.set_shader_param('position', pos)

	if Input.is_action_just_pressed('ui_accept') or Input.is_action_just_pressed('ui_cancel') or Input.is_action_just_pressed('interact'):
		$AnimationPlayer.playback_speed = 20


func _on_AnimationPlayer_animation_finished(_anim_name):
	Game.transition('res://main.tscn')
