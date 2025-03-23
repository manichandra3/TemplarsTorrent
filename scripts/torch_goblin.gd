extends CharacterBody2D

enum AI_STATE {
	IDLE,
	CHASING,
	ATTACKING
}

@export var speed: float = 100.0
@export var attack_range: float = 50.0  
@export var detection_radius: float = 200.0  

var target: Node2D = null
var current_state: AI_STATE = AI_STATE.IDLE

@onready var navigation_agent = $NavigationAgent2D
@onready var sprite = $AnimatedTorchGoblin

func _ready():
	add_to_group('goblins')
	navigation_agent.path_desired_distance = 5.0
	navigation_agent.target_desired_distance = 6.0
	navigation_agent.avoidance_enabled = true

func _process(delta):
	match current_state:
		AI_STATE.IDLE:
			look_for_target()
		AI_STATE.CHASING:
			chase_target(delta)
		AI_STATE.ATTACKING:
			attack_target()

func look_for_target():
	var nearby_units = get_tree().get_nodes_in_group("pawns")  
	for unit in nearby_units:
		if global_position.distance_to(unit.global_position) < detection_radius:
			target = unit
			change_state(AI_STATE.CHASING)
			return

func chase_target(delta):
	if not target:
		change_state(AI_STATE.IDLE)
		return

	navigation_agent.target_position = target.global_position
	
	if navigation_agent.is_navigation_finished():
		change_state(AI_STATE.ATTACKING)
		return

	var next_position = navigation_agent.get_next_path_position()
	velocity = (next_position - global_position).normalized() * speed
	move_and_slide()
	
	sprite.play("run")  
	sprite.flip_h = velocity.x < 0

func attack_target():
	if target and global_position.distance_to(target.global_position) > attack_range:
		change_state(AI_STATE.CHASING)
		return

	sprite.play("attack")  
	
func change_state(new_state: AI_STATE):
	current_state = new_state
