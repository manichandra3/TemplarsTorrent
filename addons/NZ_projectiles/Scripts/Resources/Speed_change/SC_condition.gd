@tool
@icon("res://addons/NZ_projectiles/Icons/Speed_change/SC_condition.svg")
class_name SC_condition
extends Speed_change_projectile

@export var speed_change : Speed_change_projectile
@export var after_condition_speed_change : Speed_change_projectile

var condition_is_true : bool = false

const CREATE_DUPLICATE : bool = true

func _ready(parent_node:Projectile) -> void:
	if speed_change != null:
		if speed_change.has_method("_ready"):
			speed_change = speed_change.duplicate(true)
			speed_change._ready(parent_node)
	#else:
		#push_error("No speed_change")
	if after_condition_speed_change != null:
		if after_condition_speed_change.has_method("_ready"):
			after_condition_speed_change = after_condition_speed_change.duplicate(true)
			after_condition_speed_change._ready(parent_node)
	else:
		push_error("No after_condition_speed_change")

func reset() -> void:
	if speed_change.has_method("reset"):
		speed_change.reset()
	if after_condition_speed_change.has_method("reset"):
		after_condition_speed_change.reset()
	condition_is_true = false

func change_speed(projectile_speed:int) -> int:
	if !condition_is_true:
		if speed_change == null:
			return projectile_speed
		speed_change.activate()
		if speed_change is SC_increase:
			if speed_change.type_of_increase == speed_change.EVERY_CALL_OF_MOVE_FUNCTION:
				return speed_change.change_speed(projectile_speed)
		return speed_change.change_speed(projectile_speed)
	if after_condition_speed_change is SC_increase:
		if after_condition_speed_change.type_of_increase == after_condition_speed_change.EVERY_CALL_OF_MOVE_FUNCTION:
			return after_condition_speed_change.change_speed(projectile_speed)
	after_condition_speed_change.activate()
	return after_condition_speed_change.change_speed(projectile_speed)
