extends RigidBody2D

const ENTITY_TYPE_ID = 'debris'

var Secondary = preload("res://booms/explosion-secondary.tscn")
var secondary = false
var small = false


func _ready():
	if small:
		$Sprite2D.frame = round(randf_range(4, 11))
	else:
		$Sprite2D.frame = randi() % ($Sprite2D.vframes * $Sprite2D.hframes)

	angular_velocity = randf_range(-PI*6, PI*6)
	$deathTimer.wait_time += randf_range(-0.5, 0.5)
	if secondary:
		$deathTimer.wait_time = randf_range(0.1, 1.0)
	$deathTimer.start()

	$Sprite2D.modulate = Color(1,1,1,1)
	var t = create_tween()
	t.tween_property($Sprite2D, "modulate",
		Color("#000099ff"),
		$deathTimer.wait_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	t.start()


func _on_deathTimer_timeout():
	die()


func hurt(_amount):
	die()
	return true


func die():
	if secondary and randf() < 0.12:
		# Secondary explosion
		var explosion = Secondary.instantiate()
		explosion.position = position
		Helper.add_child(explosion)

	queue_free()
