extends CharacterBody2D

enum ARCHER_STATE {
	IDLE,
	RUNNING,
	ATTACKING,
	COOLDOWN  # New state to handle post-attack cooldown
}

@export var health: float = 100.0
@export var movement_speed: float = 250.0 
@export var acceleration: float = 500.0
@export var attack_damage: float = 15.0
@export var attack_cooldown: float = 0.75
@export var entity_type: String = "archer"
@export var detection_radius: float = 350.0
@export var attack_range: float = 300.0
@export var projectile_speed: float = 400.0
@export var projectile_offset: Vector2 = Vector2(20, -10)

var current_state: ARCHER_STATE = ARCHER_STATE.IDLE
var is_selected: bool = false
var target_enemy: Node2D = null
var attack_timer: Timer = null
var target_check_timer: Timer = null  
var state_handlers = {}
var last_attack_time: float = 0.0
var can_attack: bool = true
var forced_movement: bool = false  # Flag to track if player is forcing movement

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $ArcherAnimated
@onready var main = get_node("/root/game")
@onready var enemy_detector: Area2D = $EnemyDetector
@onready var health_bar = $HealthBar
@onready var projectile_scene = preload("res://scenes/arrow.tscn")

signal state_changed(new_state: ARCHER_STATE)

func _ready():
	add_to_group("pawns")
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 15.0
	health_bar.init_bar(health)

	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_finished)
	add_child(attack_timer)

	target_check_timer = Timer.new()
	target_check_timer.wait_time = 0.5
	target_check_timer.one_shot = false
	target_check_timer.timeout.connect(find_closest_enemy)
	add_child(target_check_timer)
	target_check_timer.start()

	main.entity_move_requested.connect(_on_entity_move_requested)
	main.selection_changed.connect(_on_selection_changed)

	input_pickable = true

	state_handlers = {
		ARCHER_STATE.IDLE: handle_idle_state,
		ARCHER_STATE.RUNNING: handle_running_state,
		ARCHER_STATE.ATTACKING: handle_attacking_state,
		ARCHER_STATE.COOLDOWN: handle_cooldown_state
	}

func _physics_process(delta):
	state_handlers[current_state].call(delta)

func handle_idle_state(_delta):
	velocity = Vector2.ZERO
	animated_sprite.play("idle")
	
	# Only auto-detect enemies when not being directly controlled
	if not forced_movement:
		find_closest_enemy()

func handle_cooldown_state(_delta):
	velocity = Vector2.ZERO
	animated_sprite.play("idle")  # You might want a cooldown animation
	
	if can_attack and target_enemy and is_instance_valid(target_enemy):
		var distance = global_position.distance_to(target_enemy.global_position)
		if distance <= attack_range:
			change_state(ARCHER_STATE.ATTACKING)
		else:
			navigation_agent.target_position = target_enemy.global_position
			change_state(ARCHER_STATE.RUNNING)

func find_closest_enemy():
	var bodies = enemy_detector.get_overlapping_bodies()
	var previous_target = target_enemy
	target_enemy = null
	var closest_distance = detection_radius
	
	for body in bodies:
		if body.is_in_group("goblins"):
			var distance = global_position.distance_to(body.global_position)
			if distance < closest_distance:
				closest_distance = distance
				target_enemy = body

	# Only change to attacking if we're not being directly controlled
	if target_enemy and current_state == ARCHER_STATE.IDLE and not forced_movement:
		change_state(ARCHER_STATE.ATTACKING)
	elif not target_enemy and previous_target and current_state == ARCHER_STATE.ATTACKING:
		change_state(ARCHER_STATE.IDLE)

func handle_running_state(delta):
	if navigation_agent.is_navigation_finished():
		forced_movement = false  # Reset forced movement flag when destination is reached
		change_state(ARCHER_STATE.IDLE)
		return

	var next_path_position = navigation_agent.get_next_path_position()
	var desired_velocity = global_position.direction_to(next_path_position) * movement_speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)

	if velocity.length() > 0:
		animated_sprite.play("running")
		animated_sprite.flip_h = velocity.x < 0

	move_and_slide()

func handle_attacking_state(_delta):
	if not target_enemy or not is_instance_valid(target_enemy):
		target_enemy = null
		change_state(ARCHER_STATE.IDLE)
		return

	var distance = global_position.distance_to(target_enemy.global_position)
	if distance > attack_range:
		if not forced_movement:
			navigation_agent.target_position = target_enemy.global_position
			change_state(ARCHER_STATE.RUNNING)
		else:
			change_state(ARCHER_STATE.IDLE)
		return

	velocity = Vector2.ZERO
	
	# Face the target
	animated_sprite.flip_h = target_enemy.global_position.x < global_position.x
	
	if can_attack:
		perform_attack()
		can_attack = false
		change_state(ARCHER_STATE.COOLDOWN)

func perform_attack():
	animated_sprite.play("attack")  # Ensure you have an attack animation
	last_attack_time = Time.get_ticks_msec() / 1000.0
	attack_timer.start()
	shoot_projectile()

func shoot_projectile():
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position + Vector2(
		projectile_offset.x * (-1 if animated_sprite.flip_h else 1),
		projectile_offset.y
	)
	
	# Ensure the projectile is targeting the current enemy position
	if target_enemy and is_instance_valid(target_enemy):
		projectile.direction = (target_enemy.global_position - global_position).normalized()
		projectile.atk = attack_damage
		projectile.speed = projectile_speed
		get_tree().current_scene.add_child(projectile)

func _on_attack_cooldown_finished():
	can_attack = true
	if current_state == ARCHER_STATE.COOLDOWN:
		if target_enemy and is_instance_valid(target_enemy):
			var distance = global_position.distance_to(target_enemy.global_position)
			if distance <= attack_range:
				change_state(ARCHER_STATE.ATTACKING)
			else:
				change_state(ARCHER_STATE.IDLE)
		else:
			change_state(ARCHER_STATE.IDLE)

func change_state(new_state: ARCHER_STATE):
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(new_state)

func take_damage(damage: float):
	health -= damage
	health_bar.update_bar(health)
	if health <= 0:
		die()

func die():
	print("Archer died!")
	if attack_timer:
		attack_timer.queue_free()
	if target_check_timer:
		target_check_timer.queue_free()
	queue_free()

func _on_selection_changed(selected_entities: Array):
	is_selected = selected_entities.has(get_instance_id())
	modulate = Color(1, 1, 0) if is_selected else Color(1.0, 1.0, 1.0)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		main.emit_signal("entity_clicked", get_instance_id())

func _on_entity_move_requested(entity_id: int, target_position: Vector2):
	if entity_id == get_instance_id():
		# Set the forced movement flag to indicate player control
		forced_movement = true
		
		# Cancel any ongoing attack
		target_enemy = null
		can_attack = true  # Reset attack state
		if attack_timer and attack_timer.time_left > 0:
			attack_timer.stop()
		
		# Set new movement target
		set_movement_target(target_position)
		
func set_movement_target(movement_target: Vector2):
	navigation_agent.target_position = movement_target
	await get_tree().process_frame
	change_state(ARCHER_STATE.RUNNING)

# Let the player manually order attacks on specific targets
func set_attack_target(enemy: Node2D):
	if enemy and is_instance_valid(enemy) and enemy.is_in_group("goblins"):
		target_enemy = enemy
		forced_movement = true  # This is player-directed behavior
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= attack_range:
			change_state(ARCHER_STATE.ATTACKING)
		else:
			navigation_agent.target_position = enemy.global_position
			change_state(ARCHER_STATE.RUNNING)
