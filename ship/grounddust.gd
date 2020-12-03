extends Node2D

var emitting = false setget set_emitting, is_emitting
var distance = 0.0 setget set_distance, get_distance

func _ready():
	pass


func set_distance(new_distance):
	distance = new_distance + 1.0

	#var speed = min(2000 / distance, 80)
	#var pm = $rocks.process_material
	#pm.initial_velocity = speed


func get_distance():
	return distance


func set_emitting(value):
	emitting = value
	$dust.emitting = value
	$cloudL.emitting = value
	$cloudR.emitting = value


func is_emitting():
	return emitting
