extends CharacterBody2D

enum PAWN_STATE {
	IDLE,
	RUNNING,
	CHOPPING,
	CONSTRUCTING
}

@export var health: float = 20.0
@export var movement_speed: float = 200.0 
@export var acceleration: float = 500.0
@export var chopping_duration: float = 10.0
@export var constructing_duration: float = 10.0 
@export var entity_type: String = "pawn"

var current_state: PAWN_STATE = PAWN_STATE.IDLE
var is_selected: bool = false
var target_tree: Node2D = null
var target_tower: Node2D = null
var is_chopping: bool = false
var is_constructing: bool = false
var chopping_task: SceneTreeTimer = null  # Tracks chopping process
var constructing_task: SceneTreeTimer = null
var previous_position: Vector2

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $pawn_animated
@onready var main = get_node("/root/game")

signal state_changed(new_state: PAWN_STATE)

func _ready():
	add_to_group("pawns")

	# Navigation agent fine-tuning
	navigation_agent.path_desired_distance = 5.0
	navigation_agent.target_desired_distance = 6.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 150.0
	navigation_agent.avoidance_priority = 1.0

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
	if is_selected:
		select()
	else:
		deselect()
func set_movement_target(movement_target: Vector2):
	# Cancel chopping if moving elsewhere
	if is_chopping and target_tree:
		print("Chopping interrupted: Moving to new target.")
		target_tree.stop_chopping(self)
		is_chopping = false
		if chopping_task:
			chopping_task.timeout.disconnect(_on_chopping_complete)
			chopping_task = null
		change_state(PAWN_STATE.RUNNING)
	if is_constructing and target_tower:
		target_tower.stop_constructing(self)
		is_constructing = false
		print("lksjdflsdjoi")
		change_state(PAWN_STATE.RUNNING)

	# Reset target tree detection
	target_tree = null  
	target_tower = null
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = movement_target
	var result = space_state.intersect_point(query)
	print(result)
	
	# Check if moving to a tree
	for hit in result:
		var collider = hit.get("collider", null)
		if collider and collider.is_in_group("trees"):
			target_tree = collider
			break
		elif collider and collider.is_in_group("towers"):
			target_tower = collider 
			print("gg")
			break
	navigation_agent.target_position = movement_target
	await get_tree().process_frame

	# Update state
	if navigation_agent.is_navigation_finished():
		print("task")
		change_state(PAWN_STATE.IDLE)
	elif target_tree: 
		print("pp")
		change_state(PAWN_STATE.CHOPPING)
	elif target_tower:
		print("ff")
		if target_tower.is_destroyed():
			change_state(PAWN_STATE.CONSTRUCTING)
	else:
		print("oo")
		change_state(PAWN_STATE.RUNNING)
		
func _physics_process(delta):
	match current_state:
		PAWN_STATE.IDLE:
			handle_idle_state(delta)
		PAWN_STATE.RUNNING:
			handle_running_state(delta)
		PAWN_STATE.CHOPPING:
			handle_chopping_state(delta)
		PAWN_STATE.CONSTRUCTING:
				handle_constructing_state(delta)

func handle_constructing_state(delta):
	if not target_tower and target_tower.is_destroyed():
		change_state(PAWN_STATE.CONSTRUCTING)
		return
	if global_position.distance_to(target_tower.global_position) >60.0:
		set_movement_target(target_tower.global_position - Vector2(40, -30))
		return
	##print("ghk")
	if is_constructing:
		return
	if target_tower.is_destroyed():
		is_constructing = true
		animated_sprite.play("building")
		target_tower.construct_tower(self)
		print("dec")
		if not target_tower.is_connected("construction_complete", Callable(self, "_on_constructing_complete")):
			print("jec")
			target_tower.connect("construction_complete", Callable(self, "_on_constructing_complete"))


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
		if global_position.distance_to(previous_position) < 0.11:
			print("hi")
			change_state(PAWN_STATE.IDLE)
	previous_position = global_position

	navigation_agent.velocity = velocity
	move_and_slide()

func handle_chopping_state(_delta):
	if not target_tree and not target_tree.is_grown():
		change_state(PAWN_STATE.IDLE)
		return
	print(global_position.distance_to(target_tree.global_position))
	# Move closer to tree if too far
	if global_position.distance_to(target_tree.global_position) > 50.0:
		print("jjj")
		set_movement_target(target_tree.global_position - Vector2(20, -15))
		return  
	if is_chopping:
		return
	# Start chopping process
	if target_tree.is_grown():
		is_chopping = true
		animated_sprite.play("chopping")
		target_tree.chop_tree(self)

		# Cancel previous chopping task if any
		if chopping_task:
			chopping_task.timeout.disconnect(_on_chopping_complete)
		
		# Start new chopping timer
		chopping_task = get_tree().create_timer(chopping_duration)
		chopping_task.timeout.connect(_on_chopping_complete)

func _on_chopping_complete():
	print("Chopping complete")
	is_chopping = false
	target_tree = null
	change_state(PAWN_STATE.IDLE)
	
func _on_constructing_complete(constructing_unit):
	if constructing_unit == self:
		print("Construction complete! Stopping building animation.")
		is_constructing = false
		change_state(PAWN_STATE.IDLE)  # or any other animation/state change
		# Optionally, disconnect from the signal if you won't build again immediately.
		target_tower.disconnect("construction_complete", Callable(self, "_on_tower_constructed"))
		target_tower = null

func change_state(new_state: PAWN_STATE):
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(new_state)
func select():
	print("pawn selected")
	is_selected = true
	animated_sprite.self_modulate = Color(1, 1, 0, 1)  # Yellow

func deselect():
	print("Pawn deselected")
	is_selected = false
	animated_sprite.self_modulate = Color(1, 1, 1, 1)  # Normal white
	#animated_sprite.modulate = Color(1, 1, 1)

func take_damage(damage: float):
	health -= damage
	print("Pawn took ", damage, "damage! Health left:", health)

	if health <= 0:
		deselect()
		die()
func die():
	print("Pawn has died!")
	queue_free()  # Remove the pawn from the game
func stop_movement():
	move_and_slide()
	velocity = Vector2.ZERO
	print("Pawn stopped due to obstacle.")
