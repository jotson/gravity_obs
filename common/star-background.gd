extends Sprite

var pos = Vector2(0,0)
export var speed = Vector2(0,0)


func _ready():
	randomize()
	if speed.length() == 0:
		speed = Vector2(rand_range(50,200), 0).rotated(randf()*2*PI)


func _process(delta):
	pos += speed * delta
	material.set_shader_param('position', pos)
