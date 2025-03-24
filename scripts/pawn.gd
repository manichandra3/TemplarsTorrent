extends CharacterBody2D

enum PAWN_STATE {
	IDLE,
	RUNNING,
	CHOPPING
}

@export var health: float = 20.0
@export var movement_speed: float = 200.0 
@export var acceleration: float = 500.0
@export var chopping_duration: float = 10.0 
@export var entity_type: String = "pawn"

var current_state: PAWN_STATE = PAWN_STATE.IDLE
var is_selected: bool = false
var target_tree: Node2D = null
var is_chopping: bool = false
var chopping_task: SceneTreeTimer = null

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $pawn_animated
@onready var main = get_node("/root/game")

signal state_changed(new_state: PAWN_STATE)

func _ready():
	add_to_group("pawns")
	navigation_agent.path_desired_distance = 5.0
	navigation_agent.target_desired_distance = 6.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 16.0
	navigation_agent.avoidance_priority = 1.0

	main.entity_move_requested.connect(_on_entity_move_requested)
	main.selection_changed.connect(_on_selection_changed)
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
	# Cancel any existing chopping
	if is_chopping and target_tree:
		target_tree.stop_chopping(self)
		is_chopping = false
		if chopping_task:
			chopping_task.timeout.disconnect(_on_chopping_complete)
			chopping_task = null
	
	# Reset target tree detection
	target_tree = null  
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = movement_target
	var result = space_state.intersect_point(query)

	# Check if moving to a tree
	for hit in result:
		var collider = hit.get("collider", null)
		if collider and collider.is_in_group("trees"):
			target_tree = collider
			break  
	
	navigation_agent.target_position = movement_target
	await get_tree().process_frame

	# Update state
	if navigation_agent.is_navigation_finished():
		change_state(PAWN_STATE.IDLE)
	elif target_tree:
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
		change_state(PAWN_STATE.IDLE)
		

	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var desired_velocity = global_position.direction_to(next_path_position) * movement_speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)

	if velocity.length() > 0:
		animated_sprite.play("running")
		animated_sprite.flip_h = velocity.x < 0

	navigation_agent.velocity = velocity
	move_and_slide()

func handle_chopping_state(_delta):
	if not target_tree and not target_tree.is_grown():
		print("change instance 1")
		change_state(PAWN_STATE.IDLE)
		return
	
	# Move closer to tree if too far
	if global_position.distance_to(target_tree.global_position) > 30.0:
		set_movement_target(target_tree.global_position - Vector2(20, -10))
		return  

	if is_chopping:
		return

	# Start chopping process
	is_chopping = true
	animated_sprite.play("chopping")
	target_tree.chop_tree(self)

	# Start chopping timer
	chopping_task = get_tree().create_timer(chopping_duration)
	chopping_task.timeout.connect(_on_chopping_complete)

func _on_chopping_complete():
	print("Chopping complete")
	is_chopping = false
	target_tree = null
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

func take_damage(damage: float):
	health -= damage
	print("Pawn took ", damage, "damage! Health left:", health)

	if health <= 0:
		die()

func die():
	print("Pawn has died!")
	queue_free()
