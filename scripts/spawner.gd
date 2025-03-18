extends Node2D

@export var health: float = 10
@export var pawn_scene: PackedScene = load("res://scenes/pawn.tscn")
@export var spawn_position_offset: Vector2 = Vector2(10, 0)  # Default 10 pixels to the right
@export var max_units: int = 5  

var spawned_units = []  

signal unit_spawned(unit)

func _ready():
	add_to_group("spawners")

func spawn_unit():
	if not pawn_scene:
		print("Error: pawn_scene is not assigned!")
		return
	
	if spawned_units.size() >= max_units:
		print("Max units reached")
		return
	
	var new_pawn = pawn_scene.instantiate()
	
	# Apply offset (can be randomized)
	var random_offset = Vector2(randi_range(-5, 5), randi_range(-5, 5))
	new_pawn.global_position = global_position + spawn_position_offset + random_offset
	
	get_tree().current_scene.add_child(new_pawn)
	spawned_units.append(new_pawn)
	
	unit_spawned.emit(new_pawn)

	# Clean up dead units from list
	new_pawn.tree_exited.connect(func(): spawned_units.erase(new_pawn))

func _unhandled_input(event: InputEvent) -> void:
	# If clicked, spawn a unit
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = get_global_mouse_position()
		var result = space_state.intersect_point(query)
		
		for hit in result:
			var collider = hit.get("collider", null)
			if collider and collider.is_in_group("spawners"):
				print("pressed!!")
				spawn_unit()
				get_viewport().set_input_as_handled()
