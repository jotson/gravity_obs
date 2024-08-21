extends RigidBody2D


func _ready() -> void:
	var c = Color.WHITE
	c.r *= randf_range(0.3, 1.0)
	c.g *= randf_range(0.3, 1.0)
	c.b *= randf_range(0.3, 1.0)
	$Sprite2D.modulate = c


func _on_text_edit_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		get_viewport().push_input(event)


func _on_focus_grabber_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		get_viewport().push_input(event)
