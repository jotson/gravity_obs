extends Sprite

var random_angle = randf() * PI/8 - PI/16


func _ready():
	rotation = random_angle - get_parent().rotation


func _physics_process(_delta):
	rotation = random_angle - get_parent().rotation
	
