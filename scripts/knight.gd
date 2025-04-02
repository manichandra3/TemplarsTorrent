extends CharacterBody2D

enum KNIGHT_STATE {
	IDLE,
	RUNNING,
	ATTACKING,
	DESTRUCTING
}

@export var health: float = 300.0
@export var movement_speed: float = 200.0 
@export var acceleration: float = 500.0
@export var attack_damage: float = 20.0
@export var attack_cooldown: float = 1.0
@export var entity_type: String = "knight"
@export var detection_radius: float = 150.0  # Auto-detect range
# NEW: The distance at which the knight prefers to attack from.
@export var preferred_attack_distance: float = 50.0
@export var destructing_duration: float = 10.0 
var target_tower: Node2D = null
var is_destructing: bool = false
var destructing_task: SceneTreeTimer = null

var current_state: KNIGHT_STATE = KNIGHT_STATE.IDLE
var is_selected: bool = false
var target_enemy: Node2D = null
var is_attacking: bool = false
var attack_timer: Timer = null
var target_check_timer: Timer = null  
var previous_position: Vector2


@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $knight_animated
@onready var health_bar = $HealthBar
@onready var main = get_node("/root/game")

signal state_changed(new_state: KNIGHT_STATE)

func _ready():
	add_to_group("pawns")
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 15.0
	health_bar.init_bar(health)
	
	# Attack timer
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_finished)
	add_child(attack_timer)
	
	# Enemy detection timer
	target_check_timer = Timer.new()
	target_check_timer.wait_time = 0.5
	target_check_timer.one_shot = false
	target_check_timer.timeout.connect(_on_check_for_enemies)
	add_child(target_check_timer)
	target_check_timer.start()

	# Connect signals
	main.entity_move_requested.connect(_on_entity_move_requested)
	main.selection_changed.connect(_on_selection_changed)

	# Enable input
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
	if is_destructing and target_tower:
		target_tower.stop_destructing(self)
		is_destructing = false
		print("lksjdflsdjoi")
		change_state(KNIGHT_STATE.RUNNING)
	if current_state == KNIGHT_STATE.ATTACKING:
		is_attacking = false
		if attack_timer.time_left > 0:
			attack_timer.stop()
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = movement_target
	var result = space_state.intersect_point(query)
	target_enemy = null 
	target_tower = null
	
	print(result)
	for hit in result:
		var collider = hit.get("collider", null)
		if collider and collider.is_in_group("goblins"):
			target_enemy = collider
			break 
		elif collider and collider.is_in_group("towers"):
			target_tower = collider 
			print("gg")
			break

	navigation_agent.target_position = movement_target
	await get_tree().process_frame  
	
	print(target_tower)
	if target_enemy:
		change_state(KNIGHT_STATE.ATTACKING)
	elif target_tower:
		print("ff")
		if target_tower.is_built():
			change_state(KNIGHT_STATE.DESTRUCTING)
	else:
		change_state(KNIGHT_STATE.RUNNING)

func _on_check_for_enemies():
	if current_state == KNIGHT_STATE.IDLE or (current_state == KNIGHT_STATE.RUNNING and navigation_agent.is_navigation_finished()):
		find_closest_enemy()

func find_closest_enemy():
	if target_enemy and is_instance_valid(target_enemy):
		return  
		
	var nearby_enemies = get_tree().get_nodes_in_group("goblins")
	var closest_enemy = null
	var closest_distance = detection_radius
	
	for enemy in nearby_enemies:
		if not is_instance_valid(enemy):
			continue
			
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	
	if closest_enemy:
		target_enemy = closest_enemy
		change_state(KNIGHT_STATE.ATTACKING)

func _physics_process(delta):
	match current_state:
		KNIGHT_STATE.IDLE:
			handle_idle_state()
		KNIGHT_STATE.RUNNING:
			handle_running_state(delta)
		KNIGHT_STATE.ATTACKING:
			handle_attacking_state(delta)
		KNIGHT_STATE.DESTRUCTING:
			handle_destructing_state(delta)

func handle_idle_state():
	velocity = Vector2.ZERO
	animated_sprite.play("idle")

func handle_running_state(delta):
	if navigation_agent.is_navigation_finished():
		if target_enemy and is_instance_valid(target_enemy):
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
		if global_position.distance_to(previous_position) < 0.11:
			print("hi")
			change_state(KNIGHT_STATE.IDLE)
		previous_position = global_position

	navigation_agent.velocity = velocity
	move_and_slide()
	
func handle_attacking_state(_delta):
	if not target_enemy or not is_instance_valid(target_enemy):
		# Enemy is gone or dead
		target_enemy = null
		change_state(KNIGHT_STATE.IDLE)
		return

	var direction = (target_enemy.global_position - global_position).normalized()
	var distance_to_enemy = global_position.distance_to(target_enemy.global_position)
	# Define a tolerance (in pixels) around the preferred attack distance.
	var tolerance = 10.0

	# Instead of approaching until too close, we maintain the preferred attack distance.
	if abs(distance_to_enemy - preferred_attack_distance) > tolerance:
		# Calculate a target position that is exactly 'preferred_attack_distance' away from the enemy.
		var target_position = target_enemy.global_position - direction * preferred_attack_distance
		navigation_agent.target_position = target_position
		var next_path_position = navigation_agent.get_next_path_position()
		var desired_velocity = global_position.direction_to(next_path_position) * movement_speed
		velocity = velocity.move_toward(desired_velocity, acceleration * _delta)
		animated_sprite.play("running")
		animated_sprite.flip_h = velocity.x < 0
		move_and_slide()
		return

	# At the proper distance: stop moving and attack.
	velocity = Vector2.ZERO
	_play_attack_animation(direction)
	if not is_attacking:
		perform_attack()

func _play_attack_animation(direction: Vector2):
	# Determine the attack animation based on the enemy's location
	if direction.y < 0:
		animated_sprite.play("attacking_north")
	elif direction.y > 0:
		animated_sprite.play("attacking_south")
	else:
		animated_sprite.play("attacking_west")
		animated_sprite.flip_h = (direction.x < 0)

func perform_attack():
	is_attacking = true
	attack_timer.start()
	if target_enemy and is_instance_valid(target_enemy):
		var direction = (target_enemy.global_position - global_position).normalized()
		_play_attack_animation(direction)
		if target_enemy.has_method("take_damage"):
			target_enemy.take_damage(attack_damage)

func _on_attack_cooldown_finished():
	is_attacking = false
	if current_state == KNIGHT_STATE.ATTACKING and target_enemy and is_instance_valid(target_enemy):
		perform_attack()  # Continue attacking if still in range

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

func take_damage(damage: float):
	health -= damage
	health_bar.update_bar(health)
	if current_state != KNIGHT_STATE.ATTACKING and current_state != KNIGHT_STATE.RUNNING:
		for goblin in get_tree().get_nodes_in_group("goblins"):
			if goblin.target == self:
				target_enemy = goblin
				change_state(KNIGHT_STATE.ATTACKING)
				break
	if health <= 0:
		die()

func die():
	print("Pawn died!")
	if attack_timer:
		attack_timer.queue_free()
	if target_check_timer:
		target_check_timer.queue_free()
	queue_free()
#========================================================================================================================
#========================================================================================================================
#========================================================================================================================


func handle_destructing_state(delta):
	print("hello")
	if not target_tower and target_tower.is_built():
		change_state(KNIGHT_STATE.DESTRUCTING)
		return
	print("kello")
	print(global_position.distance_to(target_tower.global_position))
	if global_position.distance_to(target_tower.global_position) >90.0:
		set_movement_target(target_tower.global_position - Vector2(50, -40))
		print("gello")
		return
	print("ghk")
	if is_destructing:
		return
	if target_tower.is_built():
		is_destructing = true
		animated_sprite.play("attacking_north_ltr")
		target_tower.destroy_tower(self)
		print("dec")
		if not target_tower.is_connected("destruction_complete", Callable(self, "_on_destructing_complete")):
			print("jec")
			target_tower.connect("destruction_complete", Callable(self, "_on_destructing_complete"))

func _on_destructing_complete(destructing_unit):
	print("braha")
	if destructing_unit == self:
		print("Building Complete")
		is_destructing = false
		change_state(KNIGHT_STATE.IDLE)
		target_tower.disconnect("destruction_complete", Callable(self, "_on_destructing_completed"))
		target_tower = null
