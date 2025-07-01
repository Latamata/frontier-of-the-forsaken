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
@onready var waypoints = [ $waypoint1, $waypoint2, $waypoint3, $waypoint4]
@onready var day_lighting: CanvasModulate = $day_lighting

var musketman: PackedScene = preload("res://scenes/soldier.tscn")
var IndicatorScene: PackedScene = preload("res://scenes/unitindicator.tscn")
var TREASURE_CHEST: PackedScene = preload("res://scenes/chest.tscn")
var BULLET: PackedScene = preload("res://scenes/bullet.tscn")
var ZOMBIE: PackedScene = preload("res://scenes/zombie.tscn")
var TANK_ZOMBIE: PackedScene = preload("res://scenes/zombie_two.tscn")

var chest_looted = false  # To track if the mouse button is being held
var is_ui_interacting = false  # To track if the mouse button is being held
var is_rotating = false  # To track if the mouse button is being held
var initial_click_position = Vector2()  # Position where the click started
var rotation_angle: float

func _ready() -> void:
	ui.tuts.hide_instruction("battle", Globals.show_battle_tut)
	day_lighting_setup()
	for waypoint in waypoints:
		waypoint.zombie_entered.connect(_on_waypoint_body_entered.bind(waypoint))
	Globals.is_global_aiming = false
	var custom_cursor = load("res://assets/mousepointer.png")
	Input.set_custom_mouse_cursor(custom_cursor)
	Input.set_custom_mouse_cursor(custom_cursor, Input.CURSOR_ARROW, Vector2(30, 30))  # Assuming 32x32 image
	ui.visible = true
	#sets up UI to change when the global stat changes
	Globals.connect( "collect_item", _on_player_collect_item )
	Globals.connect( "sword_spec_dmgrdc", sword_spec_dmgcheck )
	Globals.connect("level_up", Callable(self, "_on_level_up"))
	get_tree().paused = false
	$wave_timer.start()
	var starting_position = Vector2(-200, -90)  # Initial position of the first musketman
	var row_offset = Vector2(50, 0)  # Offset for moving down within a column
	var column_offset = Vector2(0, 50)  # Offset for moving to the next column
	var column_height = 2  # Number of musketmen per column
	ui.hide_map_ui(false)
	for i in range(Globals.soldier_count):
		var musketman_instance = musketman.instantiate()
		npcgroup.add_child(musketman_instance)
		musketman_instance.set_brightness = player.point_light_2d.energy
		create_light_bearer()	
		var row = i % column_height
		var column = floori(float(i) / float(column_height))
		musketman_instance.connect("soldier_died", Callable(self, "_on_soldier_died"))
		musketman_instance.global_position = starting_position + column * column_offset + row * row_offset
		# Set the correct aiming state before adding to scene
		musketman_instance.is_aiming = Globals.is_global_aiming

var time_since_speed_update = 0.0
const SPEED_UPDATE_INTERVAL = 0.5  # seconds
func _process(delta):
	time_since_speed_update += delta
	if time_since_speed_update >= SPEED_UPDATE_INTERVAL:
		update_all_speeds()
		#update_speed_based_on_tile(player)
		time_since_speed_update = 0.0

#OPTIMIZATION for placement
var last_update_time = 0.0  # Tracks the last time rotation logic was updated
var update_interval = 200  # Minimum interval between updates (in seconds)
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
		if current_weapon == player.gun && player.gun_reloaded: 
			fire_gun(player)
			player.player_shoot()
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
		# Calculat the ideal indicator position
		var indicator_position = start_position + offset
		# Get he nearest tile position to snap to
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
	musketBall.shooter = firing_entity
	musketBall.direction = direction
	musketBall.rotation = adjusted_angle
	add_child(musketBall)

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

func _on_player_collect_item() -> void:
	ui.update_resources()
	
func _on_level_up():
	if player:
		player.level_up(Globals.level)

var using_guns = true
func _on_ui_weapon_toggle() -> void:
	using_guns = !using_guns
	var weapon = "gun" if using_guns else "sabre"
	for entity in npcgroup.get_children():
		if entity.has_method("switch_weapon"):
			entity.switch_weapon(weapon)

func _on_player_heal_npc(area: Area2D) -> void:
	for npc in npcgroup.get_children():
		if npc.HEALTH < npc.MAX_HEALTH:
			npc.take_damage(-5)
			area.collected()  # Now the NPC collects it instead
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

var light_reassign_in_progress := false
func _on_soldier_died(light_holder: bool) -> void:
	_play_sound(preload("res://sound/soldier_die.wav"), global_position)
	if light_reassign_in_progress:
		return
	if light_holder:
		light_reassign_in_progress = true
		$Timer.start()
		print("Light-carrying soldier has died!")

func _on_timer_timeout() -> void:
	create_light_bearer()
	light_reassign_in_progress = false

func create_light_bearer() -> void:
	var npcs = npcgroup.get_children()
	if npcs.size() == 0:
		return  # no one to assign the light to
	# Remove all existing lights and reset their status
	for npc in npcs:
		if npc.has_method("remove_point_light"):
			npc.remove_point_light()
		npc.light_holder = false
	# Pick the middle NPC and give them the light
	var middle_index = int(npcs.size() / 2.0)
	var new_light_holder = npcs[middle_index]
	new_light_holder.is_aiming = Globals.is_global_aiming
	
	new_light_holder.light_holder = true
	new_light_holder.add_point_light()

func _on_zombie_died():
	_play_sound(preload("res://sound/zombiedeath.wav"), global_position)
	ui.update_xp_talents()
	await get_tree().create_timer(0.6).timeout  # waits ~1/10th of a second
	if zombiegroup.get_child_count() == 0:
		ui.hide_or_show_wavecomplete(true)
		ui.hide_show_camp_button(true)
		ui.travel_mode = true
		$wave_timer.start()
		print("All zombies are dead! Spawning chest...")
		spawn_treasure_chest()

func get_random_waypoint(exclude: Node) -> Node:
	var available = waypoints.filter(func(wp): return wp != exclude)
	return available[randi() % available.size()]

func _on_waypoint_body_entered(waypoint: Node) -> void:
	await get_tree().create_timer(0.1).timeout
	for zombie in zombiegroup.get_children():
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(zombie) and zombie.is_inside_tree():
			zombie.target = get_random_waypoint(waypoint)

var max_zombies = 64
func _on_wave_timer_timeout() -> void:
	Globals.wave_count += 1
	ui.update_wave(Globals.wave_count)
	ui.hide_or_show_wavecomplete(false)
	ui.hide_show_camp_button(false)
	ui.travel_mode = false
	var green_amount = min(8 + (Globals.wave_count * 2), max_zombies)  # Increases by 2 per wave
	var purple_amount = clamp( (Globals.wave_count * 0.1), 0.1, 2.0)  # Increases slowly, capped at 2.0
	# Green zombies
	var green_spawn_x = ceil(sqrt(green_amount))
	var green_spawn_y = ceil(green_amount / green_spawn_x)
	var random_waypoint_green = waypoints[randi() % waypoints.size()]
	spawn_zombies(green_spawn_x, green_spawn_y, random_waypoint_green.position, 150.0, random_waypoint_green)
	# Purple zombies
	var purple_count = int(purple_amount)
	if purple_count > 0:
		for i in purple_count:
			var random_waypoint_purple = waypoints[randi() % waypoints.size()]
			spawn_zombies(1, 1, random_waypoint_purple.position, 0.0, random_waypoint_purple)

func spawn_zombies(rows: int, cols: int, center: Vector2, radius: float, exclude_waypoint: Node = null, tank_chance: float = 0.2) -> void:
	for _row in range(rows):
		for _col in range(cols):
			var zombie
			if randf() < tank_chance:
				zombie = TANK_ZOMBIE.instantiate()
				zombie.SPEED = 45
			else:
				zombie = ZOMBIE.instantiate()
			var angle = randf() * TAU
			var distance = randf_range(32, radius)
			zombie.position = center + Vector2(cos(angle), sin(angle)) * distance
			# Assign a target that's not the spawn waypoint
			zombie.target = get_random_waypoint(exclude_waypoint)
			zombie.connect("zombie_died", Callable(self, "_on_zombie_died"))
			zombiegroup.add_child(zombie)
			await get_tree().create_timer(0.2).timeout

func _on_player_one_pump() -> void:
	if player:
		ui.get_child(0).get_node("reloadtimer").value = player.reload_pumps 

func sword_spec_dmgcheck():
	player.sword_spec_damage_reduce = true

func day_lighting_setup():
	if Globals.time_of_day == "night":
		day_lighting.color = Color("224e9b") 
		player.point_light_2d.energy = 0.50
	elif Globals.time_of_day == "morning":
		day_lighting.color = Color("e7817f")
		player.point_light_2d.energy = 0.34
	elif Globals.time_of_day == "evening":
		day_lighting.color = Color("b95eb6") 
		player.point_light_2d.energy = 0.34
	else:
		day_lighting.color = Color("ffffff") 
		player.point_light_2d.energy = 0.0


func _on_playermenu_show_tutorial_requested() -> void:
	ui.tuts.hide_instruction("battle", true)


func _on_ambience_finished() -> void:
	$ambience.play()
