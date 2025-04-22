extends Control

@export var Address = "127.0.0.1"
@export var port = 8080
var x = 0
var peer
func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	if "--server" in OS.get_cmdline_args():
		hostGame()
	pass

@rpc("any_peer")
func _process(delta):
	#if GameManager.Players.size() == 2 and x == 0:
		#print("Two players registered, starting game now.")
		#StartGame.rpc()
		#x = x+ 1;
	pass
	
# this get called on server and client 
func peer_connected(id):
	print("Player Connected" + str(id))
	
func peer_disconnected(id):
	print("Player Disconnected "+ str(id))
	GameManager.Players.erase(id)
	var player1 = get_tree().get_nodes_in_group("player1")
	var player2 = get_tree().get_nodes_in_group("player2")
	if str(id) == str(player1[0].player_id):
		player1[0].queue_free()
	elif str(id) == str(player2[0].player_id):
		player2[0].queue_free()
	get_tree().root.queue_free()
		
# this get called only from client
func connected_to_server():
	print("Connected to server");
	SendPlayerInformation.rpc_id(1, $LineEdit.text, multiplayer.get_unique_id())
	
# this get called only from client
func connection_failed():
	print("Connection failed")
	pass
	
@rpc("any_peer")
func SendPlayerInformation(name,id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name": name,
			"id" : id,
			"score": 0
		}
	
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[i].name, i)
	
@rpc("any_peer", "call_local")
func StartGame():
	if OS.has_feature("server") or OS.has_feature("headless"):
		return
	var scene = load("res://scenes/game.tscn").instantiate()
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	self.hide()

func hostGame() -> void:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 2)
	if error != OK:
		print("cananot host: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for Players")

func _on_host_pressed() -> void:
	hostGame()
	SendPlayerInformation($LineEdit.text, multiplayer.get_unique_id())
	pass


func _on_join_pressed() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	pass # Replace with function body.


func _on_start_game_pressed() -> void:
	StartGame.rpc()
	pass # Replace with function body.
