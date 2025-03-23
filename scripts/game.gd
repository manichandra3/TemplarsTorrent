extends Node2D

signal entity_move_requested(entity_id, target_position) # Signal to move selected unit
signal selection_changed(new_selected)  # Signal to manage selection updates
signal current_unit_deselected() # Signal to change current selection

var selected_unit: CharacterBody2D = null  # The currently selected unit

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var target_position = get_global_mouse_position()
		
		# Check if clicking on a selectable unit
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = target_position
		query.collide_with_areas = true  # Detects areas (units should have area colliders)

		var result = space_state.intersect_point(query)

		for hit in result:
			var collider = hit.get("collider", null)
			if collider and collider is CharacterBody2D:
				change_selected_unit(collider)
				return  # Stop further processing, prevent movement trigger

		# Move only if clicking on empty ground
		if selected_unit:
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
	
