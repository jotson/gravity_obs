extends Node2D

@export var MAX_LENGTH = 20
@export var THICKNESS = 3.0

var points = []
var elapsed = 0


func _ready():
	$Line2D.width = THICKNESS


func _physics_process(delta):
	elapsed += delta
	if elapsed > 0.05:
		elapsed = 0
		points.push_front(global_position)
		if points.size() > MAX_LENGTH:
			points.pop_back()

	$Line2D.points = points
	$Line2D.rotation = -get_parent().rotation
	$Line2D.global_position = Vector2.ZERO
