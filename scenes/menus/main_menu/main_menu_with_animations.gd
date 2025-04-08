extends MainMenu

var animation_state_machine : AnimationNodeStateMachinePlayback

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1" 
const lobby_scene = "res://scenes/automatchmaking/lobby.tscn"

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

func _ready():
	super._ready()
	animation_state_machine = $MenuAnimationTree.get("parameters/playback")

func _on_new_game_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	
func start_game():
	get_tree().change_scene_to_file("res://scenes/game.tscn");
	
func _on_client_pressed(ip = SERVER_IP, port = SERVER_PORT):
	print("Client Pressed")
	start_game()
	
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

	
