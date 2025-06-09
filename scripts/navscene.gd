extends Node2D

@onready var indicators = $Enviorment/indicators
@onready var tile_map = $Enviorment/ground
@onready var npcgroup = $Enviorment/sorted/NPCGROUP
@onready var zombiegroup = $Enviorment/sorted/ZOMBIEGROUP
@onready var player = $Enviorment/sorted/player
@onready var ui = $UI
@onready var camera_2d = $Camera2D
@onready var wave_timer: Timer = $wave_timer
@onready var chest_container: Node2D = $Enviorment/chests
@onready var waypoints = [
	$waypoint1,
	$waypoint2,
	$waypoint3,
	$waypoint4
]

var musketman: PackedScene = preload("res://scenes/npc.tscn")
var IndicatorScene: PackedScene = preload("res://scenes/unitindicator.tscn")
var TREASURE_CHEST: PackedScene = preload("res://scenes/chest.tscn")
var BULLET: PackedScene = preload("res://scenes/bullet.tscn")
var ZOMBIE: PackedScene = preload("res://scenes/zombie.tscn")
var TANK_ZOMBIE: PackedScene = preload("res://scenes/zombie_two.tscn")

#var line_infantry_reloaded = true  
#var circleselected = false
var chest_looted = false  # To track if the mouse button is being held
var is_ui_interacting = false  # To track if the mouse button is being held
var is_rotating = false  # To track if the mouse button is being held
var initial_click_position = Vector2()  # Position where the click started
var rotation_angle: float

func _ready():
	for wp in waypoints:
		wp.connect("body_entered", Callable(self, "_on_any_waypoint_body_entered"))

	var custom_cursor = load("res://assets/mousepointer.png")
	Input.set_custom_mouse_cursor(custom_cursor)
	Input.set_custom_mouse_cursor(custom_cursor, Input.CURSOR_ARROW, Vector2(30, 30))  # Assuming 32x32 image
	ui.visible = true
	#sets up UI to change when the global stat changes
	Globals.connect( "collect_item", _on_player_collect_item )
	Globals.connect("level_up", Callable(self, "_on_level_up"))
	get_tree().paused = false
	$wave_timer.start()
	#spawn_zombies(2, 2, $waypoint1.position, 100.0)
	# On ready spawn npcs
	var starting_position = Vector2(-200, 50)  # Initial position of the first musketman
	var row_offset = Vector2(50, 0)  # Offset for moving down within a column
	var column_offset = Vector2(0, 50)  # Offset for moving to the next column
	var column_height = 2  # Number of musketmen per column
	ui.hide_map_ui(false)
	for i in range(Globals.soldier_count):
		var musketman_instance = musketman.instantiate()  # Assuming musketman is a scene or preloaded resource
		# Calculate the row and column index
		var row = i % column_height  # Alternates between 0 and `column_height - 1`
		var column = floori(float(i) / float(column_height))
		musketman_instance.connect("soldier_died", Callable(self, "_on_soldier_died"))
		# Set the position
		musketman_instance.global_position = starting_position + column * column_offset + row * row_offset
		# Add to the group
		npcgroup.add_child(musketman_instance)

func _process(_delta: float) -> void:
	update_all_speeds()
	if player:
		ui.get_child(0).get_node("reloadtimer").value = player.reload_pumps 

#OPTIMIZATION for placement
var last_update_time = 0.0  # Tracks the last time rotation logic was updated
var update_interval = 100  # Minimum interval between updates (in seconds)
func _input(event):
	if is_ui_interacting:
		return
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					camera_2d.zoom *= 0.9  # Zoom in
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					camera_2d.zoom *= 1.1  # Zoom out
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
	else:
		is_rotating = false
		assign_npcs_to_indicators(rotation_angle)

	if Input.is_action_just_pressed("collect") and player:
		player.looting = true
	if Input.is_action_just_released("collect") and player:
		player.looting = false
	if Input.is_action_just_pressed("one_key") and player:
		player.switch_weapon()
	if Input.is_action_just_pressed("ui_accept") and is_instance_valid(player):
		var current_weapon = player.get_current_weapon()
		if current_weapon == player.gun && player.gun_reloaded:  # Ensure only the gun can shoot
			player.player_shoot()
			fire_gun(player)
		elif current_weapon == player.sabre && player.melee_reloaded:
			player.sword_attack()

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

func get_nearest_tile(selected_position: Vector2, exclude_positions := []) -> Vector2:
	var tile_coords = tile_map.local_to_map(tile_map.to_local(selected_position))
	var search_radius = 1

	while search_radius < 16:
		for x_offset in range(-search_radius, search_radius + 1):
			for y_offset in range(-search_radius, search_radius + 1):
				var check_coords = tile_coords + Vector2i(x_offset, y_offset)
				if exclude_positions.has(check_coords):
					continue
				var tile_data = tile_map.get_cell_tile_data(check_coords)
				
				if tile_data and bool(tile_data.get_custom_data_by_layer_id(0)):
					var adjusted_position = tile_map.map_to_local(check_coords) + Vector2(tile_map.tile_set.tile_size) / 2
					
					return adjusted_position
		search_radius += 1
	# Default return if no valid tile is found
	var fallback_position = tile_map.map_to_local(tile_coords) + Vector2(tile_map.tile_set.tile_size) / 2
	fallback_position.x = selected_position.x  # Align to mouse position if needed
	return fallback_position

# Function to rotate a position around a point by a given angle
func spawn_double_line_at_position(start_position: Vector2, unit_rotation_angle: float = 0.0):
	# Clear previous indicators
	for child in indicators.get_children():
		child.queue_free()

	var row_spacing = 20
	var indicator_spacing = 60
	var placed_positions = []

	var unit_count = npcgroup.get_child_count()
	var line_count = ceil(unit_count / 2.0)
	var line_center_offset = -((line_count - 1) * indicator_spacing) / 2.0

	# Directional vectors based on rotation
	var forward_vector = Vector2(0, 1).rotated(unit_rotation_angle)
	var side_vector = Vector2(1, 0).rotated(unit_rotation_angle)

	for i in range(unit_count):
		var indicator_instance = IndicatorScene.instantiate()

		# Calculate the current position in line (this would be the "ideal" position without snapping)
		var row = i % 2
		var position_in_line = floor(i / 2.0)

		var forward_offset = forward_vector * ((position_in_line * indicator_spacing) + line_center_offset)
		var side_offset = side_vector * ((row * 2 - 1) * row_spacing)
		var offset = forward_offset + side_offset

		# Calculate the ideal indicator position
		var indicator_position = start_position + offset
		
		# Get the nearest tile position to snap to
		var snapped_position = get_nearest_tile(indicator_position, placed_positions)

		# Check if the distance to the snapped position is small enough to accept the tile snapping
		if snapped_position.distance_to(indicator_position) < 10:  # threshold can be adjusted
			indicator_instance.position = snapped_position
		else:
			indicator_instance.position = indicator_position  # Use the ideal position if snapping doesn't improve
		# Add the indicator to the scene
		indicators.add_child(indicator_instance)
		# Keep track of the tile positions we've used to avoid overlapping
		placed_positions.append(tile_map.local_to_map(indicator_instance.position))

func assign_npcs_to_indicators(forward_angle: float):
	var indicator_group = indicators.get_children()  # Get all children (indicators) of the 'indicators' node
	for i in range(min(npcgroup.get_child_count(), indicator_group.size())):  # Use .size() for the list of children
		var npc = npcgroup.get_child(i)
		var indicator = indicator_group[i]
		#print(npc.is_aiming)
		npc.forward_angle = forward_angle
		npc.move_to_position(indicator.position)


# Add the 'async' keyword to allow for await-based delays
func fire_gun(firing_entity: Node2D):
	if not is_instance_valid(firing_entity) or not firing_entity.has_node("Musket/Marker2D"):
		print("Error: Invalid firing entity or missing Musket/Marker2D node.")
		return

	# 🔄 Add a small random delay before firing (e.g., simulate flintlock delay)
	await get_tree().create_timer(randf_range(0.05, 0.5)).timeout

	var musketBall = BULLET.instantiate()
	var gun_marker = firing_entity.get_node("Musket/Marker2D")

	# 🔊 Play sound at gun's position
	_play_sound(preload("res://sound/Musket Single Shot Distant 3 - QuickSounds.com.mp3"),gun_marker.global_position)

	musketBall.position = gun_marker.global_position

	var gun_angle = gun_marker.global_rotation
	var adjusted_angle = gun_angle + deg_to_rad(randf_range(-3, 3))
	var direction = Vector2(cos(adjusted_angle), sin(adjusted_angle)).normalized()

	musketBall.damage_bonus += Globals.talent_tree["gun_damage"]["level"]
	musketBall.direction = direction
	musketBall.rotation = adjusted_angle
	add_child(musketBall)

func spawn_zombies(rows: int, cols: int, center: Vector2, radius: float, tank_chance: float = 0.2):
	for _row in range(rows):
		for _col in range(cols):
			# Randomly decide whether to spawn a tank zombie
			var zombie
			if randf() < tank_chance:
				
				zombie = TANK_ZOMBIE.instantiate()
				zombie.SPEED = 45
			else:
				zombie = ZOMBIE.instantiate()
				
			zombie.target = $waypoint1
			# Spawn randomly within a circle around the center
			var angle = randf() * TAU
			var distance = randf_range(0, radius)
			zombie.connect("zombie_died", Callable(self, "_on_zombie_died"))
			zombie.position = center + Vector2(cos(angle), sin(angle)) * distance
			#zombie.connect("death_signal", Callable(self, "_on_death_signal"))
			zombiegroup.add_child(zombie)

func _on_ui_aim_action():
	# Toggle the global aiming state
	Globals.is_global_aiming = !Globals.is_global_aiming
	
	# Apply the global aiming state to all NPCs
	for npc in npcgroup.get_children():
		npc.is_aiming = Globals.is_global_aiming

func _on_ui_fire_action():
	#if line_infantry_reloaded:
	for npc in npcgroup.get_children():
		if is_instance_valid(npc) and not npc.moving:  # Ensure NPC is not moving
			if npc.weapon_in_use == 'gun' and npc.fire_gun():
				fire_gun(npc)


#prevent unit selection when ai is hovered
func _on_ui_ui_interaction_started():
	is_ui_interacting = true
	is_rotating = false
	
func _on_ui_ui_interaction_ended() -> void:
	is_ui_interacting = false

func _on_any_waypoint_body_entered(body: Node2D) -> void:
	if body.is_in_group("zombie"):
		body.target = get_random_waypoint(body.target)


func _on_auto_shoot_timer_timeout() -> void:
	for npc in npcgroup.get_children():
		if is_instance_valid(npc) and not npc.moving && npc.target != null:  # Ensure NPC is not moving
			if npc.weapon_in_use == 'gun' && npc.fire_gun():
				fire_gun(npc)

var is_auto_shooting_enabled = false  # To track if auto shooting is on or off
func _on_ui_auto_shoot_action() -> void:
	if is_auto_shooting_enabled:
		$auto_shoot_timer.stop()  # Stop the timer if auto-shooting is already enabled
	else:
		$auto_shoot_timer.start()  # Start the timer if auto-shooting is off
	is_auto_shooting_enabled = !is_auto_shooting_enabled  # Toggle the state

var max_zombies = 64
func _on_wave_timer_timeout() -> void:
	ui.update_wave(Globals.wave_count)
	#if Globals.wave_count >= 1:
		#spawn_treasure_chest()
	var spawn_amount = min(8 + (Globals.wave_count * 2), max_zombies)  # Increases by 2 per wave
	var spawn_x = ceil(sqrt(spawn_amount))  # Distribute evenly
	var spawn_y = ceil(spawn_amount / spawn_x)

	# Define an array of waypoints
	var waypoints = [
		$waypoint1,
		$waypoint2,
		$waypoint3,
		$waypoint4  # Add more as needed
	]
	# Pick a random waypoint
	var random_waypoint = waypoints[randi() % waypoints.size()]

	# Spawn zombies at the random waypoint
	spawn_zombies(spawn_x, spawn_y, random_waypoint.position, 120.0)
	
	Globals.wave_count += 1
	
func get_random_waypoint(exclude: Node) -> Node:
	var available = waypoints.filter(func(wp): return wp != exclude)
	return available[randi() % available.size()]

func _on_player_collect_item() -> void:
	ui.update_resources()
	
func _on_level_up():
	#print('leveled up')
	player.level_up(Globals.level)
	#$Tween.tween_property($LevelUpLabel, "modulate:a", 0, 1.5)

var using_guns = true
func _on_ui_weapon_toggle() -> void:
	using_guns = !using_guns
	var weapon = "gun" if using_guns else "sabre"

	for entity in npcgroup.get_children():
		if entity.has_method("switch_weapon"):
			entity.switch_weapon(weapon)


func _on_player_heal_npc() -> void:
	for npc in npcgroup.get_children():
		if npc.HEALTH < npc.MAX_HEALTH:
			npc.take_damage(-1)
			return

func spawn_treasure_chest():
	if chest_container.get_child_count() > 0:
		var chest = chest_container.get_child(0)
		chest.chest_amount += 5 * Globals.wave_count
	else:
		var chest_instance = TREASURE_CHEST.instantiate()
		chest_instance.chest_amount = 5 * Globals.wave_count
		chest_instance.position = Vector2(465, 364)
		chest_container.add_child(chest_instance)

func _on_zombiegroup_child_exiting_tree(_node: Node) -> void:
	ui.update_xp_talents()
	
	await get_tree().create_timer(0.5).timeout  # waits ~1/10th of a second
	
	if $Enviorment/sorted/ZOMBIEGROUP.get_child_count() == 0:
		$wave_timer.start()
		print("All zombies are dead! Spawning chest...")
		spawn_treasure_chest()

func _on_player_died() -> void:
	ui.turn_screen_red()
	$playermenu.visible = true
	print('player died signal recieved')

func _play_sound(stream: AudioStream, sound_position: Vector2):
	var sound_player = AudioStreamPlayer2D.new()
	sound_player.stream = stream
	sound_player.global_position = sound_position
	sound_player.connect("finished", Callable(sound_player, "queue_free"))
	add_child(sound_player)
	sound_player.play()

func _on_soldier_died():
	_play_sound(preload("res://sound/soldier_die.wav"), global_position)

func _on_zombie_died():
	_play_sound(preload("res://sound/zombiedeath.wav"), global_position)
