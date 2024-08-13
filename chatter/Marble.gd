extends RigidBody2D

var FLOOR = Helper.WINDOW_H
var first = false
var velocity: Vector2
const GRAVITY = 50.0
var t = 6.0
var last_say: float = 0.0


func _ready():
	position = Helper.random_position()
	
	var colors = []
	colors.append(Color("#e43b44")) # red
	colors.append(Color("#63c74d")) # green
	colors.append(Color("#0095e9")) # blue
	var c = colors[randi() % colors.size()]
	
	if first:
		c = Color("#f77622") # special orange
	
	material = material.duplicate()
	material.set_shader_parameter("color", c)
	
	velocity = Vector2.ZERO

	$head/nametag.hide()


func _process(_delta):
	#$head/nametag.global_position = global_position + Vector2(-49, -25)
	$head/nametag.global_rotation = 0
	$speechBubble.global_rotation = 0
	
	
func _physics_process(delta):
	if position.y > FLOOR:
		transform = Transform2D(0, Helper.random_position())
	
	var elapsed: float = (Time.get_ticks_msec() - last_say)/1000.0 - 180.0
	if elapsed >= 0.0 and elapsed <= 10.0:
		var s = 1.0 - elapsed / 30.0
		resize.call_deferred(Vector2.ONE * s)
		
	t -= delta
	if t <= 0:
		t = randf() * 10.0 + 10.0
		apply_central_impulse(Vector2(0, -1000).rotated(randf() * PI/2 - PI/4))


func resize(sz: Vector2) -> void:
	mass = 3.0 * sz.x
	$head.scale = sz
	$speechBubble.scale = sz
	$CollisionShape2D.shape.radius = 48 * sz.x
	

func say(message:String):
	$speechBubble/speechBubble.text = message
	$speechBubble/AnimationPlayer.play("speak")
	if last_say > 1000:
		apply_central_impulse(Vector2(0, -3000).rotated(randf() * PI/2 - PI/4))
	resize.call_deferred(Vector2.ONE)
	last_say = Time.get_ticks_msec()
	
		
func add_head(image:Image = null, login:String = "", first_chatter:bool = false):
	$head/nametag/nametag.text = login
	if image:
		var c: Color = image.get_pixel(1, 1)
		$head/helmet/Face.hide()
		$head/Bg.modulate = c
		$head/Bg.modulate.a = 1.0
		var tex = ImageTexture.create_from_image(image)
		var s = Sprite2D.new()
		s.texture = tex
		s.scale *= 0.2
		s.show_behind_parent = true
		$head/helmet.add_child(s)
		
	self.first = first_chatter
