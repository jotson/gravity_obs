extends Area2D

func _ready():
	pass


func _on_VisibilityEnabler2D_viewport_entered(_viewport):
	if Game.player:
		$CollisionShape2D.shape.radius = Game.player.TRACTOR_RANGE - 16
	hide()


func _on_VisibilityEnabler2D_viewport_exited(_viewport):
	hide()


func activate():
	$active.show()


func deactivate():
	$active.hide()


func _on_BeamTarget_body_entered(body):
	if !visible and Game.player and Game.player == body:
		$AnimationPlayer.play('stage1')


func _on_BeamTarget_body_exited(body):
	if Game.player and Game.player == body:
		hide()
