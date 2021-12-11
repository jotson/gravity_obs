extends RigidBody2D

var LINEAR_ACCELERATION = 250.0 # px/s/s
var ANGULAR_ACCELERATION = 8.0 # radians/s/s
var ANGULAR_MAX = PI * 2 # radians/s
var TRACTOR_RANGE = 100 # px
var STARTING_HEALTH = 1
var health = 0

var _transform = null

var fuel = 0.0 # Starting fuel is set during level init
var _thrust_duration = 0
var thrusting_last_frame = false
var turn = 0
var _turn_duration = 0
var _shoot_shots = 0
var landed = false

var tractor_target = '' # Node path to the target object
var tractor_can_toggle = true # Controls when beam input can toggle
var closest_beamable = null # Keeps track of closest beamable object
var beam_priority = ['fuel-pod', 'person', 'generator', 'cargo-box']

var _teleport = null

var FUEL_CONSUMPTION_RATE = 20.0 # units/s

var Bullet = preload("res://ship/bullet.tscn")
var Respawn = preload("res://ship/respawn.tscn")

var last_velocity = Vector2()
var local_gravity = Vector2()
var _thrust_dir = Vector2(0, 0)
var aim_dir = Vector2(0, -1)
var turret_locked = false
var is_shooting = false

var username setget set_username
var color setget set_color
var kills setget set_kills

var shootSfx = []

onready var alive = true
onready var initial_collision_layer = collision_layer
onready var initial_collision_mask = collision_mask
onready var initial_transform = transform

signal destroyed
signal revived

const ENTITY_TYPE_ID = 'player'


func _ready():
	randomize()
	
	lock_turret()
	emit_exhaust(0)
	$flash.hide()
	alive = false
	$ui/crown.hide()
	$ui/chat.hide()
	$ui/chat.text = ""
	hide()
	revive()
	
	$collision.disabled = true


func say(text):
	$ui/chat.text = text
	$ui/chatAnim.play("default")
	

func update_ui():
	$ui.global_rotation = 0
	$ui/username.text = username
	$Sprite/hull.modulate = color
	$trail.modulate = color
	$trail2.modulate = color
	$ui/kills.text = "Kills: %d" % [kills]
	if Battle.last_winner == username:
		$ui/crown.show()
	else:
		$ui/crown.hide()
	

func set_username(value):
	username = value
	if is_inside_tree():
		update_ui()
	

func set_color(value):
	color = value
	if is_inside_tree():
		update_ui()
	

func set_kills(value):
	kills = value
	if is_inside_tree():
		update_ui()
	

func _physics_process(_delta):
	if not alive:
		return
	
	update_ui()
		
	# Track last known velocity
	last_velocity = linear_velocity
	
	if _shoot_shots > 0:
		shoot(_shoot_shots)

	# Change raycast aim
	$aimRaycast.rotation = sin(OS.get_ticks_msec()/100.0) * 0.1 * PI
	var on_target = $aimRaycast.is_colliding()
	
	if randi() % 150 == 0:
		thrust(10)
	
	if on_target:
		shoot(3)

	if not on_target:	
		if randi() % 100 == 0:
			if randi() % 2 == 1:
				turn_left(0.3)
			else:
				turn_right(0.3)

	
func _integrate_forces(state):
	if not alive:
		return
		
	if _transform:
		state.transform = _transform
		_transform = null

	local_gravity = state.total_gravity

	var bearing = Vector2(1,0).rotated(rotation).normalized()
	var delta = state.get_step()

	# Animate hull
	if _thrust_duration > 0:
		_thrust_duration -= delta
		linear_velocity += _thrust_dir.normalized() * LINEAR_ACCELERATION/mass * delta
		thrust(_thrust_duration)
		
	$flamePort.hide()
	$flameStarboard.hide()
	if _turn_duration > 0:
		_turn_duration -= delta
		angular_velocity += turn * ANGULAR_ACCELERATION * delta
		if abs(angular_velocity) > ANGULAR_MAX:
			angular_velocity = ANGULAR_MAX * angular_velocity / abs(angular_velocity)

		if turn > 0:
			$flamePort.show()
		if turn < 0:
			$flameStarboard.show()

	if _thrust_duration > 0:
		# Thrust animation
		if $Sprite/hull.frame != 3 and not $Sprite/hull/AnimationPlayer.is_playing():
			$Sprite/hull/AnimationPlayer.play('thrust')
	else:
		# Reverse thrust animation
		if $Sprite/hull.frame == 3 and not $Sprite/hull/AnimationPlayer.is_playing():
			$Sprite/hull/AnimationPlayer.play('thrust', -1, -1, true)

	# Aim turret
	if turret_locked:
		aim_dir = bearing

	# Consume fuel and turn on engine
	if _thrust_duration > 0:
		emit_exhaust(1)
	else:
		emit_exhaust(0)

	# Thrust sound
	if _thrust_duration > 0:
		thrusting_last_frame = true
	else:
		thrusting_last_frame = false


func thrust(duration = 0.5):
	var bearing = Vector2(1,0).rotated(rotation).normalized()
	_thrust_duration = duration
	thrust_dir(bearing)

func turn_left(duration = 0.25):
	_turn_duration = duration
	turn = -1

func turn_right(duration = 0.25):
	_turn_duration = duration
	turn = 1

func thrust_dir(direction):
	_thrust_dir = direction

func aim(direction):
	aim_dir = direction

func lock_turret():
	turret_locked = true

func unlock_turret():
	turret_locked = false

func shoot(shots = 1):
	if !alive:
		return
		
	_shoot_shots = shots
	
	$shootTimer.wait_time = 0.1

	if $shootTimer.is_stopped():
		_shoot_shots -= 1
		
		is_shooting = true
		
		# Fire bullet
		var bullet = Bullet.instance()
		bullet.username = username
		bullet.position = position + Vector2(32,0).rotated(rotation)
		bullet.apply_central_impulse(Vector2(1200, 0).rotated($Sprite/turret.rotation + rotation) + linear_velocity)
		Helper.add_child(bullet)

		# Apply recoil force to ship
		#apply_impulse(Vector2(0,0), Vector2(-15, 0).rotated($Sprite/turret.rotation + rotation))
		$flash.rotation = $Sprite/turret.rotation

		$flash.show()
		if not $flash/AnimationPlayer.is_playing():
			var anims = $flash/AnimationPlayer.get_animation_list()
			var a = anims[randi() % anims.size()]
			$flash/AnimationPlayer.play(a)
		$shootTimer.start()


func stop_shooting():
	is_shooting = false

	$shieldEnergyTimer.stop()
	$shootTimer.stop()


func emit_exhaust(on):
	if on:
		$flame.show()
		$flame.rotation = PI/2 - angular_velocity * PI/36
		$flame/flare.global_rotation = 0
		$flame/flare.scale = Vector2(rand_range(.5,1), 1)
	else:
		$flame.hide()


func hurt(amount):
	if alive:
		#print('ship damaged ', amount, ', remaining health ', health)
		health -= amount

		if health <= 0:
			health = 0
			die()

	return true


func revive():
	# Respawn
	var r = Respawn.instance()
	r.position = position
	Helper.call_deferred("add_child", r)

	# Wait here until the respawn is complete
	yield(r, 'done')
	
	$collision.disabled = false
	
	alive = true

	health = STARTING_HEALTH

	# Shield watches for this signal to enable
	emit_signal('revived')

	show()

	aim_dir = Vector2(0, -1)
	aim(aim_dir)


func self_destruct():
	Battle.explode(position + Vector2(32,0).rotated(randf()*2*PI), linear_velocity, 0.1, true)
	Battle.explode(position + Vector2(32,0).rotated(randf()*2*PI), linear_velocity, 0.2, true)
	Battle.explode(position + Vector2(32,0).rotated(randf()*2*PI), linear_velocity, 0.3, true)
	die()


func die():
	if alive:
		alive = false

		# Explosion
		Battle.explode(position, linear_velocity, 0, true)

		emit_signal("destroyed")

		queue_free()


func _on_ship_body_entered(body):
	if body.is_in_group('wall'):
		var state = Physics2DServer.body_get_direct_state(get_rid())
		if state.get_contact_count():
			var normal = state.get_contact_local_normal(0)
			_transform = Transform2D(normal.angle(), position)
