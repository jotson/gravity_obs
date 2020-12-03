extends Node

const Explosion = preload("res://booms/explosion.tscn")
const Spark = preload("res://booms/spark.tscn")
const ImpactSmoke = preload("res://booms/impactsmoke.tscn")
const Burst = preload("res://booms/burst-small.tscn")
const Bonus = preload("res://common/bonus.tscn")


func _ready():
	pass # Replace with function body.


func add_child(object, _default=false):
	get_tree().current_scene.call_deferred('add_child', object)


func burst(position):
	var burst = Burst.instance()
	burst.position = position
	add_child(burst)


func explode(position, velocity, delay = 0.0, secondary = false):
	var explosion = Explosion.instance()
	explosion.position = position
	explosion.velocity = velocity
	explosion.delay = delay
	explosion.secondary = secondary
	add_child(explosion)

	return explosion


func spark(position, velocity):
	var spark = Spark.instance()
	spark.position = position
	spark.velocity = -velocity
	add_child(spark)

	return spark
	

func impactsmoke(position):
	var impactsmoke = ImpactSmoke.instance()
	impactsmoke.position = position
	add_child(impactsmoke)
	
	return impactsmoke
	
