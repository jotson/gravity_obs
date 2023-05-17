extends Node2D

var Debris = preload("debris.tscn")

var delay = 0.0
var velocity = Vector2()
var secondary = false


func _ready():
	if delay == 0:
		delay = 0.001
	$Timer.wait_time = delay
	$Timer.one_shot = true
	$Timer.start()


func explode():
	Battle.burst(position)
	Battle.spark(position, Vector2.ZERO)

	#$explosionSfx.play()

	var debris_amount = 6

	for _i in range(debris_amount):
		var obj = Debris.instantiate()
		obj.secondary = secondary
		obj.position = position
		obj.global_position = position
		obj.linear_velocity = velocity + Vector2(randf_range(-200,200), randf_range(-200,200))
		Helper.add_child(obj)

	$explosion.rotation = randf() * 2 * PI
	$AnimationPlayer.play('default')


func die():
	queue_free()
