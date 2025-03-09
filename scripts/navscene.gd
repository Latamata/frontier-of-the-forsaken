extends Node2D

@onready var indicaters = $Enviorment/indicators
@onready var tile_map = $Enviorment/ground
@onready var npcgroup = $Enviorment/sorted/NPCGROUP
@onready var zombiegroup = $Enviorment/sorted/ZOMBIEGROUP
@onready var player = $Enviorment/sorted/player
@onready var ui = $UI
@onready var camera_2d = $Camera2D

var musketman: PackedScene = preload("res://scenes/npc.tscn")
var musketgun: PackedScene = preload("res://scenes/items.tscn")
var IndicatorScene: PackedScene = preload("res://scenes/unitindicator.tscn")
var BULLET: PackedScene = preload("res://scenes/bullet.tscn")
var ZOMBIE: PackedScene = preload("res://scenes/zombie.tscn")

var line_infantry_reloaded = true  
#var circleselected = false
var is_ui_interacting = false  # To track if the mouse button is being held
var is_rotating = false  # To track if the mouse button is being held
var initial_click_position = Vector2()  # Position where the click started
var rotation_angle: float

func _ready():
	
	spawn_zombies(8, 8,Vector2(500,-200), 100.0)
	# On ready spawn npcs
	var starting_position = Vector2(-300, -250)  # Initial position of the first musketman
	var row_offset = Vector2(50, 0)  # Offset for moving down within a column
	var column_offset = Vector2(0, 50)  # Offset for moving to the next column
	var column_height = 2  # Number of musketmen per column
	ui.hide_map_ui(false)
	for i in range(Globals.soldier_count):
		var musketman_instance = musketman.instantiate()  # Assuming musketman is a scene or preloaded resource
		# Calculate the row and column index
		var row = i % column_height  # Alternates between 0 and `column_height - 1`
		var column = i / column_height  # Moves to the next column after every `column_height` musketmen
		# Set the position
		musketman_instance.global_position = starting_position + column * column_offset + row * row_offset
		# Add to the group
		npcgroup.add_child(musketman_instance)

func _process(_delta: float) -> void:
	update_all_speeds()
	ui.get_child(1).get_child(5).value = $gunreloadtimer.time_left

#OPTIMIZATION for placement
var last_update_time = 0.0  # Tracks the last time rotation logic was updated
var update_interval = 100.0  # Minimum interval between updates (in seconds)
func _input(event):
	if is_ui_interacting:
		return
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					camera_2d.zoom = Vector2(1, 1)
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					camera_2d.zoom = Vector2(2, 2)
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					is_rotating = true
					initial_click_position = get_local_mouse_position()
				else:
					is_rotating = false
	# Process rotation logic if active
	if is_rotating:
		var current_time = Time.get_ticks_msec()
		if current_time - last_update_time > update_interval:
			process_rotation()
			last_update_time = current_time
		assign_npcs_to_indicators(rotation_angle)
	if event.is_action_pressed("collect") and is_instance_valid(player):
		# Check if the player is near any plant
		for area in $Enviorment/plantgroup.get_children():  # Loop through all plants in the level
			if area is Area2D and area.has_method("try_collect") and area.player_nearby:
				area.try_collect()  # Call the plant's try_collect method
				ui.update_resources()
	if Input.is_action_just_pressed("one_key") and player:
		_on_ui_fire_action()
	if Input.is_action_just_pressed("ui_accept") and is_instance_valid(player):
		print()
		var current_weapon = player.get_current_weapon()
		
		if current_weapon == player.gun:  # Ensure only the gun can shoot
			fire_gun(player)

func update_speed_based_on_tile(entity):
	if not is_instance_valid(entity):
		return
	
	var entity_tile = tile_map.local_to_map(entity.global_position)  # Convert entity position to tile coordinates
	var tile_data = tile_map.get_cell_tile_data(entity_tile)  # Fetch tile data

	if tile_data and tile_data.get_custom_data("slow"):  # Check for custom data (adjust key as needed)
		entity.slow_affect(true)
	else:
		entity.slow_affect(false)

func update_all_speeds():
	for entity in npcgroup.get_children() + zombiegroup.get_children() + [player]:  # Include all entities
		update_speed_based_on_tile(entity)
		pass

func process_rotation():
	var current_mouse_position = get_local_mouse_position()
	if initial_click_position.distance_to(current_mouse_position) > 5:  # Only update if the mouse moved significantly
		rotation_angle = (current_mouse_position - initial_click_position).angle()
		var nearest_tile_position = get_nearest_tile(current_mouse_position)
		spawn_double_line_at_position(nearest_tile_position, rotation_angle)
	#assign_npcs_to_indicators(rotation_angle)

func get_nearest_tile(selected_position: Vector2, exclude_positions := []) -> Vector2:
	var tile_coords = tile_map.local_to_map(tile_map.to_local(selected_position))
	var search_radius = 1

	while search_radius < 15:
		for x_offset in range(-search_radius, search_radius + 1):
			for y_offset in range(-search_radius, search_radius + 1):
				var check_coords = tile_coords + Vector2i(x_offset, y_offset)
				if exclude_positions.has(check_coords):
					continue
				var tile_data = tile_map.get_cell_tile_data(check_coords)
				
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
	# Fire the musket ball
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

func spawn_zombies(rows: int, cols: int, center: Vector2, radius: float):
	for _row in range(rows):
		for _col in range(cols):
			var zombie = ZOMBIE.instantiate()
			zombie.target = $waypoint1
			# Spawn randomly within a circle around the center
			var angle = randf() * TAU
			var distance = randf_range(0, radius)
			zombie.position = center + Vector2(cos(angle), sin(angle)) * distance
			zombiegroup.add_child(zombie)

func _on_ui_aim_action():
	# Toggle the global aiming state
	Globals.is_global_aiming = !Globals.is_global_aiming
	
	# Apply the global aiming state to all NPCs
	for npc in npcgroup.get_children():
		npc.is_aiming = Globals.is_global_aiming

func _on_ui_fire_action():
	if line_infantry_reloaded:
		for npc in npcgroup.get_children():
			if is_instance_valid(npc):
				fire_gun(npc)
		line_infantry_reloaded = false
		$gunreloadtimer.start()

#prevent unit selection when ai is hovered
func _on_ui_ui_interaction_started():
	is_ui_interacting = true
	is_rotating = false
	
func _on_ui_ui_interaction_ended() -> void:
	is_ui_interacting = false

func _on_ui_weapon_toggle() -> void:
	if player != null:
		player.switch_weapon()

func _on_ui_inventory_item_dropped(item: Variant) -> void:
	var droppeditem = musketgun.instantiate()  # Create the item instance
	droppeditem.position = player.position + Vector2(0, 40)  # Drop slightly below the player
	
	# Assuming 'droppeditem' is a Sprite or has a Sprite child node
	if droppeditem is Sprite2D:
		droppeditem.texture = item  # Assuming 'item' is a texture or image you want to apply
	elif droppeditem.has_node("Sprite2D"):
		var sprite = droppeditem.get_node("Sprite2D") as Sprite2D
		sprite.texture = item  # Apply the texture to the sprite
	get_tree().current_scene.add_child(droppeditem)  # Add it to the scene
	print("Item dropped at position:", droppeditem.position)

func _on_gunreloadtimer_timeout() -> void:
	line_infantry_reloaded = true
	print('running')

func _on_waypoint_body_entered(body: Node2D) -> void:
		if body.is_in_group('zombie'):
			for entity in zombiegroup.get_children():
				entity.target = $waypoint2
func _on_waypoint_2_body_entered(body: Node2D) -> void:
		if body.is_in_group('zombie'):
			for entity in zombiegroup.get_children():
				entity.target = $waypoint3


func _on_waypoint_3_body_entered(body: Node2D) -> void:
		if body.is_in_group('zombie'):
			for entity in zombiegroup.get_children():
				entity.target = $waypoint4


func _on_waypoint_4_body_entered(body: Node2D) -> void:
		if body.is_in_group('zombie'):
			for entity in zombiegroup.get_children():
				entity.target = $waypoint1
