extends RigidBody2D

const ENTITY_TYPE_ID = 'debris'

var Secondary = preload("res://booms/explosion-secondary.tscn")
var secondary = false
var small = false


func _ready():
	if small:
		$Sprite.frame = round(rand_range(4, 11))
	else:
		$Sprite.frame = randi() % ($Sprite.vframes * $Sprite.hframes)

	angular_velocity = rand_range(-PI*6, PI*6)
	$deathTimer.wait_time += rand_range(-0.5, 0.5)
	if secondary:
		$deathTimer.wait_time = rand_range(0.1, 1.0)
	$deathTimer.start()

	var t = Tween.new()
	add_child(t)
	t.interpolate_property($Sprite, "modulate",
		Color(1,1,1,1), Color("#000099ff"),
		$deathTimer.wait_time,
		Tween.TRANS_QUINT, Tween.EASE_IN)
	t.start()


func _on_deathTimer_timeout():
	die()


func hurt(_amount):
	die()
	return true


func die():
	if secondary and randf() < 0.12:
		# Secondary explosion
		var explosion = Secondary.instance()
		explosion.position = position
		Helper.add_child(explosion)

	queue_free()
