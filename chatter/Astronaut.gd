extends Node2D

var FLOOR = Helper.WINDOW_H
var first = false
var velocity: Vector2
const GRAVITY = 50.0

func _ready():
	play_animation()

	# Seek to a random starting location on the first
	# animation so that the animations for all people
	# are out of phase
	$AnimationPlayer.seek(randf())
	
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


func _physics_process(delta):
	if position.y > FLOOR:
		position.y = FLOOR
		velocity = Vector2.ZERO
		
	if position.y < FLOOR:
		velocity.y += GRAVITY * delta

	if position.x < 250:
		position.x = 250
		velocity.x = -velocity.x
		
	if position.x > Helper.WINDOW_W-16:
		position.x = Helper.WINDOW_W-16
		velocity.x = -velocity.x
		
	position += velocity * delta

	# Moon jump
	if position.y == FLOOR and randf_range(0, 60) < 1:
		velocity = Vector2.ZERO
		if randf() < 0.5:
			velocity = Vector2(1, -1)
			if randf() < 0.5: velocity = Vector2(-1, -1)
		velocity *= randf_range(30, 60)


func say(message:String):
	$speechBubble.text = message
	$speechBubble/AnimationPlayer.play("speak")
	
		
@warning_ignore("shadowed_variable")
func add_head(image:Image = null, login:String = "", first:bool = false):
	$head/nametag/nametag.text = login
	if image:
		var tex = ImageTexture.create_from_image(image)
		
		var s = Sprite2D.new()
		s.texture = tex
		s.scale *= 0.1
		s.position = Vector2(0, -2)
		s.show_behind_parent = true
		$head/helmet.add_child(s)	
		
	self.first = first
	

func _on_AnimationPlayer_animation_finished(_anim_name):
	play_animation()


func play_animation():
	# Play a random (non-death) animation
	var anims = $AnimationPlayer.get_animation_list()
	var anim = anims[randi() % anims.size()]
	$AnimationPlayer.play(anim)

	# Flip sprite for extra variety
	if randf() < 0.5:
		$body.flip_h = true
	else:
		$body.flip_h = false
