extends Node2D

# Signals
signal entity_move_requested(entity_id, target_position)
signal selection_changed(new_selected)

# Existing variables
@onready var ui_layer = preload("res://scenes/ui.tscn").instantiate()
#@export var pawn_scene: PackedScene = load("res://scenes/pawn.tscn")
#@export var knight_scene: PackedScene = load("res://scenes/knight.tscn")
@export var player1_scene: PackedScene = load("res://scenes/player_1/player_1.tscn")
@export var player2_scene: PackedScene = load("res://scenes/player_2/player_2.tscn")

var NUM = 3
var selected_unit: CharacterBody2D = null
var castle: StaticBody2D
@export var totalGoblins = 0

var linked_goblins = []
var goblin_tower1_capacity = []
var goblin_tower2_capacity = []
var goblin_towers : Array[Node]

var node_goblin_tower: Array[Node]
var counter = 0
var first_player: Node
var second_player: Node

func _ready():
	add_child(ui_layer) 
	var index = 1
	for i in GameManager.Players:
		var currentPlayer
		if index == 1:
			currentPlayer = player1_scene.instantiate()
		else:
			currentPlayer = player2_scene.instantiate()
		# set the custom field, not the node’s name:
		currentPlayer.player_id = GameManager.Players[i].id
		add_child(currentPlayer)
		index += 1
		#castle = get_tree().get_first_node_in_group("castle")
		#if not castle:
			#push_error("Castle not found! Make sure it's in the 'castle' group")
	if multiplayer.is_server():
		spawn_trees.rpc()
		spawn_goblin_towers.rpc()
		print(goblin_towers)
		goblin_towers = get_tree().get_nodes_in_group("goblin_towers")
		spawn_goblin_in_towers()
		spawn_control_point.rpc()
		
		var spawn_timer = Timer.new()
		spawn_timer.wait_time = 10.0  # Spawn a goblin every 20 seconds
		spawn_timer.autostart = true
		spawn_timer.timeout.connect(spawn_goblin_in_towers)
		add_child(spawn_timer)
		
	# Register any existing goblins that should be linked to this tower
	call_deferred("_register_existing_goblins")
	
func _process(float) -> void:
	if counter == 0:
		if get_tree().get_first_node_in_group("player1") and get_tree().get_first_node_in_group("player2"):
			var match_timer = Timer.new()
			match_timer.wait_time = 5.0  # 5 seconds for the match duration
			match_timer.one_shot = true  # run only once
			match_timer.timeout.connect(_handle_win_player)
			add_child(match_timer)  # <<== Important!
			match_timer.start()
			print("Match timer started!")
			counter = 1
			first_player =  get_tree().get_first_node_in_group("player1")
			second_player =  get_tree().get_first_node_in_group("player2")

func _handle_win_player():
	print("handle")
	if get_gold_count() > get_gold_count_2():
		print("handle1")
		var won_player = first_player
		var loose_player = second_player
		display_results(won_player, loose_player)
	elif get_gold_count() < get_gold_count_2():
		print("handle")
		var loose_player = first_player
		var won_player = second_player
		display_results(won_player,loose_player)
	else:
		print("handle")
		var loose_player = first_player
		var won_player = second_player
		print(str(loose_player) + " loose player")
		print(str(won_player) + " right player")
		var loose_display = won_player.get_node("Camera2D/UI/result_display")
		var win_display = loose_player.get_node("Camera2D/UI/result_display")
		win_display.show()		
		loose_display.show()
		win_display.text = "Draw..."
		loose_display.text = "Draw..."
		#get_tree().quit()
		Engine.time_scale = 0
			
func display_results(won_player, loose_player):
	var win_display = won_player.get_node("Camera2D/UI/result_display")
	var loose_display = loose_player.get_node("Camera2D/UI/result_display")
	win_display.show()
	loose_display.show()
	win_display.text = "You Won!"
	loose_display.text = "You loose :/)"
	#get_tree().quit()
	Engine.time_scale = 0

func link_goblin(goblin) -> void:
	if goblin not in linked_goblins:
		linked_goblins.append(goblin)
		
		# Assign this tower as the goblin's home tower if it doesn't have one
		if goblin.has_method("find_home_tower") and not is_instance_valid(goblin.home_tower):
			goblin.home_tower = self

			
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var target_position = get_global_mouse_position()

		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = target_position
		query.collide_with_areas = true  

		var result = space_state.intersect_point(query)

		for hit in result:
			var collider = hit.get("collider", null)
			if collider and collider is CharacterBody2D and not collider.is_in_group('trees'):
				change_selected_unit(collider)
				return 

		if selected_unit:
			request_entity_movement(selected_unit.get_instance_id(), target_position)

func request_entity_movement(entity_id, target_position):
	emit_signal("entity_move_requested", entity_id, target_position)

func change_selected_unit(new_unit):
	if selected_unit and selected_unit.has_method("deselect") and selected_unit != new_unit and not selected_unit.is_in_group('goblins'):
		selected_unit.deselect()
	selected_unit = new_unit
	emit_signal("selection_changed", new_unit)

func deselect_current_unit():
	if selected_unit:
		selected_unit.deselect()
		selected_unit = null
	emit_signal("selection_changed", null)

# Resource Management
# Replace these functions in your original script

func add_wood(amount: int):
	ResourceManager.add_wood(amount)

func get_wood_count() -> int:
	return ResourceManager.get_wood_count()

func spend_wood(amount: int) -> bool:
	return ResourceManager.spend_wood(amount)

func add_gold(amount: int):
	ResourceManager.add_gold(amount)

func get_gold_count() -> int:
	return ResourceManager.get_gold_count()

func spend_gold(amount: int) -> bool:
	return ResourceManager.spend_gold(amount)
	
	
func add_wood_2(amount: int):
	ResourceManager2.add_wood(amount)

func get_wood_count_2() -> int:
	return ResourceManager2.get_wood_count()

func spend_wood_2(amount: int) -> bool:
	return ResourceManager2.spend_wood(amount)

func add_gold_2(amount: int):
	ResourceManager2.add_gold(amount)

func get_gold_count_2() -> int:
	return ResourceManager2.get_gold_count()

func spend_gold_2(amount: int) -> bool:
	return ResourceManager2.spend_gold(amount)
# Spawning Functions
#func _on_spawn_pawn_pressed() -> void:
	#if not pawn_scene or not is_instance_valid(castle):
		#return
	#if spend_wood(20):
		#spawn_unit(pawn_scene)
	#else:
		#display_insufficient_resources("Wood")

#func _on_spawn_knight_pressed() -> void:
	#if not knight_scene or not is_instance_valid(castle):
		#return
	#
	#if spend_wood(20):
		#spawn_unit(knight_scene)
	#else:
		#display_insufficient_resources("Wood")

func spawn_unit(unit_scene: PackedScene):
	var spawn_position = get_valid_spawn_position()
	var new_unit = unit_scene.instantiate()
	new_unit.global_position = spawn_position
	get_parent().add_child(new_unit)
	print(new_unit.name, " spawned!")

func get_valid_spawn_position() -> Vector2:
	var attempts = 10
	while attempts > 0:
		var random_offset = Vector2(randf_range(-30, 30), randf_range(60, 100))
		var test_position = castle.global_position + random_offset

		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = test_position
		query.collide_with_bodies = true

		if space_state.intersect_point(query).size() == 0:
			return test_position

		attempts -= 1
	return castle.global_position + Vector2(0, 90)

func display_insufficient_resources(resource_name: String):
	print("Not enough ", resource_name, " to spawn a unit!")

func _on_cancel_selection_pressed() -> void:
	deselect_current_unit()

@rpc("any_peer", "call_local")
func spawn_trees():
	# Example: spawn 3 trees at different locations
	for i in range(1):
		var tree = preload("res://scenes/tree.tscn").instantiate()
		tree.position = Vector2(-1159, -286)
		add_child(tree)
		
		# Assign a unique name for network syncing
		tree.name = "tree_%s" % str(i)

		# Set ownership to the server (so it can sync)
		if multiplayer.is_server():
			tree.set_multiplayer_authority(multiplayer.get_unique_id())
		

#func spawn_goblins():
	#for i in range(3):
		#var torch_goblin = preload("res://scenes/torch_goblin.tscn").instantiate()
		#torch_goblin.position = Vector2(-951 +i*10, -719+i*10)
		#
		## Assign a unique name for network syncing
		#torch_goblin.name = "TorchGoblin_%s" % str(i)
		#add_child(torch_goblin)
		#
		## Set ownership to the server (so it can sync)
		#torch_goblin.set_multiplayer_authority(multiplayer.get_unique_id())
		
func _handle_spawn_globin(num, goblin_tower, sno):
	if multiplayer.is_server():
		spawn_goblins.rpc(num, goblin_tower, sno)

@rpc("any_peer", "call_local")
func spawn_goblins(num, goblin_tower, sno):

	for i in range(NUM, NUM+num):
		var g = preload("res://scenes/torch_goblin.tscn").instantiate()
		g.name = "Goblin_%d" % i
		
		g.position = node_goblin_tower[sno].position + Vector2(randi_range(25,50), randi_range(25,50))
		get_parent().add_child(g)
		link_goblin(g)
		if sno == 0:
			goblin_tower1_capacity.append(g)
		elif sno == 1:
			goblin_tower2_capacity.append(g)
		if multiplayer.is_server():
			g.set_multiplayer_authority(multiplayer.get_unique_id())
		NUM = NUM + num
		
func _spawn_goblin(goblin_tower, sno) -> void:
	# Check if we should spawn more goblins
	var active_goblins = 0
	print(linked_goblins)
	var buffer 
	if sno == 0:
		buffer = goblin_tower1_capacity
	elif sno == 1:
		buffer = goblin_tower2_capacity
	for goblin in buffer:
		if is_instance_valid(goblin):
			active_goblins += 1
		else:
			# Remove invalid references
			linked_goblins.erase(goblin)
			buffer.erase(goblin)
	
	# Limit the number of goblins per tower
	print(str(active_goblins) + " active_goblins ")
	if active_goblins >= 5:
		return
	if multiplayer.is_server():
		_handle_spawn_globin(1, goblin_tower,sno)
	
func spawn_goblin_in_towers():
	var goblin_tower_position: Vector2
	print(goblin_towers)
	for goblin_tower in goblin_towers:
		print(str(goblin_towers.find(goblin_tower)) +" index" )
		_spawn_goblin(goblin_tower,goblin_towers.find(goblin_tower))

@rpc("any_peer", "call_local")
func spawn_goblin_towers():
	for i in range(2):
		var goblin_tower = preload("res://scenes/goblin_tower.tscn").instantiate()
		goblin_tower.position = Vector2(-987 +i*600, -923+i*20)
		node_goblin_tower.append(goblin_tower)
		get_parent().add_child(goblin_tower)
		
		# Assign a unique name for network syncing
		goblin_tower.name = "GoblinTower_%s" % str(i)

		# Set ownership to the server (so it can sync)
		if multiplayer.is_server():
			goblin_tower.set_multiplayer_authority(multiplayer.get_unique_id())
			
@rpc("any_peer", "call_local")
func spawn_control_point():
	for i in range(1):
		var control_point = preload("res://scenes/control_point.tscn").instantiate()
		control_point.position = Vector2(0,0)
		get_parent().add_child(control_point)
		
		# Assign a unique name for network syncing
		control_point.name = "ControlPoint_%s" % str(i)

		# Set ownership to the server (so it can sync)
		if multiplayer.is_server():
			control_point.set_multiplayer_authority(multiplayer.get_unique_id())
			

	
