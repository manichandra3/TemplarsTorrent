extends CharacterBody2D

@export var health: float = 20.0
@export var movement_speed: float = 200.0 
@export var acceleration: float = 500.0

var is_selected: bool = false

# These should be assigned in _ready() of child scripts
var animated_sprite: AnimatedSprite2D = null
var health_bar = null

func select():
	is_selected = true
	if animated_sprite:
		animated_sprite.self_modulate = Color(1, 1, 0, 1)  # Yellow

func deselect():
	is_selected = false
	if animated_sprite:
		animated_sprite.self_modulate = Color(1, 1, 1, 1)  # Normal white

func take_damage(damage: float):
	health -= damage
	if health_bar:
		health_bar.update_bar(health)
	print(name, " took ", damage, " damage! Health left: ", health)

	if health <= 0:
		deselect()
		die()

func die():
	print(name, " has died!")
	queue_free()  # Remove the unit from the game
