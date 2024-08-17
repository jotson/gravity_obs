extends Node2D

var emote_id
var emote_url


func _ready() -> void:
	hide()
	
	
func fetch(the_id, the_url) -> void:
	emote_id = the_id
	emote_url = the_url
	
	Twitch.register_emote(emote_id)
	
	if Twitch.emotes.has(emote_id):
		generate_props()
	else:
		$HTTPRequest.request(emote_url)
		
		var result = await $HTTPRequest.request_completed
		var body = result[3]
		
		var image = Image.new()
		image.load_png_from_buffer(body)
		Twitch.register_emote(emote_id, image)
	
	generate_props()

	queue_free()


func generate_props():
	for i in range(3):
		var obj = preload("res://smiley/emote_body.tscn").instantiate()
		obj.global_position = Helper.random_position()
		Helper.add_child(obj)
		obj.texture = Twitch.emotes[emote_id]
