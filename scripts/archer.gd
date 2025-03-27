extends CharacterBody2D

enum ARCHER_STATE {
	IDLE,
	RUNNING,
	ATTACKING
}

@export var health: float = 100.0
@export var movement_speed: float = 250.0 
@export var acceleration: float = 500.0
@export var attack_damage: float = 15.0
@export var attack_cooldown: float = 0.75
@export var entity_type: String = "archer"
@export var detection_radius: float = 350.0  # Increased detection range
@export var attack_range: float = 300.0      # Increased attack range
@export var projectile_speed: float = 400.0  # Added projectile speed
@export var projectile_offset: Vector2 = Vector2(20, -10) # Visual offset for arrow spawn

var current_state: ARCHER_STATE = ARCHER_STATE.IDLE
var is_selected: bool = false
var target_enemy: Node2D = null
var is_attacking: bool = false
var attack_timer: Timer = null
var target_check_timer: Timer = null  

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $ArcherAnimated
@onready var main = get_node("/root/game")

signal state_changed(new_state: ARCHER_STATE)

func _ready():
	add_to_group("pawns")
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 15.0

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
	if current_state == ARCHER_STATE.ATTACKING:
		is_attacking = false
		if attack_timer.time_left > 0:
			attack_timer.stop()
	
	target_enemy = find_best_enemy_in_radius(detection_radius)
	navigation_agent.target_position = movement_target
	await get_tree().process_frame  

	if target_enemy:
		change_state(ARCHER_STATE.ATTACKING)
	else:
		change_state(ARCHER_STATE.RUNNING)

func _on_check_for_enemies():
	if current_state == ARCHER_STATE.IDLE or (current_state == ARCHER_STATE.RUNNING and navigation_agent.is_navigation_finished()):
		find_closest_enemy()

func find_best_enemy_in_radius(radius: float) -> Node2D:
	var nearby_enemies = get_tree().get_nodes_in_group("goblins")
	var best_enemy = null
	var closest_distance = radius
	
	for enemy in nearby_enemies:
		if not is_instance_valid(enemy):
			continue
			
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			best_enemy = enemy
	
	return best_enemy

func find_closest_enemy():
	if target_enemy and is_instance_valid(target_enemy):
		return  
	target_enemy = find_best_enemy_in_radius(detection_radius)
	if target_enemy:
		change_state(ARCHER_STATE.ATTACKING)

func _physics_process(delta):
	match current_state:
		ARCHER_STATE.IDLE:
			handle_idle_state()
		ARCHER_STATE.RUNNING:
			handle_running_state(delta)
		ARCHER_STATE.ATTACKING:
			handle_attacking_state(delta)

func handle_idle_state():
	velocity = Vector2.ZERO
	animated_sprite.play("idle")
	# Check for enemies periodically even when idle
	find_closest_enemy()

func handle_running_state(delta):
	if navigation_agent.is_navigation_finished():
		if target_enemy and is_instance_valid(target_enemy):
			change_state(ARCHER_STATE.ATTACKING)
		else:
			change_state(ARCHER_STATE.IDLE)
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
	if not target_enemy or not is_instance_valid(target_enemy):
		target_enemy = null
		change_state(ARCHER_STATE.IDLE)
		return

	# Face the enemy
	var direction_to_enemy = (target_enemy.global_position - global_position).normalized()
	animated_sprite.flip_h = direction_to_enemy.x < 0

	var distance_to_enemy = global_position.distance_to(target_enemy.global_position)
	if distance_to_enemy > attack_range:
		# Move toward enemy if out of range
		navigation_agent.target_position = target_enemy.global_position
		change_state(ARCHER_STATE.RUNNING)
		return

	velocity = Vector2.ZERO
	animated_sprite.play("attacking")
	if not is_attacking:
		perform_attack()

func perform_attack():
	is_attacking = true
	attack_timer.start()
	shoot_projectile()

func shoot_projectile():
	var projectile = preload("res://scenes/arrow.tscn").instantiate()
	# Apply visual offset based on facing direction
	var spawn_position = global_position + Vector2(
		projectile_offset.x * (-1 if animated_sprite.flip_h else 1),
		projectile_offset.y
	)
	projectile.global_position = spawn_position
	projectile.direction = (target_enemy.global_position - spawn_position).normalized()
	projectile.atk = attack_damage
	projectile.speed = projectile_speed
	get_tree().current_scene.add_child(projectile)

func _on_attack_cooldown_finished():
	is_attacking = false
	if current_state == ARCHER_STATE.ATTACKING and target_enemy and is_instance_valid(target_enemy):
		perform_attack()

func change_state(new_state: ARCHER_STATE):
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(new_state)

func take_damage(damage: float):
	print("take damage method called")
	health -= damage
	if health <= 0:
		die()

func die():
	print("Archer died!")
	if attack_timer:
		attack_timer.queue_free()
	if target_check_timer:
		target_check_timer.queue_free()
	queue_free()
