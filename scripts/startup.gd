extends Node 
#res://scenes/opening/opening_with_logo.tscn 
const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1" 
const lobby_scene = "res://scenes/automatchmaking/lobby.tscn"
func _ready(): 
	pass 
	
func _on_client_pressed(ip = SERVER_IP, port = SERVER_PORT):
	print("Client Pressed")
	
func start_client(ip, port):
	print("start_client %s %s"% [ip, port])
	_on_client_pressed(ip, port)
	$LobbyPlaceholder.get_child(0).hide()
	
func _on_find_match_pressed() -> void: 
	print("find match pressed!") 
	$UI.hide() 
	
	var mock_id = str(randi()%100)
	var mock_user = {
		"playerId":mock_id,
		"username":"TT"+mock_id
	}
	print(mock_user)
	var lobby = preload(lobby_scene).instantiate()
	lobby.mock_user = mock_user
	
	lobby.start_client.connect(start_client)
	$LobbyPlaceholder.add_child(lobby)
