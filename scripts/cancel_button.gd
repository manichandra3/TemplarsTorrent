extends Button

func _ready():
	# Connect the button's pressed signal
	pressed.connect(_on_pressed)

func _on_pressed():
	var game = get_node_or_null("/root/game")
	if game and game.has_method("change_selected_unit"):
		game.change_selected_unit(null)
		print("Selection canceled")
	else:
		push_error("Game node missing or missing deselect method")
