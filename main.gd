extends Node2D

const ASTEROIDS_MAX = 10
const Asteroid = preload("res://asteroid/Asteroid.tscn")
const Ship = preload("res://ship/Ship.tscn")


func _ready():
	var ship = Ship.instance()
	ship.position = Vector2(100,100)
	Game.add_child(ship)
	ship.thrust()
	ship.turn_right()
	pass # Replace with function body.
