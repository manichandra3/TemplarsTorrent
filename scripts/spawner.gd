extends Node2D

@export var health : float = 10
@export var pawn_scene: PackedScene  
@export var spawn_position_offset: Vector2 = Vector2(50, 0)  # Where units spawn relative to spawner
@export var max_units: int = 5  

var spawned_units = []  # Stores references to spawned pawns

signal unit_spawned(unit)

func _ready():
	add_to_group("spawners")

func spawn_unit():
	if spawned_units.size() >= max_units:
		print("Max units reached")
		return
	
	var new_pawn = pawn_scene.instantiate()
	new_pawn.global_position = global_position + spawn_position_offset
	get_tree().current_scene.add_child(new_pawn)
	spawned_units.append(new_pawn)
	
	unit_spawned.emit(new_pawn)
	
	# Clean up dead units from list
	new_pawn.tree_exited.connect(func(): spawned_units.erase(new_pawn))

func _input_event(_viewport, event, _shape_idx):
	# If clicked, spawn a unit
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("pressed!!")
		spawn_unit()
		get_viewport().set_input_as_handled()
