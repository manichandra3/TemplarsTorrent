extends Camera2D

var TARGET_ZOOM: float = 1.0
var MIN_ZOOM: float = 0.1
var MAX_ZOOM: float = 1.5
var ZOOM_INCREMENT: float = 0.1
var ZOOM_RATE: float = 8
var PAN_SPEED: float = 50
var PAN_ACCELERATION: float = 25

func _unhandled_input(event: InputEvent) -> void:
	# Mouse Drag Panning
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_RIGHT: 
			position -= event.relative / zoom 

	# Mouse Wheel Zooming
	if Input.is_action_just_pressed("mouse_up"):
		zoom_in()
	elif Input.is_action_just_pressed("mouse_down"):
		zoom_out()

	# Keyboard Zooming
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_PLUS:
			zoom_in()
		elif event.keycode == KEY_MINUS or event.keycode == KEY_UNDERSCORE:
			zoom_out()

func zoom_in() -> void:
	TARGET_ZOOM = min(MAX_ZOOM, TARGET_ZOOM + ZOOM_INCREMENT)

func zoom_out() -> void:
	TARGET_ZOOM = max(MIN_ZOOM, TARGET_ZOOM - ZOOM_INCREMENT)

func _process(delta: float) -> void:
	# Improved Smooth Zoom Transition
	zoom = lerp(zoom, Vector2(TARGET_ZOOM, TARGET_ZOOM), 1 - exp(-ZOOM_RATE * delta))

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

	if move_direction != Vector2.ZERO:
		# Panning speed now scales with zoom
		var speed = (PAN_SPEED + PAN_ACCELERATION * delta) * zoom.length()
		position += move_direction.normalized() * speed
