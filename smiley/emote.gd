extends Node2D

var url: String:
	set(value):
		url = value
		$HTTPRequest.request(url)


func _ready() -> void:
	hide()
	
	
func _on_http_request_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var image = Image.new()
	image.load_png_from_buffer(body)
	var texture = ImageTexture.create_from_image(image)
	
	for i in range(3):
		var obj = preload("res://smiley/emote_body.tscn").instantiate()
		obj.global_position = Helper.random_position()
		Helper.add_child(obj)
		obj.texture = texture
	
	queue_free()
