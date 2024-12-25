extends Node2D

@onready var indicaters = $INDICATER
@onready var tile_map = $Enviorment/TileMap
@onready var npcgroup = $NPCGROUP
@onready var zombiegroup = $ZOMBIEGROUP
@onready var player = $player
@onready var ui = $UI
@onready var camera_2d = $Camera2D

var musketman: PackedScene = preload("res://scenes/npc.tscn")
var musketgun: PackedScene = preload("res://scenes/items.tscn")
var IndicatorScene: PackedScene = preload("res://scenes/unitindicator.tscn")
var BULLET: PackedScene = preload("res://scenes/bullet.tscn")
var ZOMBIE: PackedScene = preload("res://scenes/zombie.tscn")

#var circleselected = false
var is_ui_interacting = false  # To track if the mouse button is being held
var is_rotating = false  # To track if the mouse button is being held
var initial_click_position = Vector2()  # Position where the click started
var rotation_angle: float

func _ready():
	var starting_position = Vector2(-200, 100)  # Initial position of npcs
	var offset = Vector2(0, -50)  # Offset to subtract each iteration npcs

	for i in range(Globals.soldier_count):
		var musketman_instance = musketman.instantiate()  # Assuming musketman is a scene or preloaded resource
		musketman_instance.global_position = starting_position  # Set position
		npcgroup.add_child(musketman_instance)
		starting_position += offset  

	ui.hide_map_ui(false)
	ui.set_UI_resources()
	var player_tile = tile_map.local_to_map(player.global_position)

func _process(delta: float) -> void:
	update_speed_based_on_tile()
	update_npc_speeds_based_on_tile()  # For NPCs
	
func update_npc_speeds_based_on_tile():
	for npc in npcgroup.get_children():
		if not is_instance_valid(npc):  # Use the global function
			continue
		var npc_tile = tile_map.local_to_map(npc.global_position)
		var tile_data = tile_map.get_cell_tile_data(0, npc_tile)
		
		if tile_data and tile_data.get_custom_data_by_layer_id(1):
			npc.slow_affect(true)
		else:
			npc.slow_affect(false)


func update_speed_based_on_tile():
	var player_tile = tile_map.local_to_map(player.global_position)
	var tile_data = tile_map.get_cell_tile_data(0, player_tile)
	#print(tile_data)
	if tile_data and tile_data.get_custom_data_by_layer_id(1):
		##current_speed = slow_speed
		player.slow_affect(true)
	else:
		player.slow_affect(false)
		#pass

func _input(event):
	if is_ui_interacting:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_2d.zoom = Vector2(1,1)
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_2d.zoom = Vector2(2,2)
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_rotating = true  # Start tracking rotation
			initial_click_position = get_local_mouse_position()  # Store the position where the click started
		else:
			is_rotating = false
	if is_rotating:
		# If the mouse button is held down, calculate the rotation angle
		var current_mouse_position = get_local_mouse_position()
		
		# Get the angle between the initial click position and the current mouse position
		rotation_angle = (current_mouse_position - initial_click_position).angle()
		# Now spawn the double line at the nearest tile and apply the calculated rotation
		var nearest_tile_position = get_nearest_tile(current_mouse_position)
		spawn_double_line_at_position(nearest_tile_position, rotation_angle)
	assign_npcs_to_indicators(rotation_angle)
	if Input.is_action_just_pressed("ui_accept"):
		player.swing_sword()
		if player.targetResource != null:
			player.targetResource.queue_free()

func get_nearest_tile(selected_position: Vector2, exclude_positions := []) -> Vector2:
	var tile_coords = tile_map.local_to_map(tile_map.to_local(selected_position))
	var search_radius = 1

	while search_radius < 15:
		for x_offset in range(-search_radius, search_radius + 1):
			for y_offset in range(-search_radius, search_radius + 1):
				var check_coords = tile_coords + Vector2i(x_offset, y_offset)
				if exclude_positions.has(check_coords):
					continue
				var tile_data = tile_map.get_cell_tile_data(0, check_coords)
				
				if tile_data and bool(tile_data.get_custom_data_by_layer_id(0)): 
					return tile_map.map_to_local(check_coords)
		search_radius += 1
	return tile_map.map_to_local(tile_coords)

# Function to rotate a position around a point by a given angle
func rotate_position_around_center(unitposition: Vector2, center: Vector2, angle: float) -> Vector2:
	var direction = unitposition - center  # Vector from center to the position
	var rotated_direction = direction.rotated(angle)  # Rotate the vector by the angle
	#print(rotated_direction)
	return center + rotated_direction  # Return the new position

func spawn_double_line_at_position(start_position: Vector2, unit_rotation_angle: float = 0.0):
	# Clear previous indicators
	for child in indicaters.get_children():
		child.queue_free()

	var row_spacing = 25  # Distance between the two lines
	var indicator_spacing = 50  # Distance between indicators in each line
	var line_offset = -((npcgroup.get_child_count() / 2) - 1) * indicator_spacing / 2  # Center both lines around start_position
	var placed_positions = []

	# Spawn NPCs in the formation
	for i in range(npcgroup.get_child_count()):
		var indicator_instance = IndicatorScene.instantiate()

		# Determine row (top or bottom) and position along the line
		var row = i % 2
		var position_in_line = i / 2

		# Calculate position relative to the start position
		var indicator_position = start_position
		indicator_position.x += (row * 2 - 1) * row_spacing  # Offset for top or bottom row
		indicator_position.y += line_offset + position_in_line * indicator_spacing

		# Rotate the indicator position around the start position
		indicator_position = rotate_position_around_center(indicator_position, start_position, unit_rotation_angle)
		#print(indicator_position)
		# Set position and add to the scene
		indicator_instance.position = get_nearest_tile(indicator_position, placed_positions)
		indicaters.add_child(indicator_instance)
		placed_positions.append(tile_map.local_to_map(indicator_instance.position))

func spawn_square_formation_at_position(start_position: Vector2, unit_rotation_angle: float = 0.0):
	# Clear previous indicators
	for child in indicaters.get_children():
		child.queue_free()

	var spacing = 50  # Distance between indicators in the square
	var npc_count = npcgroup.get_child_count()
	var grid_size = int(ceil(sqrt(npc_count)))  # Ensure grid_size is an integer
	var placed_positions = []

	# Spawn NPCs in a square formation
	for i in range(npc_count):
		var indicator_instance = IndicatorScene.instantiate()

		# Determine row and column in the grid
		var row = i % grid_size
		var col = i / grid_size

		# Calculate position relative to the start position
		var indicator_position = start_position
		indicator_position.x += (col - (grid_size - 1) / 2) * spacing  # Center the square horizontally
		indicator_position.y += (row - (grid_size - 1) / 2) * spacing  # Center the square vertically

		# Rotate the indicator position around the start position
		indicator_position = rotate_position_around_center(indicator_position, start_position, unit_rotation_angle)
		
		# Set position and add to the scene
		indicator_instance.position = get_nearest_tile(indicator_position, placed_positions)
		indicaters.add_child(indicator_instance)
		placed_positions.append(tile_map.local_to_map(indicator_instance.position))

func assign_npcs_to_indicators(forward_angle: float):
	var indicators = indicaters.get_children()
	for i in range(min(npcgroup.get_child_count(), indicators.size())):
		var npc = npcgroup.get_child(i)
		var indicator = indicators[i]
		#print(npc.is_aiming)
		npc.forward_angle = forward_angle
		npc.move_to_position(indicator.position)

func fire_gun(firing_entity: Node2D):
	if not is_instance_valid(firing_entity) or not firing_entity.has_node("Musket/Marker2D"):
		print("Error: Invalid firing entity or missing Musket/Marker2D node.")
		return
	
	var musketBall = BULLET.instantiate()
	var gun_marker = firing_entity.get_node("Musket/Marker2D")
	musketBall.position = gun_marker.global_position
	
	var gun_angle = gun_marker.global_rotation
	# Shoot with inaccuracy
	var adjusted_angle = gun_angle + deg_to_rad(randf_range(-15, 15))
	var direction = Vector2(cos(adjusted_angle), sin(adjusted_angle)).normalized()
	
	musketBall.direction = direction
	musketBall.rotation = adjusted_angle
	add_child(musketBall)

func _on_timer_timeout():
	if zombiegroup.get_child_count() < 1:
		for row in range(1):  # 5 rows
			for col in range(1):  # 5 columns
				var zombie = ZOMBIE.instantiate()
				zombie.position = Vector2(50 * col, 50 * row)  # Adjust spacing for a grid
				zombie.name = "zombie_%d_%d" % [row, col]  # Unique name for debugging
				zombiegroup.add_child(zombie)
				zombie.add_to_group("zombies")

func _on_ui_aim_action():
	# Toggle the global aiming state
	Globals.is_global_aiming = !Globals.is_global_aiming

	# Apply the global aiming state to all NPCs
	for npc in npcgroup.get_children():
		npc.is_aiming = Globals.is_global_aiming


func _on_ui_fire_action():
	#camera_2d.zoom = Vector2(2,2)
	for npc in npcgroup.get_children():
		if is_instance_valid(npc):
			if npc.reloaded:
				fire_gun(npc)
				npc.fire_gun()

func _on_ui_ui_interaction_started():
	is_ui_interacting = true
	is_rotating = false
	#print(is_ui_interacting)

func _on_ui_ui_interaction_ended():
	is_ui_interacting = false
	#print(is_ui_interacting)


func _on_wagon_ui_2_hovered_wagon() -> void:
	is_ui_interacting = true


func _on_wagon_ui_2_hovered_wagon_exit() -> void:
	is_ui_interacting = false


func _on_items_item_picked_up(item_type: Variant) -> void:
	print($wagon/wagonUI2.add_next_slot())
