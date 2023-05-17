extends TextureRect

var who : set = set_who
var reward : set = set_reward

func _ready():
	$sfxReward.play()
	$AnimationPlayer.play("default")


func set_who(value):
	$whoLabel.text = value + ":"
	
	
func set_reward(value):
	$rewardLabel.text = value
	
