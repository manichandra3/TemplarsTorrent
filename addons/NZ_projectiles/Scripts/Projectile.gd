@icon("res://addons/NZ_projectiles/Icons/Projectile.svg")
class_name Projectile
extends Area2D

## Base class for every projectile
@export var velocity: Vector2
@export var atk : int
@export var speed : int
@export var direction : Vector2
@export var life_time : float:
	set(value):
		life_time = abs(value)
@export var activated : bool = true:
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
@export_group("Remove when colliding with","remove_when_")
@export var remove_when_tilemap_layer : bool = true
@export var remove_when_static_body : bool = true
@export_group("Variables and functions names","name_")
@export var name_type : StringName = "type" ## Only hit if projectile type and body type isn't the same
@export var name_hit : StringName = "take_damage" ## Name of the function that deals damage in body

var life_timer : Timer
var type : int

func _ready() -> void:
	set_everything()

func _physics_process(delta:float):
	if activated:
		move(delta)

func move(delta: float) -> void:
	velocity = transform.x * speed * direction;
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
	# Area2D
	body_entered.connect(_on_area_2d_body_entered)

func remove_projectile(_colliding_with_remove_when_collide:bool=false) -> void:
	queue_free()

func _on_life_timer_timeout() -> void:
	queue_free()

func hit_body(body:Node2D) -> void:
	if ProjectileChecks.check_if_body_has_this_and_its_type(body,name_hit,TYPE_CALLABLE,true):
		body.call(name_hit,atk)
		remove_projectile()

func _check_if_is_it_a_tilemap_layer(remove_if_it_is:bool,body:Node2D) -> bool:
	if remove_if_it_is and body is TileMapLayer:
		return true
	return false

func _check_if_is_it_a_static_body(remove_if_it_is:bool,body:Node2D) -> bool:
	if remove_if_it_is and body is StaticBody2D:
		return true
	return false

func _on_area_2d_body_entered(body:Node2D):
	if !_check_if_is_it_a_tilemap_layer(remove_when_tilemap_layer,body) and !_check_if_is_it_a_static_body(remove_when_static_body,body):
		if ProjectileChecks.check_if_body_has_this_and_its_type(body,name_type,TYPE_INT):
			if body.get(name_type) != type:
				hit_body(body)
	else:
		remove_projectile(true)
