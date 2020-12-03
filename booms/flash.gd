extends Sprite


func _ready():
	var viewport_size = get_viewport().size
	var my_size = texture.get_size()

	scale = viewport_size/my_size


func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()
