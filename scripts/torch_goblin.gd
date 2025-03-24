extends CharacterBody2D

enum AI_STATE {
	IDLE,
	CHASING,
	ATTACKING,
	RETURNING
}

@export var speed: float = 100.0
@export var attack_range: float = 50.0  
@export var detection_radius: float = 200.0  
@export var max_distance_from_tower: float = 350.0  
@export var health: float = 15.0  
@export var attack_damage: float = 10.0  
@export var attack_cooldown: float = 1.0  

var target: Node2D = null
var home_tower: Node2D = null
var current_state: AI_STATE = AI_STATE.IDLE
var is_attacking: bool = false
var attack_timer: Timer = null
var wander_timer: Timer = null
var random_offset: Vector2 = Vector2.ZERO

@onready var navigation_agent = $NavigationAgent2D
@onready var sprite = $AnimatedTorchGoblin

func _ready():
	add_to_group('goblins')
	
	# Set up navigation
	navigation_agent.path_desired_distance = 5.0
	navigation_agent.target_desired_distance = 6.0
	navigation_agent.avoidance_enabled = true
	
	# Set up attack timer
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_finished)
	add_child(attack_timer)
	
	# Set up wander timer for random movement
	wander_timer = Timer.new()
	wander_timer.wait_time = randf_range(3.0, 7.0)  # Randomize wandering intervals
	wander_timer.timeout.connect(_on_wander_timeout)
	wander_timer.start()
	add_child(wander_timer)
	
	# Find parent tower on initialization
	find_home_tower()

func find_home_tower():
	var towers = get_tree().get_nodes_in_group("goblin_towers")
	var closest_distance = INF
	var closest_tower = null
	
	for tower in towers:
		var distance = global_position.distance_to(tower.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_tower = tower
	
	if closest_tower:
		home_tower = closest_tower
		print("Goblin assigned to tower at position: ", home_tower.global_position)


func _physics_process(delta):
	match current_state:
		AI_STATE.IDLE:
			handle_idle_state()
		AI_STATE.CHASING:
			handle_chase_state(delta)
		AI_STATE.ATTACKING:
			handle_attack_state()
		AI_STATE.RETURNING:
			handle_return_state(delta)
	
	# Check if too far from tower
	if is_instance_valid(home_tower) and current_state != AI_STATE.RETURNING:
		var distance_to_tower = global_position.distance_to(home_tower.global_position)
		if distance_to_tower > max_distance_from_tower:
			print("Too far from tower, returning!")
			change_state(AI_STATE.RETURNING)

func handle_idle_state():
	sprite.play("idle")
	
	# 30% chance to ignore nearby enemies for a short time
	if randf() > 0.7:
		return
	
	look_for_target()

func handle_chase_state(delta):
	if not is_instance_valid(target):
		change_state(AI_STATE.IDLE)
		return
	
	# Add some random deviation to movement
	if randf() > 0.8:
		random_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	navigation_agent.target_position = target.global_position + random_offset
	
	if global_position.distance_to(target.global_position) <= attack_range:
		change_state(AI_STATE.ATTACKING)
		return
		
	if not navigation_agent.is_navigation_finished():
		var next_position = navigation_agent.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		velocity = direction * speed
		
		sprite.play("run")
		sprite.flip_h = velocity.x < 0
		
		move_and_slide()

func handle_attack_state():
	if not is_instance_valid(target):
		change_state(AI_STATE.IDLE)
		return
		
	if global_position.distance_to(target.global_position) > attack_range:
		change_state(AI_STATE.CHASING)
		return
	
	sprite.play("attack")
	
	if not is_attacking:
		perform_attack()

func handle_return_state(delta):
	if not is_instance_valid(home_tower):
		change_state(AI_STATE.IDLE)
		find_home_tower()
		return
	
	navigation_agent.target_position = home_tower.global_position
	
	if global_position.distance_to(home_tower.global_position) <= max_distance_from_tower * 0.5:
		change_state(AI_STATE.IDLE)
		return
		
	if not navigation_agent.is_navigation_finished():
		var next_position = navigation_agent.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		velocity = direction * speed
		
		sprite.play("run")
		sprite.flip_h = velocity.x < 0
		
		move_and_slide()

func perform_attack():
	is_attacking = true
	
	# Randomize attack damage within a range
	var randomized_damage = randf_range(attack_damage * 0.8, attack_damage * 1.2)
	
	if target.has_method("take_damage"):
		target.take_damage(randomized_damage)
	else:
		print("Warning: Target doesn't have take_damage method")
	
	attack_timer.start()

func look_for_target():
	if !is_instance_valid(home_tower):
		find_home_tower()
		return
		
	var nearby_units = get_tree().get_nodes_in_group("pawns")
	var closest_distance = INF
	var closest_unit = null
	
	for unit in nearby_units:
		if not is_instance_valid(unit):
			continue
			
		var distance = global_position.distance_to(unit.global_position)
		
		# Only consider targets within detection radius
		var distance_from_tower = unit.global_position.distance_to(home_tower.global_position)
		if distance < detection_radius and distance < closest_distance and distance_from_tower <= max_distance_from_tower:
			closest_distance = distance
			closest_unit = unit
	
	# 20% chance to "miss" spotting a nearby enemy
	if closest_unit and randf() > 0.2:
		target = closest_unit
		change_state(AI_STATE.CHASING)

func _on_attack_cooldown_finished():
	is_attacking = false
	
	if current_state == AI_STATE.ATTACKING and is_instance_valid(target):
		if global_position.distance_to(target.global_position) <= attack_range:
			perform_attack()

func change_state(new_state: AI_STATE):
	if current_state != new_state:
		current_state = new_state
		
		if new_state != AI_STATE.ATTACKING:
			is_attacking = false

func take_damage(damage: float):
	health -= damage
	
	if health <= 0:
		die()

func die():
	print("Goblin died!")
	queue_free()

# Random wandering behavior
func _on_wander_timeout():
	if current_state == AI_STATE.IDLE:
		# 50% chance to move in a random direction
		if randf() > 0.5:
			var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			var wander_target = global_position + (random_direction * randf_range(20, 50))
			navigation_agent.target_position = wander_target
			sprite.play("run")
			move_and_slide()
	
	# Reset timer with a new random interval
	wander_timer.wait_time = randf_range(3.0, 7.0)
	wander_timer.start()
