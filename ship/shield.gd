extends RigidBody2D

var STARTING_HEALTH = 1 setget set_starting_health
var health = 0
var uses_fuel = false
var alive = true

# Store the original collision layer bits
onready var original_collision_layer = collision_layer

const ENTITY_TYPE_ID = 'shield'


func _ready():
	$joint.node_a = '../../'

	# Start disabled
	die()

	connect_signals()


# connect_signals and disconnect_signals are called by
# the game and the player ship so that when shields are disabled
# as a level feature they don't turn back on again when these
# events happen. This way the shield doesn't need to know anything
# about the SHIELD_ENABLED global property.
func connect_signals():
	if not get_parent().is_connected('revived', self, 'revive'):
		# warning-ignore:return_value_discarded
		get_parent().connect('revived', self, 'revive')
	
	if not get_parent().is_connected('destroyed', self, 'die'):
		# warning-ignore:return_value_discarded
		get_parent().connect('destroyed', self, 'die')

	if get_parent().get_script().has_script_signal('fuel_changed'):
		uses_fuel = true
		if not get_parent().is_connected('fuel_used', self, 'check_fuel_used'):
			# warning-ignore:return_value_discarded
			get_parent().connect('fuel_used', self, 'check_fuel_used')
			
		if not get_parent().is_connected('fuel_added', self, 'check_fuel_added'):
			# warning-ignore:return_value_discarded
			get_parent().connect('fuel_added', self, 'check_fuel_added')

func disconnect_signals():
	get_parent().disconnect('revived', self, 'revive')
	get_parent().disconnect('destroyed', self, 'die')
	if get_parent().get_script().has_script_signal('fuel_changed'):
		get_parent().disconnect('fuel_used', self, 'check_fuel_used')
		get_parent().disconnect('fuel_added', self, 'check_fuel_added')
		

func set_starting_health(value):
	STARTING_HEALTH = value
	health = value


func hurt(amount):
	if $AnimationPlayer.is_playing():
		return true

	if not alive:
		return
		
	health -= amount
	if health <= 0:
		if uses_fuel and get_parent().fuel <= 0:
			disable()
		else:
			$shieldDownSfx.stop()
			$shieldDownUpSfx.play()
			$AnimationPlayer.stop()
			$AnimationPlayer.play('disable_and_recharge')

	return true


func is_idle():
	return not $AnimationPlayer.is_playing()


func check_fuel_used(_amount_used):
	if not alive:
		return
		
	if get_parent().fuel <= 0:
		disable()


func check_fuel_added(_amount_added):
	if not alive:
		revive()
		
	if get_parent().fuel > 0 and health <= 0:
		enable()


func disable():
	$shieldDownUpSfx.stop()
	$shieldDownSfx.play()
	$AnimationPlayer.play('disable')
	health = 0


func enable():
	if uses_fuel and get_parent().fuel <= 0:
		return
		
	if not get_parent().alive:
		return

	# Don't play shield down because of the mechanic that disables the shield
	# during rapid fire. If the player holds down the fire button, then the shield
	# starts to be disabled, then the player releases the fire button while the
	# sound is playing, then it's cutoff and weird. But if you let the down sound
	# play it's okay because it doesn't interfere with the recharge sound anyway.
	#$shieldDownSfx.stop()
	$shieldDownUpSfx.play(1.0)
	$AnimationPlayer.play('enable')
	health = STARTING_HEALTH


# Called on animation timeline
func disable_collision():
	$collision.call_deferred("set_disabled", true)


# Called on animation timeline
func enable_collision():
	$collision.call_deferred("set_disabled", false)


func inherit_parent_collision():
	collision_layer = get_parent().collision_layer


func die():
	if not alive:
		return
		
	alive = false
	
	disable_collision()
	$Sprite.hide()
	$rechargeProgress.hide()

	call_deferred('set_linear_velocity', Vector2(0,0))
	call_deferred('set_angular_velocity', 0)


func revive():
	if uses_fuel and get_parent().fuel <= 0:
		return

	alive = true
	health = STARTING_HEALTH
	rotation = -get_parent().rotation
	$AnimationPlayer.stop(true)
	enable()


func _on_shield_body_entered(body):
	if not $hitSfx.playing:
		$hitSfx.play()

	if body.ENTITY_TYPE_ID == 'shield':
		pass

	elif get_parent().ENTITY_TYPE_ID == 'generator' and body.ENTITY_TYPE_ID == 'generator-platform':
		pass

	elif body.ENTITY_TYPE_ID == 'cargo-platform':
		pass

	elif body.ENTITY_TYPE_ID == 'laser-beam':
		hurt(100)
		
	elif body is StaticBody2D:
		if linear_velocity.length() > 20:
			hurt(1)
			
			if body.has_method('hurt'):
				body.hurt(1)


func attach_to_player():
	collision_layer = 1


func detach_from_player():
	collision_layer = original_collision_layer
