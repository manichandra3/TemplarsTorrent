@icon("res://addons/NZ_projectiles/Icons/Projectile_extended.svg")
class_name Projectile_extended
extends Projectile

@export var id : int
@export_enum("Queue_free","Free","Activate remove resource") var when_colliding_with_remove_when_collide : int = 0
@export var duplicate_resources : bool = true
@export_group("Resources","r_")
@export var r_atk_change : Atk_change_projectile
@export var r_speed_change : Speed_change_projectile
@export var r_move_extended : Move_extended_projectile
@export var r_hit_extended : Hit_extended_projectile
@export var r_remove_projectile : Remove_projectile
#@export var r_custom : Resource

enum {QUEUE_FREE,FREE,ACTIVATE_REMOVE_RESOURCE}

var can_move: bool = true

func _ready() -> void:
	super()
	check_everything()

func move(delta:float) -> void:
	if can_move:
		if r_speed_change != null:
			speed = r_speed_change.change_speed(speed)
		if r_move_extended == null:
			position += transform.x*speed * delta
		else:
			r_move_extended.move_extended(self,delta)

func check_everything() -> void:
	if duplicate_resources:
		if ProjectileChecks.check_resource_if_needed_to_duplicate(self,r_atk_change):
			r_atk_change = r_atk_change.duplicate(true)
		if ProjectileChecks.check_resource_if_needed_to_duplicate(self,r_remove_projectile):
			r_remove_projectile = r_remove_projectile.duplicate(true)
		if ProjectileChecks.check_resource_if_needed_to_duplicate(self,r_move_extended):
			r_move_extended = r_move_extended.duplicate(true)
		if ProjectileChecks.check_resource_if_needed_to_duplicate(self,r_hit_extended):
			r_hit_extended = r_hit_extended.duplicate(true)
		if ProjectileChecks.check_resource_if_needed_to_duplicate(self,r_speed_change):
			r_speed_change = r_speed_change.duplicate(true)
	chech_if_resource_has_ready_method(r_speed_change)
	chech_if_resource_has_ready_method(r_atk_change)
	if r_speed_change != null:
		r_speed_change.activate()

func chech_if_resource_has_ready_method(resource:Resource) -> void:
	if resource != null:
		if resource.has_method("_ready"):
			resource.call("_ready",self)

func hit_body(body:Node2D) -> void:
	if r_hit_extended == null:
		body.call(name_hit,atk)
	else:
		if !r_hit_extended.hit_extended(atk,body,self):
			super(body)
			return
	remove_projectile()

func remove_projectile(colliding_with_remove_when_collide:bool=false) -> void:
	if colliding_with_remove_when_collide and when_colliding_with_remove_when_collide != ACTIVATE_REMOVE_RESOURCE:
		if when_colliding_with_remove_when_collide == QUEUE_FREE:
			queue_free()
		else:
			free()
		return
	if r_remove_projectile != null:
		r_remove_projectile.remove_projectile(self)
	else:
		super.remove_projectile()
