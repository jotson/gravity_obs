extends Node2D

var points : int = 0


func _ready():
	global_position += Vector2(rand_range(-25, 25), rand_range(-10, 10))
	start()


func start():
	$RichTextLabel.bbcode_text = "+" + str(points)
	
	var new_position = global_position + Vector2(0, -75)
	$Tween.interpolate_property(self, "global_position", global_position, new_position, 1.0, Tween.TRANS_CIRC, Tween.EASE_OUT)
	$Tween.start()


func _on_Tween_tween_all_completed():
	queue_free()
