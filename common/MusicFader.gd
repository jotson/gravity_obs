extends Node2D

var tracks : Array = []
var current_track : int = 0

var current_resource : Resource = null
var current_player : int = 1

signal finished


func _ready():
	pass


func set_tracks(new_tracks : Array) -> void:
	self.tracks = new_tracks
	self.tracks.shuffle()
	current_track = 0
	
	
func next_track() -> void:
	current_track = current_track + 1
	if current_track >= tracks.size():
		current_track = 0
		
	play(tracks[current_track])


func play(resource : Resource, speed = 1.0) -> void:
	current_resource = resource
	
	match current_player:
		1:
			$music2.stream = resource
			$music2.play()
			$music2.stream_paused = false
			$AnimationPlayer.play("1to2")
			$AnimationPlayer.playback_speed = speed
			if not $music1.playing or $music1.stream_paused:
				$AnimationPlayer.seek(1.99)
		2:
			$music1.stream = resource
			$music1.play()
			$music1.stream_paused = false
			$AnimationPlayer.play("2to1")
			$AnimationPlayer.playback_speed = speed
			if not $music2.playing or $music2.stream_paused:
				$AnimationPlayer.seek(1.99)
				
			
	current_player = current_player % 2 + 1
	
	
func stop() -> void:
	# Pause instead of stopping so that "finished" signal is not
	# emitted which causes the game to automatically play the
	# next track
	$music1.stream_paused = true
	$music2.stream_paused = true
	
	
func is_playing() -> bool:
	return $music1.playing && !$music1.stream_paused or $music2.playing && !$music2.stream_paused


func _on_music1_finished():
	emit_signal("finished")


func _on_music2_finished():
	emit_signal("finished")
