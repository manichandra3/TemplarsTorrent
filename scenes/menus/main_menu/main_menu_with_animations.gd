extends MainMenu

var animation_state_machine : AnimationNodeStateMachinePlayback

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1" 
const lobby_scene = "res://scenes/automatchmaking/lobby.tscn"

var peer
func _ready():
	super._ready()
	animation_state_machine = $MenuAnimationTree.get("parameters/playback")
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	if "--server" in OS.get_cmdline_args():
		hostGame()

func intro_done():
	animation_state_machine.travel("OpenMainMenu")

func _is_in_intro():
	return animation_state_machine.get_current_node() == "Intro"

func _event_is_mouse_button_released(event : InputEvent):
	return event is InputEventMouseButton and not event.is_pressed()

func _event_skips_intro(event : InputEvent):
	return event.is_action_released("ui_accept") or \
		event.is_action_released("ui_select") or \
		event.is_action_released("ui_cancel") or \
		_event_is_mouse_button_released(event)

func _open_sub_menu(menu):
	super._open_sub_menu(menu)
	animation_state_machine.travel("OpenSubMenu")

func _close_sub_menu():
	super._close_sub_menu()
	animation_state_machine.travel("OpenMainMenu")

func _input(event):
	if _is_in_intro() and _event_skips_intro(event):
		intro_done()
		return
	super._input(event)

func _on_new_game_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	
func start_game():
	get_tree().change_scene_to_file("res://scenes/game.tscn");
	
#=========================================================================================
@rpc("any_peer", "call_local")
func StartGame():
	if OS.has_feature("server") or OS.has_feature("headless"):
		return
	var scene = load("res://scenes/game.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

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
	if GameManager.Players.size() == 0:
		clear_game_scene()

func clear_game_scene():
	var game_node = get_tree().get_root().get_node("game")
	if game_node:
		for child in game_node.get_children():
			child.queue_free()


# this get called only from client
func connected_to_server():
	print("Connected to server");
	SendPlayerInformation.rpc_id(1, "", multiplayer.get_unique_id())
	
# this get called only from client
func connection_failed():
	print("Connection failed")
	pass

func _on_host_pressed() -> void:
	hostGame()
	SendPlayerInformation($LineEdit.text, multiplayer.get_unique_id())
	pass

func hostGame() -> void:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(SERVER_PORT, 2)
	if error != OK:
		print("cananot host: " + error)
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for Players")

func _on_client_pressed(ip = SERVER_IP, port = SERVER_PORT):
	print("Client Pressed")
	#start_game()
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, str(port).to_int())
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	$Start.show()


func _on_start_pressed() -> void:
	StartGame.rpc()
	pass # Replace with function body.
	
func start_client(ip, port):
	print("start_client %s %s"% [ip, port])
	_on_client_pressed(ip, port)
	$LobbyPlaceholder.get_child(0).hide()
	
func _on_continue_game_button_pressed():
	$MenuContainer.hide()
	
	print("find match pressed!") 
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

	
