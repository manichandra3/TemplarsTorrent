extends CharacterBody2D

enum TREE_STATE {
	GROWN,
	CHOPPING,
	CHOPPED
}

@export var secs_to_grow: float = 50  # Time taken to regrow
@onready var animated_sprite: AnimatedSprite2D = $tree_animated

var state = TREE_STATE.GROWN # Current state of the tree

func _ready() -> void:
	add_to_group("trees")
	update_animation()

func chop_tree():
	if state == TREE_STATE.GROWN:
		state = TREE_STATE.CHOPPING
		update_animation()
		await get_tree().create_timer(10.0).timeout 
		state = TREE_STATE.CHOPPED
		update_animation()
		start_regrowth()

func start_regrowth():
	await get_tree().create_timer(secs_to_grow).timeout
	state = TREE_STATE.GROWN
	update_animation()

func update_animation():
	match state:
		TREE_STATE.GROWN:
			animated_sprite.play("default")
		TREE_STATE.CHOPPING:
			animated_sprite.play("chopping")
		TREE_STATE.CHOPPED:
			animated_sprite.play("chopped")
