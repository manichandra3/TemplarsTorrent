extends Node2D

@export var health: float = 10
@export var pawn_scene: PackedScene = load("res://scenes/pawn.tscn")
@export var max_units: int = 5
@export var spawn_offset: Vector2 = Vector2(100, 0)  # Default spawn offset to right of castle
@export var spawn_variation: float = 20.0  # Random variation in spawn position
var spawned_units = []
var castle: StaticBody2D
signal unit_spawned(unit)

func _ready():
	add_to_group("spawners")
	# Find the castle node
	castle = get_tree().get_first_node_in_group("castle")
	if not castle:
		push_error("Castle not found! Make sure it's in the 'castle' group")
		return

func spawn_unit():
	if not pawn_scene:
		push_error("Pawn scene not assigned!")
		return
	
	if not is_instance_valid(castle):
		push_error("Castle reference is invalid!")
		return
	
	if spawned_units.size() >= max_units:
		print("Max units reached (", max_units, ")")
		return
	
	# Calculate spawn position with random variation
	var random_variation = Vector2(
		randf_range(-spawn_variation, spawn_variation),
		randf_range(-spawn_variation, spawn_variation)
	)
	var spawn_pos = castle.global_position + spawn_offset + random_variation
	
	# Create and position the new pawn
	var new_pawn = pawn_scene.instantiate()
	new_pawn.global_position = spawn_pos
	get_parent().add_child(new_pawn) 
	
	# Track and clean up the unit
	spawned_units.append(new_pawn)
	unit_spawned.emit(new_pawn)
	new_pawn.tree_exited.connect(_on_pawn_exited.bind(new_pawn))

func _on_pawn_exited(pawn: Node):
	if pawn in spawned_units:
		spawned_units.erase(pawn)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = get_global_mouse_position()
		var result = space_state.intersect_point(query)
		
		for hit in result:
			var collider = hit.get("collider", null)
			if collider and collider.is_in_group("spawners"):
				print("Spawning new unit at castle location")
				spawn_unit()
				get_viewport().set_input_as_handled()
				return
