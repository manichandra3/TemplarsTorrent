extends CharacterBody2D

enum STATE {
	GROWN,
	CHOPPING,
	CHOPPED
}

@export var secs_to_grow: float = 50.0  # Time taken to regrow
@onready var animated_sprite: AnimatedSprite2D = $tree_animated

var state = STATE.GROWN  # Current state of the tree

func _ready() -> void:
	add_to_group("trees")
	update_animation()

func chop_tree():
	print("chop_tree() is running")
	if state == STATE.GROWN:
		state = STATE.CHOPPING
		update_animation()
		await get_tree().create_timer(10.0).timeout 
		state = STATE.CHOPPED
		update_animation()
		start_regrowth()

func start_regrowth():
	await get_tree().create_timer(secs_to_grow).timeout
	state = STATE.GROWN
	update_animation()

func update_animation():
	match state:
		STATE.GROWN:
			animated_sprite.play("default")
		STATE.CHOPPING:
			animated_sprite.play("chopping")
		STATE.CHOPPED:
			animated_sprite.play("chopped")
