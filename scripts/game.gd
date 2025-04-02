extends Node2D

# Signals
signal entity_move_requested(entity_id, target_position)
signal selection_changed(new_selected)

# Existing variables
@onready var ui_layer = preload("res://scenes/ui.tscn").instantiate()
@export var pawn_scene: PackedScene = load("res://scenes/pawn.tscn")
@export var knight_scene: PackedScene = load("res://scenes/knight.tscn")
var selected_unit: CharacterBody2D = null
var castle: StaticBody2D

func _ready():
	add_child(ui_layer) 
	castle = get_tree().get_first_node_in_group("castle")
	if not castle:
		push_error("Castle not found! Make sure it's in the 'castle' group")

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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

func request_entity_movement(entity_id, target_position):
	emit_signal("entity_move_requested", entity_id, target_position)

func change_selected_unit(new_unit):
	if selected_unit and selected_unit.has_method("deselect") and selected_unit != new_unit and not selected_unit.is_in_group('goblins'):
		selected_unit.deselect()
	selected_unit = new_unit
	emit_signal("selection_changed", new_unit)

func deselect_current_unit():
	if selected_unit:
		selected_unit.deselect()
		selected_unit = null
	emit_signal("selection_changed", null)

# Resource Management
# Replace these functions in your original script

func add_wood(amount: int):
	ResourceManager.add_wood(amount)

func get_wood_count() -> int:
	return ResourceManager.get_wood_count()

func spend_wood(amount: int) -> bool:
	return ResourceManager.spend_wood(amount)

func add_gold(amount: int):
	ResourceManager.add_gold(amount)

func get_gold_count() -> int:
	return ResourceManager.get_gold_count()

func spend_gold(amount: int) -> bool:
	return ResourceManager.spend_gold(amount)
# Spawning Functions
func _on_spawn_pawn_pressed() -> void:
	if not pawn_scene or not is_instance_valid(castle):
		return
	if spend_wood(20):
		spawn_unit(pawn_scene)
	else:
		display_insufficient_resources("Wood")

func _on_spawn_knight_pressed() -> void:
	if not knight_scene or not is_instance_valid(castle):
		return
	
	if spend_wood(20):
		spawn_unit(knight_scene)
	else:
		display_insufficient_resources("Wood")

func spawn_unit(unit_scene: PackedScene):
	var spawn_position = get_valid_spawn_position()
	var new_unit = unit_scene.instantiate()
	new_unit.global_position = spawn_position
	get_parent().add_child(new_unit)
	print(new_unit.name, " spawned!")

func get_valid_spawn_position() -> Vector2:
	var attempts = 10
	while attempts > 0:
		var random_offset = Vector2(randf_range(-30, 30), randf_range(60, 100))
		var test_position = castle.global_position + random_offset

		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = test_position
		query.collide_with_bodies = true

		if space_state.intersect_point(query).size() == 0:
			return test_position

		attempts -= 1
	return castle.global_position + Vector2(0, 90)

func display_insufficient_resources(resource_name: String):
	print("Not enough ", resource_name, " to spawn a unit!")

func _on_cancel_selection_pressed() -> void:
	deselect_current_unit()
