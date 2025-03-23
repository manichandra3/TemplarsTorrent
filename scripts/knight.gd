extends CharacterBody2D

enum KNIGHT_STATE {
	IDLE,
	RUNNING,
	ATTACKING
}

@export var health: float = 20
@export var movement_speed: float = 200.0 
@export var acceleration: float = 500.0
#@export var arrival_threshold: float = 5.0
@export var entity_type: String = "knight"

var current_state: KNIGHT_STATE = KNIGHT_STATE.IDLE
var is_selected: bool = false
var is_selection_changed: bool = false
var target_enemy: Node2D = null  # For targeting enemies to attack

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $knight_animated
@onready var main = get_node("/root/game")

signal state_changed(new_state: KNIGHT_STATE)

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
	target_enemy = null  # Reset target enemy
	# Check if clicked on an enemy
	for hit in result:
		var collider = hit.get("collider", null)
		if collider and collider.is_in_group("goblins"):
			print("enemy found")
			target_enemy = collider
			break 
	navigation_agent.target_position = movement_target
	await get_tree().process_frame  # Wait for the path to be processed
	
	if navigation_agent.is_navigation_finished():
		return  # Stop execution if no path is found
	
	if target_enemy:
		change_state(KNIGHT_STATE.ATTACKING)
	else:
		change_state(KNIGHT_STATE.RUNNING)

func _physics_process(delta):
	match current_state:
		KNIGHT_STATE.IDLE:
			handle_idle_state(delta)
		KNIGHT_STATE.RUNNING:
			handle_running_state(delta)
		KNIGHT_STATE.ATTACKING:
			handle_attacking_state(delta)

func handle_idle_state(_delta):
	velocity = Vector2.ZERO
	animated_sprite.play("idle")

func handle_running_state(delta):
	if navigation_agent.is_navigation_finished():
		if target_enemy:
			change_state(KNIGHT_STATE.ATTACKING)
		else:
			change_state(KNIGHT_STATE.IDLE)
		return
	
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var desired_velocity = global_position.direction_to(next_path_position) * movement_speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	
	if velocity.length() > 0:
		animated_sprite.play("running")
		animated_sprite.flip_h = velocity.x < 0
	navigation_agent.velocity = velocity
	move_and_slide()

func handle_attacking_state(_delta):
	print(target_enemy)
	if target_enemy:
		if not is_instance_valid(target_enemy):
			# Enemy has been destroyed
			change_state(KNIGHT_STATE.IDLE)
			return
		if global_position.distance_to(target_enemy.global_position) > 30.0:
			# Enemy too far, move towards it
			set_movement_target(target_enemy.global_position)
			return
		# We're close enough to attack
		animated_sprite.play("attacking")
		# Face the enemy
		animated_sprite.flip_h = target_enemy.global_position.x < global_position.x
		# Damage logic 
		if target_enemy.has_method("take_damage"):
			target_enemy.take_damage(1) 
		await get_tree().create_timer(1.0).timeout
	else:
		change_state(KNIGHT_STATE.IDLE)

func change_state(new_state: KNIGHT_STATE):
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(new_state)

func select():
	is_selected = true
	animated_sprite.modulate = Color(1, 1, 0)

func deselect():
	is_selected = false
	animated_sprite.modulate = Color(1, 1, 1)
