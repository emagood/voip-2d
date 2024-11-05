extends Node2D

const playerScene = preload("res://character.tscn")
@onready var playersNode = $players
func _ready():
	if multiplayer.is_server():
		push_warning("SERVER SESSION")
		multiplayer.peer_connected.connect(createPlayer)
		multiplayer.peer_disconnected.connect(removePlayer)
		print("CREATE SERVER %s" % 1)

	else:
		push_warning("CLIENT SESSION")
	pass


func createPlayer(id ):
	print("CREATE PLAYER %s" % id)
	var player = playerScene.instantiate()
	player.name = str(id)
	playersNode.add_child(player, true)

func removePlayer(id ):
	print("Player remove: ", str(id))
	var player = playersNode.get_node_or_null(str(id))
	if player:
		player.queue_free()
