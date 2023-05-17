extends Node2D

func _ready():
	$Sprite2D.frame = randi() % ($Sprite2D.vframes * $Sprite2D.hframes)
	pass


func _on_AnimationPlayer_animation_finished(_anim_name):
	queue_free()
