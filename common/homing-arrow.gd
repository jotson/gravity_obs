extends Node2D

func _ready():
	pass


func _physics_process(_delta):
	if not Game.player:
		return
		
	var closest_wall = Game.get_nearest_wall_to_player()
	
	rotation = -get_parent().rotation + closest_wall.angle_to_point(global_position)
