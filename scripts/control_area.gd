extends Area2D
@export var coin_scene: PackedScene
@export var spawn_area: Vector2 = Vector2(200, 200)
@export var spawn_interval: float = 10.0
# Reference to the mine scene with an AnimatedSprite2D node as a child
@onready var mine = $GoldMine 
@onready var animated_sprite = $GoldMine/GoldMineActive
var spawn_timer: Timer

func _ready() -> void:
	if not coin_scene:
		push_error("Coin scene not assigned!")
		return
	
	if not animated_sprite:
		push_error("AnimatedSprite2D not found in mine!")
		return
	
	# Set initial animation
	animated_sprite.play("inactive") 
	
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(spawn_coin)
	add_child(spawn_timer)

func spawn_coin() -> void:
	var spawn_position = get_valid_spawn_position()
	
	var coin = coin_scene.instantiate()
	coin.global_position = spawn_position
	get_parent().add_child(coin)
	
	# Change animation when spawning a coin
	animated_sprite.play("active")

func get_valid_spawn_position() -> Vector2:
	var mine_collision = mine.get_node("CollisionShape2D") if mine.has_node("CollisionShape2D") else null
	
	if not mine_collision:
		push_error("No CollisionShape2D found in GoldMine node!")
		return global_position + Vector2(spawn_area.x/2, spawn_area.y/2)
	
	var mine_shape = mine_collision.shape
	var mine_extents = mine_shape.extents if mine_shape is RectangleShape2D else Vector2(50, 50)
	var mine_position = mine.global_position
	
	var max_attempts = 10
	var attempts = 0
	
	while attempts < max_attempts:
		var random_offset = Vector2(
			randf_range(-spawn_area.x, spawn_area.x),
			randf_range(-spawn_area.y, spawn_area.y)
		)
		var potential_position = global_position + random_offset
		
		# Check if the position is outside the mine's area
		var dist_to_mine = (potential_position - mine_position).abs()
		
		if dist_to_mine.x > mine_extents.x or dist_to_mine.y > mine_extents.y:
			return potential_position
			
		attempts += 1
	
	# If no valid position found, return a position just outside the mine
	var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var fallback_position = mine_position + direction * (mine_extents + Vector2(20, 20))
	return fallback_position

func on_area_entered(area: Area2D) -> void:
	pass
