extends Particles2D

func _ready():
	pass


func off():
	emitting = false
	

func on():
	emitting = true


func _physics_process(_delta):
	global_rotation = 0
