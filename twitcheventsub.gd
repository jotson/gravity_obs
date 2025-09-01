extends Node

signal reward_redemption
var the_sub: EventSub


func _ready() -> void:
	make_new_connection()


func make_new_connection() -> void:
	the_sub = preload("res://eventsub.tscn").instantiate()
	add_child(the_sub)
	the_sub.reward_redemption.connect(reward_redemption.emit)
	the_sub.closed.connect(on_closed)


func on_closed(es: EventSub) -> void:
	if es == the_sub:
		await get_tree().create_timer(3).timeout
		make_new_connection()
		if the_sub:
			the_sub.connect_to_twitch(false)
		

func connect_to_twitch() -> void:
	if the_sub:
		the_sub.connect_to_twitch(false)


func reconnect(reconnect_url: String) -> void:
	make_new_connection()
	the_sub.websocket_url = reconnect_url
	the_sub.connect_to_twitch(true)
	

func close() -> void:
	if the_sub:
		the_sub.close()
