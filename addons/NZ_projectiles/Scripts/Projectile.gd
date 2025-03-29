@icon("res://addons/NZ_projectiles/Icons/Projectile.svg")
class_name Projectile
extends Area2D

## Base class for every projectile
@export var velocity: Vector2
@export var atk: int
@export var speed: int
@export var direction: Vector2
@export var life_time: float:
	set(value):
		life_time = abs(value)
@export var activated: bool = true:
	set(value):
		activated = value
		if life_time > 0 and is_instance_valid(life_timer):
			if activated:
				if life_timer.paused:
					life_timer.paused = false
				else:
					life_timer.start(life_time)
			else:
				life_timer.paused = true
@export var remove_when_tilemap_layer: bool = true
@export var remove_when_static_body: bool = true
@export var name_hit: StringName = "take_damage" ## Function name for applying damage
@export var can_pierce: bool = false ## If true, the projectile can pass through enemies

var life_timer: Timer
var type: int = 1

func _ready() -> void:
	set_everything()

func _physics_process(delta: float):
	if activated:
		move(delta)

func move(delta: float) -> void:
	velocity = direction.normalized() * speed
	var angle = -get_angle_to(direction)
	rotate(angle)
	position += velocity * delta  

func set_everything() -> void:
	# Life timer
	if life_time > 0:
		life_timer = Timer.new()
		life_timer.timeout.connect(_on_life_timer_timeout)
		life_timer.one_shot = true
		add_child(life_timer)
		if activated:
			life_timer.start(life_time)
	# Area2D collision detection
	body_entered.connect(_on_area_2d_body_entered)

func _on_life_timer_timeout() -> void:
	queue_free()

func _on_area_2d_body_entered(body: Node2D):
	# Check if the body belongs to the "goblins" group
	if body.is_in_group("goblins"):
		hit_body(body)
	elif _check_if_is_it_a_tilemap_layer(remove_when_tilemap_layer, body) or _check_if_is_it_a_static_body(remove_when_static_body, body):
		remove_projectile()

func hit_body(body: Node2D) -> void:
	if body.has_method(name_hit):
		body.call(name_hit, atk)
		if not can_pierce:
			remove_projectile()

func _check_if_is_it_a_tilemap_layer(remove_if_it_is: bool, body: Node2D) -> bool:
	return remove_if_it_is and body is TileMapLayer

func _check_if_is_it_a_static_body(remove_if_it_is: bool, body: Node2D) -> bool:
	return remove_if_it_is and body is StaticBody2D

func remove_projectile() -> void:
	queue_free()
