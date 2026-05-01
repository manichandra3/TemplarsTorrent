extends CanvasLayer

func _ready() -> void:
	var cancel_btn = $HBoxContainer/cancel_selection
	var pawn_btn = $HBoxContainer/spawn_pawn
	var knight_btn = $HBoxContainer/spawn_knight
	
	if cancel_btn:
		cancel_btn.pressed.connect(get_tree().get_first_node_in_group("player_controller")._on_cancel_selection_pressed)
	if pawn_btn:
		pawn_btn.pressed.connect(Game._on_spawn_pawn_pressed)
	if knight_btn:
		knight_btn.pressed.connect(Game._on_spawn_knight_pressed)
