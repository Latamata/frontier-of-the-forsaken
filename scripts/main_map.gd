extends Node2D

@onready var path_2d = $Path2D
@onready var path_2d_2 = $Path2D2
@onready var wagonpin = $wagonpin
@onready var ui = $UI
@onready var turn_button = $wagonpin/turn  # Assuming TurnButton is a child of the UI
var speed: float = 50  # Movement speed (pixels per second)

# Track the current path (global variable)
var current_path: Path2D = path_2d

var mountain_points = [7, 10, 6, 2, 15]

func _ready():
	if ui == null or path_2d == null or path_2d_2 == null or wagonpin == null:
		print("Error: One or more nodes are missing!")
		return

	# Debugging: Check if the path nodes are initialized properly
	if path_2d == null:
		print("Error: path_2d node is null!")
	if path_2d_2 == null:
		print("Error: path_2d_2 node is null!")
	
	ui.hide_map_ui(true)
	ui.set_UI_resources()
	
	# Ensure that the global path is set correctly
	current_path = Globals.current_line if Globals.current_line != null else path_2d
	#print("Current path initialized:", current_path)
	
	move_wagon_to_line(current_path, Globals.geo_map_camp)
	_update_turn_button_visibility()

func move_wagon_to_line(target_line: Path2D, line_point: int):
	if target_line == null:
		print("Error: target_line is null!")
		return
	
	if target_line.curve == null:
		print("Error: target_line.curve is null!")
		return
	
	var point_position = target_line.curve.get_point_position(line_point)
	wagonpin.global_position = target_line.global_position + point_position
	#print("Moved wagon to:", wagonpin.global_position)
	
	# Update the global current path
	Globals.current_line = target_line

	_update_turn_button_visibility()

# Update visibility of the turn button based on the wagon's position
func _update_turn_button_visibility():
	# Make turn button visible when the wagon reaches the specific point (for example, point 8)
	if Globals.geo_map_camp == 8:
		turn_button.visible = true
	else:
		turn_button.visible = false

func _on_ui_move_action():
	print(current_path)
	var total_points = current_path.curve.get_point_count()
	if Globals.geo_map_camp < total_points - 1:
		Globals.geo_map_camp += 1
	else:
		Globals.geo_map_camp = 0

	move_wagon_to_line(current_path, Globals.geo_map_camp)

func _on_turn_button_down():
	if Globals.geo_map_camp == 8:
		Globals.geo_map_camp = 1
		current_path = path_2d_2  # Update to the new path
		move_wagon_to_line(path_2d_2, 0)  # Move the wagon to the start of the new path
		_update_turn_button_visibility()  # Hide the button again after the turn

func _on_ui_camp_action():
	# Handle camp action based on Globals.geo_map_camp
	if Globals.geo_map_camp in mountain_points:
		get_tree().change_scene_to_file("res://scenes/mountain.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/desert.tscn")
