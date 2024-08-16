extends RigidBody2D


func _ready() -> void:
	var c = Color.WHITE
	c.r *= randf_range(0.3, 1.0)
	c.g *= randf_range(0.3, 1.0)
	c.b *= randf_range(0.3, 1.0)
	$Sprite2D.modulate = c


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
