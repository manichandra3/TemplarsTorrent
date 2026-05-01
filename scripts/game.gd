extends Node2D

# Existing variables
@onready var ui_layer = preload("res://scenes/ui.tscn").instantiate()
@export var pawn_scene: PackedScene = preload("res://scenes/player_1/pawn_1.tscn")
@export var knight_scene: PackedScene = preload("res://scenes/player_1/knight_1.tscn")
var castle: StaticBody2D

func _ready() -> void:
	add_child(ui_layer) 
	castle = get_tree().get_first_node_in_group("castle")
	if not castle:
		push_error("Castle not found! Make sure it's in the 'castle' group")

# Resource Management
# Replace these functions in your original script

func add_wood(amount: int) -> void:
	ResourceManager.add_wood(amount)

func get_wood_count() -> int:
	return ResourceManager.get_wood_count()

func spend_wood(amount: int) -> bool:
	return ResourceManager.spend_wood(amount)

func add_gold(amount: int) -> void:
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

func spawn_unit(unit_scene: PackedScene) -> void:
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

func display_insufficient_resources(resource_name: String) -> void:
	print("Not enough ", resource_name, " to spawn a unit!")

