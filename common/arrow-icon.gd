extends StaticBody2D

const ENTITY_TYPE_ID = 'arrow'


func _ready():
	pass


func prepare_for_gameplay():
	return
	
	
func prepare_for_editor():
	return


func editor_transform(rot, pos):
	global_rotation = rot
	global_position = pos
