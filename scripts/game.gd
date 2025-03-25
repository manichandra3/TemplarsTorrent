extends Node2D

# Existing signals
signal entity_move_requested(entity_id, target_position)
signal selection_changed(new_selected)

# Wood management variables 
var wood_count: int = 0

# Existing variables
@onready var ui_layer = preload("res://scenes/ui.tscn").instantiate()
@onready var wood_label: Label = null
@export var pawn_scene: PackedScene = load("res://scenes/pawn.tscn")
@export var knight_scene: PackedScene = load("res://scenes/knight.tscn")
var selected_unit: CharacterBody2D = null
var castle: StaticBody2D

func _ready():
	add_child(ui_layer) 
	# Existing setup
	castle = get_tree().get_first_node_in_group("castle")
	if not castle:
		push_error("Castle not found! Make sure it's in the 'castle' group")

# Existing input handling (unchanged)
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

# Existing movement/selection functions (unchanged)
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

# Updated pawn spawning function with wood check
func _on_spawn_pawn_pressed() -> void:
	if not pawn_scene or not is_instance_valid(castle):
		return
	
	if spend_wood(40):  # Require 40 wood to spawn pawn
		var random = Vector2(randf_range(10,30),randf_range(10,30))
		var spawn_position = castle.global_position + Vector2(0, 90) + random  
		var new_pawn = pawn_scene.instantiate()
		new_pawn.global_position = spawn_position
		get_parent().add_child(new_pawn)
		print("Pawn spawned!")
	else:
		print("Not enough wood to spawn a pawn!")

# NEW WOOD MANAGEMENT FUNCTIONS
func add_wood(amount: int):
	wood_count += amount
	print("Wood added: ", amount, " (Total: ", wood_count, ")")

func get_wood_count() -> int:
	return wood_count

func spend_wood(amount: int) -> bool:
	if wood_count >= amount:
		wood_count -= amount
		return true
	return false

# Implemented knight spawning function with wood check
func _on_spawn_knight_pressed() -> void:
	if not knight_scene or not is_instance_valid(castle):
		return

	if spend_wood(20):  # Require 20 wood to spawn knight
		var random = Vector2(randf_range(10,30),randf_range(10,30))
		var spawn_position = castle.global_position + Vector2(0, 90) + random  
		var new_knight = knight_scene.instantiate()
		new_knight.global_position = spawn_position
		get_parent().add_child(new_knight)
		print("Knight spawned!")
	else:
		print("Not enough wood to spawn a knight!")

func _on_cancel_selection_pressed() -> void:
	deselect_current_unit()
	pass # Replace with function body.
