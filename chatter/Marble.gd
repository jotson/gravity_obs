extends RigidBody2D

var FLOOR = Helper.WINDOW_H
var first = false
var velocity: Vector2
const GRAVITY = 50.0
var t = 6.0

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
	
	# warning-ignore:return_value_discarded
	Battle.connect("changed_state", Callable(self, "battle_state"))


func battle_state(state):
	if state == Battle.STATE.WAITING:
		call_deferred("set_gravity_scale", 0)
		apply_central_impulse(Vector2(0, -200).rotated(randf() * PI/2 - PI/4))
	if state == Battle.STATE.IDLE:
		call_deferred("set_gravity_scale", 1)


func _physics_process(delta):
	if position.y > FLOOR:
		transform = Transform2D(0, Helper.random_position())
		
	t -= delta
	if t <= 0:
		t = randf() * 10.0 + 10.0
		apply_central_impulse(Vector2(0, -50).rotated(randf() * PI/2 - PI/4))


func say(message:String):
	$speechBubble.text = message
	$speechBubble/AnimationPlayer.play("speak")
	apply_central_impulse(Vector2(0, -200).rotated(randf() * PI/2 - PI/4))
	
		
func add_head(image:Image = null, login:String = "", first_chatter:bool = false):
	$head/nametag.text = login
	if image:
		var tex = ImageTexture.create_from_image(image)
		
		var s = Sprite2D.new()
		s.texture = tex
		s.scale *= 0.1
		s.show_behind_parent = true
		$head/helmet.add_child(s)	
		
	self.first = first_chatter


func _on_Marble_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		event = event as InputEventMouseButton
		if event.button_index == 1 and event.is_pressed():
			var offset = event.global_position - position
			apply_impulse(-offset.normalized() * 400, offset)
