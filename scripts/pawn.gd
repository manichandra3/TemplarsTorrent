extends CharacterBody2D

enum PAWN_STATE {
	IDLE,
	RUNNING,
	BUILDING,
	CHOPPING,
	FETCHING
}

@export var movement_speed: float = 200.0
@export var acceleration: float = 500.0
@export var arrival_threshold: float = 5.0
@export var chopping_duration: float = 10.0  # Time taken to chop

var current_state: PAWN_STATE = PAWN_STATE.IDLE
var movement_target_position: Vector2 = Vector2.ZERO
var is_selected: bool = false 
var target_tree: Node2D = null
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $pawn_animated

signal state_changed(new_state: PAWN_STATE)

func _ready():
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 15.0

func set_movement_target(movement_target: Vector2):
	navigation_agent.target_position = movement_target
	if current_state == PAWN_STATE.IDLE:
		change_state(PAWN_STATE.RUNNING)

func _physics_process(delta):
	match current_state:
		PAWN_STATE.IDLE:
			_handle_idle_state(delta)
		PAWN_STATE.RUNNING:
			_handle_running_state(delta)
		PAWN_STATE.CHOPPING:
			_handle_chopping_state(delta)

func _handle_idle_state(_delta):
	velocity = Vector2.ZERO
	animated_sprite.play("idle")

func _handle_running_state(delta):
	if navigation_agent.is_navigation_finished():
		if target_tree:
			change_state(PAWN_STATE.CHOPPING)  # Switch to chopping when reaching tree
		else:
			change_state(PAWN_STATE.IDLE) # Switch to idle otherwise
		return
	
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var desired_velocity = global_position.direction_to(next_path_position) * movement_speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	
	if velocity.length() > 0:
		animated_sprite.play("running")
		animated_sprite.flip_h = velocity.x < 0
	
	navigation_agent.velocity = velocity
	move_and_slide()

func _handle_chopping_state(_delta):
	if target_tree:
		if global_position.distance_to(target_tree.global_position) < 30.0:
			animated_sprite.play("chopping")
			target_tree.chop_tree() 
			await get_tree().create_timer(chopping_duration).timeout
			target_tree = null # reset the target_tree to null
			change_state(PAWN_STATE.RUNNING)  # Go back to idle after chopping
		else:
			set_movement_target(target_tree.global_position)  # Keep moving

func change_state(new_state: PAWN_STATE):
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(new_state)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var clicked_position = get_global_mouse_position()
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = clicked_position
			var result = space_state.intersect_point(query)
			
			var found_target = false
			for hit in result:
				var collider = hit.get("collider", null)
				
				if collider:
					if is_selected and collider.is_in_group("trees"):
						set_movement_target(collider.global_position)
						target_tree = collider
						found_target = true
						break  
					
					elif collider is CharacterBody2D and collider != self:
						is_selected = true
						found_target = true
						break  
			
			if not found_target:
				if global_position.distance_to(clicked_position) < 20.0:
					is_selected = true
				elif is_selected:
					set_movement_target(clicked_position)
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and is_selected:
			deselect()

func deselect():
	is_selected = false
