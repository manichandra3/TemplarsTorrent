extends Button

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
	castle = get_tree().get_first_node_in_group("castle")
	if not castle:
		push_error("Castle not found! Make sure it's in the 'castle' group")
		return
	
	var button = Button.new()
	button.text = "Spawn Pawn"
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(spawn_unit)
	
	var canvas_layer = CanvasLayer.new()
	var control = Control.new()
	control.anchor_bottom = 1.0
	control.anchor_right = 1.0
	control.margin_bottom = -20
	control.margin_right = -150
	control.add_child(button)
	
	canvas_layer.add_child(control)
	add_child(canvas_layer)

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
	
	var random_variation = Vector2(
		randf_range(-spawn_variation, spawn_variation),
		randf_range(-spawn_variation, spawn_variation)
	)
	var spawn_pos = castle.global_position + spawn_offset + random_variation
	
	var new_pawn = pawn_scene.instantiate()
	new_pawn.global_position = spawn_pos
	get_parent().add_child(new_pawn) 
	
	spawned_units.append(new_pawn)
	unit_spawned.emit(new_pawn)
	new_pawn.tree_exited.connect(_on_pawn_exited.bind(new_pawn))

func _on_pawn_exited(pawn: Node):
	if pawn in spawned_units:
		spawned_units.erase(pawn)
