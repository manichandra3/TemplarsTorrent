extends Camera2D

var PAN_SPEED: float = 50
var PAN_ACCELERATION: float = 25

func _unhandled_input(event: InputEvent) -> void:
	# Mouse Drag Panning
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_RIGHT: 
			position -= event.relative / zoom 

	# Keyboard Panning
	var move_direction = Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
		move_direction.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
		move_direction.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
		move_direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
		move_direction.y += 1
