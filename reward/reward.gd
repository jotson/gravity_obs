extends TextureRect

var who setget set_who
var reward setget set_reward

func _ready():
	$sfxReward.play()
	$AnimationPlayer.play("default")


func set_who(value):
	$whoLabel.text = value + ":"
	
	
func set_reward(value):
	$rewardLabel.text = value
	
