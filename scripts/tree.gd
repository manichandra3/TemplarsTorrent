extends CharacterBody2D

enum STATE {
	GROWN,
	CHOPPING,
	CHOPPED
}

@export var secs_to_grow: float = 50.0
@export var chopping_duration: float = 10.0

@onready var animated_sprite: AnimatedSprite2D = $tree_animated

var state = STATE.GROWN
var chopping_pawn: Node2D = null
var chopping_task: SceneTreeTimer = null
var is_regrowth_scheduled: bool = false

func _ready():
	add_to_group("trees")
	update_animation()

func chop_tree(pawn: Node2D):
	if state != STATE.GROWN or chopping_pawn:
		return
	
	print("chop_tree() is running")
	state = STATE.CHOPPING
	chopping_pawn = pawn
	update_animation()
	
	# Clear existing timer if any
	if chopping_task and chopping_task.time_left > 0:
		chopping_task.timeout.disconnect(_on_chopping_complete)
		chopping_task = null
	
	chopping_task = get_tree().create_timer(chopping_duration)
	var task = chopping_task  # Store reference to compare later
	await chopping_task.timeout
	
	# Only complete chopping if this is still the active task and the same pawn
	if task == chopping_task and chopping_pawn == pawn:
		complete_chopping()
		
func _on_chopping_complete(pawn: Node2D):
	# Only complete chopping if this pawn is still the active chopper
	if chopping_pawn == pawn:
		complete_chopping()

func complete_chopping():
	state = STATE.CHOPPED
	update_animation()
	chopping_pawn = null
	chopping_task = null
	start_regrowth()

func stop_chopping(pawn: Node2D):
	if chopping_pawn != pawn:
		return
		
	chopping_pawn = null
	state = STATE.GROWN
	update_animation()
	
	# Cancel any pending chop completion
	chopping_task = null

func start_regrowth():
	if is_regrowth_scheduled:
		return
		
	is_regrowth_scheduled = true
	await get_tree().create_timer(secs_to_grow).timeout
	is_regrowth_scheduled = false
	
	# Only regrow if we're still in chopped state
	if state == STATE.CHOPPED:
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
