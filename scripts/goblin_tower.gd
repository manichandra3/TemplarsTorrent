extends StaticBody2D

signal enemy_detected(enemy)

@export var detection_radius: float = 300.0
@export var goblin_patrol_radius: float = 350.0  # Radius within which goblins should stay


var linked_goblins = Game.linked_goblins

func _ready() -> void:
	add_to_group("goblin_towers")
	
	# Create a timer to periodically check for enemies
	var detection_timer = Timer.new()
	detection_timer.wait_time = 0.5  # Check every half second
	detection_timer.autostart = true
	detection_timer.timeout.connect(_check_for_enemies)
	add_child(detection_timer)
	
	# Create a timer to spawn goblins
	#var spawn_timer = Timer.new()
	#spawn_timer.wait_time = 60.0  # Spawn a goblin every 20 seconds
	#spawn_timer.autostart = true
	#spawn_timer.timeout.connect(_spawn_goblin)
	#add_child(spawn_timer)
	#
	## Register any existing goblins that should be linked to this tower
	#call_deferred("_register_existing_goblins")
#
func _register_existing_goblins() -> void:
	var goblins = get_tree().get_nodes_in_group("goblins")
	
	for goblin in goblins:
		if not is_instance_valid(goblin):
			continue
			
		var distance = global_position.distance_to(goblin.global_position)
		if distance <= goblin_patrol_radius:
			link_goblin(goblin)

func link_goblin(goblin) -> void:
	if goblin not in linked_goblins:
		linked_goblins.append(goblin)
		
		# Assign this tower as the goblin's home tower if it doesn't have one
		if goblin.has_method("find_home_tower") and not is_instance_valid(goblin.home_tower):
			goblin.home_tower = self

func _check_for_enemies() -> void:
	var pawns = get_tree().get_nodes_in_group("pawns")
	
	for pawn in pawns:
		if not is_instance_valid(pawn):
			continue
			
		var distance = global_position.distance_to(pawn.global_position)
		if distance <= detection_radius:
			# Enemy detected within range
			emit_signal("enemy_detected", pawn)
			
			# Alert all linked goblins about this enemy
			for goblin in linked_goblins:
				if is_instance_valid(goblin) and goblin.has_method("look_for_target"):
					goblin.target = pawn
					goblin.change_state(goblin.AI_STATE.CHASING)
			
			break  # Only alert about the first enemy detected

#func _spawn_goblin() -> void:
	## Check if we should spawn more goblins
	#var active_goblins = 0
	#for goblin in linked_goblins:
		#if is_instance_valid(goblin):
			#active_goblins += 1
		#else:
			## Remove invalid references
			#linked_goblins.erase(goblin)
	#
	## Limit the number of goblins per tower
	#if active_goblins >= 5:
		#return
	#if multiplayer.is_server():
		#Game._handle_spawn_globin(1)
	#var goblin_scene = preload("res://scenes/torch_goblin.tscn")
	#var new_goblin = goblin_scene.instantiate()
	#new_goblin.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	#get_parent().add_child(new_goblin)
	#link_goblin(new_goblin)

# Optional: Draw the patrol radius in the editor for visualization
func _draw():
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, goblin_patrol_radius, Color(1, 0, 0, 0.1))
		draw_circle(Vector2.ZERO, detection_radius, Color(0, 1, 0, 0.1))
