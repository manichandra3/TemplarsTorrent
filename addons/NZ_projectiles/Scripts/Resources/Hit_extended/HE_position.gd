@icon("res://addons/NZ_projectiles/Icons/Hit_extended/Position.svg")
class_name HE_position
extends Hit_extended_projectile

@export var position_type : POSITION_TYPE = POSITION_TYPE.Global_position

enum POSITION_TYPE{Position,Global_position}

func call_hit_extended_function(atk:int,body:Node2D,projectile:Projectile) -> void:
	match position_type:
		POSITION_TYPE.Position:
			body.call(name_hit_extended,atk,projectile.position)
		POSITION_TYPE.Global_position:
			body.call(name_hit_extended,atk,projectile.global_position)
