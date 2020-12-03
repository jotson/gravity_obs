extends Node2D

func _ready():
	$AnimationPlayer.play('gamepad')
	

func _process(_delta):
	rotation = -get_parent().rotation
	position = Vector2(-48,0).rotated(-get_parent().rotation)


func _on_AnimationPlayer_animation_finished(_anim_name):
	if Game.USING_GAMEPAD:
		$AnimationPlayer.play('gamepad')
	else:
		$AnimationPlayer.play('mouse')
