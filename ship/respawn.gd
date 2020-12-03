extends Node2D

signal done


func _ready():
	pass


func _on_AnimationPlayer_animation_finished(_anim_name):
	emit_signal("done")
	queue_free()
