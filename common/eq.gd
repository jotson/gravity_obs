extends Control

var music_bus


func _ready():
	music_bus = AudioServer.get_bus_index('Music')


func _process(_delta):
	if AudioServer.is_bus_mute(music_bus):
		hide()
		return
	
	show()

	var volume_left_db = AudioServer.get_bus_peak_volume_left_db(music_bus, 0)
	var volume_left = db2linear(volume_left_db) * 100

	var volume_right_db = AudioServer.get_bus_peak_volume_right_db(music_bus, 0)
	var volume_right = db2linear(volume_right_db) * 100

	$left.value = volume_left
	$right.value = volume_right
