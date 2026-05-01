extends Node2D

# Signals
signal entity_move_requested(entity_id: int, target_position: Vector2)
signal selection_changed(new_selected: CharacterBody2D)

var selected_unit: CharacterBody2D = null

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		var target_position = get_global_mouse_position()

		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = target_position
		query.collide_with_areas = true  

		var result = space_state.intersect_point(query)

		for hit in result:
			var collider = hit.get("collider", null)
			if collider and collider is CharacterBody2D and not collider.is_in_group('trees'):
				change_selected_unit(collider)
				return 

		if selected_unit:
			request_entity_movement(selected_unit.get_instance_id(), target_position)

func request_entity_movement(entity_id: int, target_position: Vector2) -> void:
	entity_move_requested.emit(entity_id, target_position)

func change_selected_unit(new_unit: CharacterBody2D) -> void:
	if selected_unit and selected_unit.has_method("deselect") and selected_unit != new_unit and not selected_unit.is_in_group('goblins'):
		selected_unit.deselect()
	selected_unit = new_unit
	selection_changed.emit(new_unit)

func deselect_current_unit() -> void:
	if selected_unit:
		selected_unit.deselect()
		selected_unit = null
	selection_changed.emit(null)

func _on_cancel_selection_pressed() -> void:
	deselect_current_unit()
