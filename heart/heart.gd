extends RigidBody2D

var lifetime: float = 0.0

func _ready():
	$AnimatedSprite2D.play("default")
	$AnimatedSprite2D.frame = randi() % 6
	apply_torque_impulse(randf_range(-1, 1) * 500)


func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime > 10 and linear_velocity.length() <= 0.1:
		queue_free()


func _on_sleeping_state_changed() -> void:
	queue_free()
