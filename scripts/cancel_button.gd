extends Button

func _ready():
	# Connect the button's pressed signal
	pressed.connect(_on_pressed)

func _on_pressed():
	if get_tree().get_first_node_in_group("player_controller"):
		get_tree().get_first_node_in_group("player_controller").change_selected_unit(null)
		print("Selection canceled")
	else:
		push_error("PlayerController missing")
