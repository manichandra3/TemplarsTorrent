extends Control
#wss://jgah4v9cga.execute-api.ap-south-1.amazonaws.com/production/
var websocket_url = "wss://jgah4v9cga.execute-api.ap-south-1.amazonaws.com/production/"
var messageToSend = ""

@onready var _client : WebScoketClient = $WebSocketClient

const REQUEST_MATCHES = "REQUEST_MATCHES"
const JOIN_MATCH = "JOIN_MATCH"
const MATCH_PLAYERS = "MATCH_PLAYERS"
const PLAYER_JOINED = "PLAYER_JOINED"
const PLAYER_DROPPED = "PLAYER_DROPPED"
const CHECK_MATCH_READY = "CHECK_MATCH_READY"
const MATCH_READY = "MATCH_READY"
const CREATE_MATCHES = "CREATE_MATCHES"

var mock_user = {}

signal start_client(ip, port)

func _ready():
	print("Attempting to connect to server...")
	_connect_to_matchmaking_server()
	$LobbyContainer.hide() 
	
func _connect_to_matchmaking_server():
	var error = _client.connect_to_url(websocket_url)
	
	if error != OK:
		print("Error connecting to websocket: %s" % [websocket_url])
	
func _process_received_message(message):
	if typeof(message) == TYPE_STRING:
		var response_msg = str_to_var(message)
		
		if response_msg.op:
			print("Process message op: %s"% response_msg.op)
			
			if response_msg.op == REQUEST_MATCHES:
				print("REQUEST_MATCHES")
				#selecting the random match 
				var matches = response_msg.response
				if matches && matches.size() > 0:
					_automatic_match_selection(matches)
					$MatchMakingStatus.text = "[center]Selecting the match automatically![center]"
					
			elif response_msg.op == MATCH_PLAYERS:
				print("MATCH_PLAYERS")
				_enter_match_lobby(response_msg.response)
			
			elif response_msg.op == MATCH_READY:
				print("MATCH_READY")
				print("Connection info: %s, %s"%[response_msg.response.ip, response_msg.response.port])
				
				$MatchMakingStatus.text = "[center]Game Full, Entering Match![center]"
				
				start_client.emit(response_msg.response.ip, response_msg.response.port)
				
				_client.close(1000, "Game started, lobby session ended normally")
				
			elif response_msg.op == PLAYER_JOINED:
				print("PLAYER_JOINED")
				var match_with_players = response_msg.response
				_build_player_lobby_lists(match_with_players.users)
				
			elif response_msg.op == PLAYER_DROPPED:
				print("PLAYER_DROPPED")
				var match_with_players = response_msg.response
				print("Dropped player: %s"% match_with_players.userId)
				_build_player_lobby_lists(match_with_players.users)
					
func _automatic_match_selection(matches):
	if matches.size() == 0:
		print("No matches available")
		return
	var match_index = randi() % matches.size()
	print("Selected match index: ", match_index)
	_join_match(matches[match_index])
	
func _join_match(match_obj: Dictionary):
	$MatchMakingStatus.text = "Entering match lobby...";
	
	var join_match_message = {
		"op": JOIN_MATCH,
		"matchId": match_obj.matchId,
		"playerId": mock_user.playerId,
		"username": mock_user.username
	}
	
	_send_message(join_match_message)
	
func _enter_match_lobby(match_with_players):
	print("Enter match lobby")
	print(match_with_players)
	
	$LobbyContainer.show()
	$MatchMakingStatus.text =  "[center]Waiting for players....[center]"
	
	_build_player_lobby_lists(match_with_players.users)
	
	# we have to change this team_full_request part when we release for production
	# we have to make the api server to call the team_full_request for every 5sec/anytime
	# of the every match 
	
	var match_id = match_with_players.matchInfo.matchId
	var check_match_ready = {
		"op": CHECK_MATCH_READY,
		"matchId": match_id
	}
	_send_message(check_match_ready)
	
func _build_player_lobby_lists(match_players):
	for team_child in $LobbyContainer/Players/player1_info.get_children():
		team_child.queue_free()
	for team_child in $LobbyContainer/Players/player2_info.get_children():
		team_child.queue_free()
	
	for player in match_players:
		print(player)
		var button_text = " %s "% [player.username]
		
		# button labelk
		var button_label := RichTextLabel.new()
		button_label.set_text(button_text)
		button_label.set_size(Vector2(300, 95))
		button_label.set_position(Vector2(112, 179))
		button_label.add_theme_font_size_override("normal_font_size", 40)
		button_label.fit_content = true
		button_label.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		
		if player.team == "1":
			$LobbyContainer/Players/player1_info.add_child(button_label)
		elif player.team == "2":
			$LobbyContainer/Players/player2_info.add_child(button_label)
		else:
			print("Player not assigned a team!")
#life cycles
func _send_message(message_to_send):
	print("send_message")
	var json_message = JSON.stringify(message_to_send)
	_client.send(json_message)
	
func _on_websocket_message_received(message):
	print("Message received: %s"% message)
	_process_received_message(message)
	
func _on_websocket_client_connection_close():
	var ws = _client.get_socket()
	print("Client disconnected with code: %s, reason: %s"% [ws.get_close_code(), ws.get_close_reason()])
	
func _on_websocket_client_connected_to_server():
	print("Client Connected to server....")
	$MatchMakingStatus.text = "[center]LOOKING FOR MATCHES...[center]"
	var request_matches = {
		"op": REQUEST_MATCHES
	}
	_send_message(request_matches)
	
func _on_send_test_message_pressed():
	print("Sending test message")
	var dict = {
		"id": "1234",
		"op": "card_played_123"
	}
	var jsonMessage = JSON.stringify(dict)
	_client.send(jsonMessage)
	
func _create_mock_matches():
	print("create_mock_matches")
	var messageToSend={
		"op": CREATE_MATCHES
	}
	_send_message(messageToSend)
	

	
	
