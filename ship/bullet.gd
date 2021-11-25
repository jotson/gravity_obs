extends RigidBody2D

var Impact = preload("res://booms/impact.tscn")

var DAMAGE = 1
var gravity_well_deflect = 60

# Keep track of last angle before collision
var last_rot = 0.0
var alive = true

var username


signal destroyed(position, body)

const ENTITY_TYPE_ID = 'bullet'


func _ready():
	gravity_scale = 0


func _physics_process(_delta):
	last_rot = rotation
	rotation = linear_velocity.angle()


func _on_bullet_body_entered(body):
	if body.has_method('hurt'):
		if body.get("username") and body.alive:
			Battle.kill_ship(username, body.username)
		if body.hurt(DAMAGE):
			die()
	else:
		die()
		
	bullet_hit(position, rotation, body);

	emit_signal("destroyed", position, last_rot, body)


func _on_deathTimer_timeout():
	die()


func die():
	if !alive:
		return
		
	alive = false
	
	# Hide it
	$Sprite.hide()
	$trail.hide()
	$particleTrail.emitting = false
	$trailDeathTimer.start()
	
	# Stop it
	linear_velocity = Vector2(0,0)
	angular_velocity = 0
	gravity_scale = 0

	# Disable collisions
	$collision.call_deferred("set_disabled", true)
	call_deferred('set_collision_layer', 0)
	call_deferred('set_collision_mask', 0)
	
	
func _on_trailDeathTimer_timeout():
	queue_free()


func _on_VisibilityNotifier2D_screen_exited():
	die()


func bullet_hit(pos, rot, body = null):
	# Show bullet hit visual effect
	var i = Impact.instance()
	i.position = pos
	i.rotation = rot + PI
	Helper.add_child(i)
	
	Battle.spark(pos, Vector2(1, 0).rotated(rot) * 200)

	if body and body.has_method("hurt"):
		bullet_hit_enemy_sfx(pos)
	else:
		# Play bullet hit sound effect
		bullet_hit_sfx(pos)


func bullet_hit_enemy_sfx(pos):
	var pitch = 1.0
	if randf() > 0.5:
		pitch = 1.0
	else:
		pitch = 0.7
	$bulletHitEnemySfx.global_position = pos
	$bulletHitEnemySfx.pitch_scale = pitch
	#$bulletHitEnemySfx.play()


func bullet_hit_sfx(pos):
	var pitch = 1.0
	if randf() > 0.5:
		pitch = 1.0
	else:
		pitch = 0.7
	$bulletHitSfx.global_position = pos
	$bulletHitSfx.pitch_scale = pitch
	#$bulletHitSfx.play()
