import os

files = ['scripts/pawn.gd', 'scripts/knight.gd', 'scripts/archer.gd', 'scripts/game_ui.gd', 'scripts/cancel_button.gd']

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    # Replacement for game_ui.gd
    if f == 'scripts/game_ui.gd':
        content = content.replace('Game._on_cancel_selection_pressed', 'get_tree().get_first_node_in_group("player_controller")._on_cancel_selection_pressed')
    elif f == 'scripts/cancel_button.gd':
        content = content.replace('Game and Game.has_method("change_selected_unit")', 'get_tree().get_first_node_in_group("player_controller")')
        content = content.replace('Game.change_selected_unit(null)', 'get_tree().get_first_node_in_group("player_controller").change_selected_unit(null)')
        content = content.replace('Game node missing or missing deselect method', 'PlayerController missing')
    else:
        # For unit files
        content = content.replace('Game.entity_move_requested.connect', 'get_tree().get_first_node_in_group("player_controller").entity_move_requested.connect')
        content = content.replace('Game.selection_changed.connect', 'get_tree().get_first_node_in_group("player_controller").selection_changed.connect')
        content = content.replace('Game.change_selected_unit', 'get_tree().get_first_node_in_group("player_controller").change_selected_unit')

    with open(f, 'w') as file:
        file.write(content)

