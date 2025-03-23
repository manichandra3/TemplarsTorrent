extends CharacterBody2D

enum STATE {
	GROWN,
	CHOPPING,
	CHOPPED
}

@export var secs_to_grow: float = 50.0  # Time taken to regrow
@export var chopping_duration: float = 10.0  # Duration of the chopping process

@onready var animated_sprite: AnimatedSprite2D = $tree_animated

var state = STATE.GROWN  # Current state of the tree
var chopping_pawn: Node2D = null  # The pawn currently chopping this tree
var chopping_task: SceneTreeTimer = null  # Timer for the chopping action

func _ready() -> void:
	add_to_group("trees")
	update_animation()

func chop_tree(pawn: Node2D):
	if state != STATE.GROWN or chopping_pawn:
		return 

	print("chop_tree() is running")
	state = STATE.CHOPPING
	chopping_pawn = pawn
	update_animation()

	# Start chopping timer
	chopping_task = get_tree().create_timer(chopping_duration)
	await chopping_task.timeout

	# If the pawn was interrupted, stop chopping
	if chopping_pawn != pawn:
		return  

	state = STATE.CHOPPED
	update_animation()
	chopping_pawn = null
	
	# Start regrowth timer
	start_regrowth()

func stop_chopping(pawn: Node2D):
	if chopping_pawn == pawn:
		print("Chopping interrupted!")
		chopping_pawn = null
		state = STATE.GROWN  # Reset state to GROWN if interrupted
		update_animation()
		if chopping_task and chopping_task.time_left > 0:
			chopping_task = null

func start_regrowth():
	await get_tree().create_timer(secs_to_grow).timeout
	
	state = STATE.GROWN
	update_animation()

func is_grown() -> bool:
	return state == STATE.GROWN

func update_animation():
	match state:
		STATE.GROWN:
			animated_sprite.play("default")
		STATE.CHOPPING:
			animated_sprite.play("chopping")
		STATE.CHOPPED:
			animated_sprite.play("chopped")
