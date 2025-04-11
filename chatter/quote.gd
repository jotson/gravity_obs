extends RigidBody2D


func set_message(message):
	$Label.text = message
	apply_central_impulse(Vector2(100, 0).rotated(randf() * TAU))
	var t = create_tween()
	t.parallel().tween_property($Panel, "modulate:a", 0, 30.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.parallel().tween_property($Label, "modulate:a", 0, 30.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(self.queue_free)
