extends RigidBody2D


func _integrate_forces(_state: PhysicsDirectBodyState2D) -> void:
	linear_velocity = Vector2.ZERO
	global_position = get_global_mouse_position()
	

func pin(body):
	$PinJoint2D.node_b = body.get_path()
	

func unpin():
	$PinJoint2D.node_b = ""
	
