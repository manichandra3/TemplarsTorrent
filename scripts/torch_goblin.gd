extends CharacterBody2D

enum AI_STATE {
	IDLE,
	CHASING,
	ATTACKING
}

@export var speed: float = 100.0
@export var attack_range: float = 50.0  
@export var detection_radius: float = 200.0  
@export var health: float = 15.0  
@export var attack_damage: float = 10.0  
@export var attack_cooldown: float = 1.0  

var target: Node2D = null
var current_state: AI_STATE = AI_STATE.IDLE
var is_attacking: bool = false
var attack_timer: Timer = null

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

func _physics_process(delta):
	match current_state:
		AI_STATE.IDLE:
			handle_idle_state()
		AI_STATE.CHASING:
			handle_chase_state(delta)
		AI_STATE.ATTACKING:
			handle_attack_state()

func handle_idle_state():
	sprite.play("idle")
	look_for_target()

func handle_chase_state(delta):
	if not is_instance_valid(target):
		change_state(AI_STATE.IDLE)
		return
		
	navigation_agent.target_position = target.global_position
	
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

func perform_attack():
	is_attacking = true
	
	# Check if target has take_damage function
	if target.has_method("take_damage"):
		attack_damage = randf_range(2,5)
		target.take_damage(attack_damage)
	else:
		print("Warning: Target doesn't have take_damage method")
	
	attack_timer.start()

func look_for_target():
	var nearby_units = get_tree().get_nodes_in_group("pawns")
	var closest_distance = INF
	var closest_unit = null
	
	for unit in nearby_units:
		if not is_instance_valid(unit):
			continue
			
		var distance = global_position.distance_to(unit.global_position)
		if distance < detection_radius and distance < closest_distance:
			closest_distance = distance
			closest_unit = unit
	
	if closest_unit:
		target = closest_unit
		change_state(AI_STATE.CHASING)

func _on_attack_cooldown_finished():
	is_attacking = false
	
	# If still in attack state and target is valid, continue attacking
	if current_state == AI_STATE.ATTACKING and is_instance_valid(target):
		if global_position.distance_to(target.global_position) <= attack_range:
			perform_attack()

func change_state(new_state: AI_STATE):
	if current_state != new_state:
		current_state = new_state
		
		# Reset attack state when changing states
		if new_state != AI_STATE.ATTACKING:
			is_attacking = false

func take_damage(damage: float):
	health -= damage
	
	# Flash animation or other visual feedback could be added here
	
	if health <= 0:
		die()

func die():
	print("Goblin died!")
	queue_free()
