extends Area2D

@export var SCALE_FACTOR: float = 1.1  
@export var NORMAL_SCALE: float = 1.0 

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	if owner: 
		owner.scale = Vector2(SCALE_FACTOR, SCALE_FACTOR)  

func _on_mouse_exited():
	if owner:
		owner.scale = Vector2(NORMAL_SCALE, NORMAL_SCALE) 
