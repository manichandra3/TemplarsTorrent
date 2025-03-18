extends CharacterBody2D

enum PAWN_STATE {
	IDLE,
	RUNNING,
	BUILDING,
	CHOPPING,
	FETCHING
}

@export var health: float = 100
@export var movement_speed: float = 200.0 
@export var acceleration: float = 500.0
#@export var arrival_threshold: float = 5.0
@export var chopping_duration: float = 10.0  # Time taken to chop a tree
@export var entity_type: String = "pawn"

var current_state: PAWN_STATE = PAWN_STATE.IDLE
var is_selected: bool = false
var is_selection_changed: bool = false
var target_tree: Node2D = null

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $pawn_animated
@onready var main = get_node("/root/game")

signal state_changed(new_state: PAWN_STATE)

func _ready():
	add_to_group("pawns")
	# Set up navigation agent
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 15.0
	# Connect signals
	main.entity_move_requested.connect(_on_entity_move_requested)
	main.selection_changed.connect(_on_selection_changed)
	# Enable input processing for this collider
	input_pickable = true

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		main.change_selected_unit(self)
		get_viewport().set_input_as_handled()

func _on_entity_move_requested(entity_id: int, target_position: Vector2):
	if entity_id == get_instance_id():
		set_movement_target(target_position)

func _on_selection_changed(new_selected):
	is_selected = (new_selected == self)
	animated_sprite.modulate = Color(1, 1, 0) if is_selected else Color(1, 1, 1)

func set_movement_target(movement_target: Vector2):
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = movement_target
	var result = space_state.intersect_point(query)
	target_tree = null  # Reset target tree
	for hit in result:
		var collider = hit.get("collider", null)
		if collider and collider.is_in_group("trees"):
			target_tree = collider
			break  # Stop checking other objects
		if collider and collider.is_in_group("pawns"):
			change_state(PAWN_STATE.IDLE)
	navigation_agent.target_position = movement_target
	await get_tree().process_frame  # Wait for the path to be processed
	if navigation_agent.is_navigation_finished():
		return  # Stop execution if no path is found
	if target_tree:
		change_state(PAWN_STATE.CHOPPING)
	else:
		change_state(PAWN_STATE.RUNNING)

func _physics_process(delta):
	match current_state:
		PAWN_STATE.IDLE:
			handle_idle_state(delta)
		PAWN_STATE.RUNNING:
			handle_running_state(delta)
		PAWN_STATE.CHOPPING:
			handle_chopping_state(delta)

func handle_idle_state(_delta):
	velocity = Vector2.ZERO
	animated_sprite.play("idle")

func handle_running_state(delta):
	if navigation_agent.is_navigation_finished():
		if target_tree:
			change_state(PAWN_STATE.CHOPPING)
		else:
			change_state(PAWN_STATE.IDLE)
		return
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var desired_velocity = global_position.direction_to(next_path_position) * movement_speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	if velocity.length() > 0:
		animated_sprite.play("running")
		animated_sprite.flip_h = velocity.x < 0
	navigation_agent.velocity = velocity
	move_and_slide()

func handle_chopping_state(_delta):
	if target_tree :
		if global_position.distance_to(target_tree.global_position) > 30.0 :
			set_movement_target(target_tree.global_position)
			return
		animated_sprite.play("chopping")
		target_tree.chop_tree()
		await get_tree().create_timer(chopping_duration).timeout
		target_tree = null  # Reset target
	else:
		change_state(PAWN_STATE.IDLE)

func change_state(new_state: PAWN_STATE):
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(new_state)

func select():
	is_selected = true
	animated_sprite.modulate = Color(1, 1, 0)

func deselect():
	is_selected = false
	animated_sprite.modulate = Color(1, 1, 1)
