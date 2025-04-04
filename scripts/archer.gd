extends CharacterBody2D

enum ARCHER_STATE {
	IDLE,
	RUNNING,
	ATTACKING,
	COOLDOWN 
}

@export var health: float = 100.0
@export var movement_speed: float = 250.0 
@export var acceleration: float = 500.0
@export var attack_damage: float = 15.0
@export var attack_cooldown: float = 0.75
@export var entity_type: String = "archer"
@export var detection_radius: float = 300.0
@export var attack_range: float = 300.0
# NEW: The distance at which the archer prefers to attack from (optimal distance)
@export var preferred_attack_distance: float = 100.0
@export var projectile_speed: float = 400.0
@export var projectile_offset: Vector2 = Vector2(20, -10)

var current_state: ARCHER_STATE = ARCHER_STATE.IDLE
var is_selected: bool = false
var target_enemy: Node2D = null
var attack_timer: Timer = null
var target_check_timer: Timer = null  
var can_attack: bool = true
var forced_movement: bool = false  # Flag to track if player is forcing movement

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $ArcherAnimated
@onready var main = get_node("/root/game")
@onready var health_bar = $HealthBar
@onready var projectile_scene = preload("res://scenes/player_1/arrow_1.tscn")

signal state_changed(new_state: ARCHER_STATE)

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
		forced_movement = true
		set_movement_target(target_position)

func _on_selection_changed(new_selected):
	is_selected = (new_selected == self)
	animated_sprite.modulate = Color(1, 1, 0) if is_selected else Color(1, 1, 1)
	print("Selection Changed:", is_selected)

func set_movement_target(movement_target: Vector2):
	if current_state == ARCHER_STATE.ATTACKING or current_state == ARCHER_STATE.COOLDOWN:
		can_attack = true
		if attack_timer.time_left > 0:
			attack_timer.stop()
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = movement_target
	var result = space_state.intersect_point(query)
	target_enemy = null  

	for hit in result:
		var collider = hit.get("collider", null)
		if collider and collider.is_in_group("goblins"):
			target_enemy = collider
			break 

	navigation_agent.target_position = movement_target
	await get_tree().process_frame  

	if target_enemy:
		change_state(ARCHER_STATE.ATTACKING)
	else:
		change_state(ARCHER_STATE.RUNNING)

func _on_check_for_enemies():
	if not forced_movement and (current_state == ARCHER_STATE.IDLE or (current_state == ARCHER_STATE.RUNNING and navigation_agent.is_navigation_finished())):
		find_closest_enemy()

func find_closest_enemy():
	if forced_movement or (target_enemy and is_instance_valid(target_enemy)):
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
		change_state(ARCHER_STATE.ATTACKING)

func _physics_process(delta):
	match current_state:
		ARCHER_STATE.IDLE:
			handle_idle_state(delta)
		ARCHER_STATE.RUNNING:
			handle_running_state(delta)
		ARCHER_STATE.ATTACKING:
			handle_attacking_state(delta)
		ARCHER_STATE.COOLDOWN:
			handle_cooldown_state(delta)

func handle_idle_state(_delta):
	velocity = Vector2.ZERO
	animated_sprite.play("idle")

func handle_cooldown_state(_delta):
	velocity = Vector2.ZERO
	animated_sprite.play("idle")
	
	if can_attack and target_enemy and is_instance_valid(target_enemy):
		var distance = global_position.distance_to(target_enemy.global_position)
		if distance <= attack_range:
			change_state(ARCHER_STATE.ATTACKING)
		else:
			navigation_agent.target_position = target_enemy.global_position
			change_state(ARCHER_STATE.RUNNING)

func handle_running_state(delta):
	if navigation_agent.is_navigation_finished():
		forced_movement = false  # Reset forced movement flag when destination is reached
		if target_enemy and is_instance_valid(target_enemy):
			change_state(ARCHER_STATE.ATTACKING)
		else:
			change_state(ARCHER_STATE.IDLE)
		return

	var next_path_position = navigation_agent.get_next_path_position()
	var desired_velocity = global_position.direction_to(next_path_position) * movement_speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)

	if velocity.length() > 0:
		animated_sprite.play("running")
		animated_sprite.flip_h = velocity.x < 0

	navigation_agent.velocity = velocity
	move_and_slide()

func handle_attacking_state(delta):
	if not target_enemy or not is_instance_valid(target_enemy):
		target_enemy = null
		change_state(ARCHER_STATE.IDLE)
		return

	var direction = (target_enemy.global_position - global_position).normalized()
	var distance_to_enemy = global_position.distance_to(target_enemy.global_position)
	
	# tolerance (in pixels) around the preferred attack distance.
	var tolerance = 20.0
	
	# Only approach if we're outside attack range
	if distance_to_enemy > attack_range:
		navigation_agent.target_position = target_enemy.global_position
		var next_path_position = navigation_agent.get_next_path_position()
		var desired_velocity = global_position.direction_to(next_path_position) * movement_speed
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)
		animated_sprite.play("running")
		animated_sprite.flip_h = velocity.x < 0
		move_and_slide()
		return
		
	# If we're within attack range but not at preferred distance, try to maintain optimal distance
	if distance_to_enemy <= attack_range and abs(distance_to_enemy - preferred_attack_distance) > tolerance:
		# If too close, move away; if too far, move closer
		var target_position = target_enemy.global_position - direction * preferred_attack_distance
		navigation_agent.target_position = target_position
		var next_path_position = navigation_agent.get_next_path_position()
		var desired_velocity = global_position.direction_to(next_path_position) * movement_speed
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)
		animated_sprite.play("running")
		animated_sprite.flip_h = velocity.x < 0
		move_and_slide()
		return

	# At proper distance and within attack range: stop and attack
	velocity = Vector2.ZERO
	_play_attack_animation(direction)
	
	if can_attack:
		perform_attack()
		can_attack = false
		change_state(ARCHER_STATE.COOLDOWN)

func _play_attack_animation(direction: Vector2):
	animated_sprite.flip_h = direction.x < 0
	
	if direction.y < -0.5: 
		animated_sprite.play("attack_north")
	elif direction.y > 0.5:  
		animated_sprite.play("attack_south")
	else: 
		animated_sprite.play("attack")  

func perform_attack():
	animated_sprite.play("attack") 
	attack_timer.start()
	shoot_projectile()

func shoot_projectile():
	var projectile = projectile_scene.instantiate()
	
	# Calculate proper offset based on character direction
	var offset = Vector2(
		projectile_offset.x * (-1 if animated_sprite.flip_h else 1),
		projectile_offset.y
	)
	
	projectile.global_position = global_position + offset
	
	if target_enemy and is_instance_valid(target_enemy):
		projectile.direction = (target_enemy.global_position - global_position).normalized()
		projectile.atk = attack_damage
		projectile.speed = projectile_speed
		get_tree().current_scene.add_child(projectile)

func _on_attack_cooldown_finished():
	can_attack = true
	if current_state == ARCHER_STATE.COOLDOWN:
		if target_enemy and is_instance_valid(target_enemy):
			change_state(ARCHER_STATE.ATTACKING)
		else:
			change_state(ARCHER_STATE.IDLE)

func change_state(new_state: ARCHER_STATE):
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(new_state)

func take_damage(damage: float):
	health -= damage
	health_bar.update_bar(health)
	
	# If not already attacking, respond to being attacked
	if current_state != ARCHER_STATE.ATTACKING and current_state != ARCHER_STATE.RUNNING:
		for goblin in get_tree().get_nodes_in_group("goblins"):
			if goblin.target == self:
				target_enemy = goblin
				change_state(ARCHER_STATE.ATTACKING)
				break
				
	if health <= 0:
		die()

func die():
	print("Archer died!")
	if attack_timer:
		attack_timer.queue_free()
	if target_check_timer:
		target_check_timer.queue_free()
	queue_free()

func select():
	is_selected = true
	print("selected archer")
	animated_sprite.modulate = Color(1, 1, 0)

func deselect():
	is_selected = false
	print("deselected archer")
	animated_sprite.modulate = Color(1, 1, 1)
