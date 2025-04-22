extends TileMap
#
#@export var navigation_region: NavigationRegion2D  # Reference to the navigation region
#@export var navigation_layer: int = 0  # Navigation layer index
#@export var obstacle_layer: int = 1  # Obstacle layer index
#
#func _ready():
	#update_navigation()
#
#func update_navigation():
	#if not navigation_region:
		#print("Error: NavigationRegion2D not assigned!")
		#return
#
	#var polygon = NavigationPolygon.new()
	#var used_cells = get_used_cells(navigation_layer)
#
	#var outline = []
	#for cell in used_cells:
		#var world_position = map_to_local(cell)
		#if not is_tile_occupied(world_position):
			#var tile_data = get_cell_tile_data(navigation_layer, cell)
			#if tile_data:
				#var cell_polygon = tile_data.get_navigation_polygon(0)
				#if cell_polygon:
					#outline.append_array(cell_polygon.get_outline(0))  # Add tile polygon to navigation
#
	#if outline:
		#polygon.add_outline(outline)
		#polygon.make_polygons_from_outlines()
#
	#navigation_region.navigation_polygon = polygon
#
#func has_obstacle_at(cell: Vector2i) -> bool:
	#return get_cell_source_id(obstacle_layer, cell) != -1
#
#func is_tile_occupied(world_position: Vector2) -> bool:
	#var space_state = get_world_2d().direct_space_state
	#var query = PhysicsShapeQueryParameters2D.new()
	#var shape = RectangleShape2D.new()
	#shape.size = Vector2(16, 16)  # Adjust to match your tile size
	#query.shape = shape
	#query.transform = Transform2D(0, world_position)
	#query.collide_with_bodies = true
	#query.collide_with_areas = true
	#var result = space_state.intersect_shape(query)
#
	#for hit in result:
		#var collider = hit.get("collider")
		#if collider and (collider is CharacterBody2D or collider.is_in_group("obstacles")):
			#return true
#
	#var cell = local_to_map(world_position)
	#return has_obstacle_at(cell)
