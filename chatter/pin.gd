extends StaticBody2D


func _ready() -> void:
	var c = Color.WHITE
	c.r *= randf_range(0.3, 1.0)
	c.g *= randf_range(0.3, 1.0)
	c.b *= randf_range(0.3, 1.0)
	$Sprite2D.modulate = c
	

func pin(body):
	$PinJoint2D.node_b = body.get_path()
