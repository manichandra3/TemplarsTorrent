extends Node2D

signal entity_move_requested(entity_id, target_position) # Signal to move selected unit
signal selection_changed(new_selected)  # Signal to manage selection updates
signal current_unit_deselected() # Signal to change current selection

var selected_unit: CharacterBody2D = null  # The currently selected unit

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected_unit:
			var target_position = get_global_mouse_position()
			request_entity_movement(selected_unit.get_instance_id(), target_position)

func request_entity_movement(entity_id, target_position):
	print("entity move requested for entity with id ", entity_id, " with target position ", target_position)
	emit_signal("entity_move_requested", entity_id, target_position)

func change_selected_unit(new_unit):
	print("selection changed")
	# Deselect the old unit
	if selected_unit and selected_unit != new_unit:
		selected_unit.deselect()
	# Set the new selection
	selected_unit = new_unit
	emit_signal("selection_changed", new_unit)
	
func deselect_current_unit():
	print("deselected")
	if selected_unit:
		selected_unit.deselect()
		selected_unit = null
		emit_signal("selection_changed", null)
	
