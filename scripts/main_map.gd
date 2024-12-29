extends Node2D

@onready var wagonpin = $wagonpin
@onready var ui = $UI
@onready var turn_button = $wagonpin/turn  # Assuming TurnButton is a child of the wagonpin

# Store all paths in an array for dynamic access
@onready var paths = [$Path2D, $Path2D2]
var current_path: Path2D
var speed: float = 50  # Movement speed (pixels per second)

# Define special points or conditions for paths
var mountain_points = [7, 10, 6, 2, 15]

func _ready():
	ui.hide_map_ui(true)
	ui.set_UI_resources()

	# Validate Globals.current_line
	if Globals.current_line < 0 or Globals.current_line >= paths.size():
		print("Invalid Globals.current_line. Falling back to default.")
		Globals.current_line = 0

	current_path = paths[Globals.current_line]
	move_wagon_to_line(current_path, Globals.geo_map_camp)

func move_wagon_to_line(target_line: Path2D, line_point: int):
	if not target_line or not target_line.curve:
		print("Error: Invalid target_line or curve!")
		return

	# Clamp the line_point to valid range
	line_point = clamp(line_point, 0, target_line.curve.get_point_count() - 1)
	var point_position = target_line.curve.get_point_position(line_point)
	wagonpin.global_position = target_line.global_position + point_position
	print("Moved wagon to:", wagonpin.global_position)
	_update_turn_button_visibility()

func _update_turn_button_visibility():
	# Show the turn button if the wagon reaches a specific point
	turn_button.visible = Globals.geo_map_camp == 8

func _on_ui_move_action():
	if current_path and current_path.curve:
		var total_points = current_path.curve.get_point_count()
		Globals.geo_map_camp = (Globals.geo_map_camp + 1) % total_points
		move_wagon_to_line(current_path, Globals.geo_map_camp)
		_update_turn_button_visibility()  # Check visibility after each move


func _on_turn_button_down():
	if Globals.geo_map_camp == 8:
		Globals.geo_map_camp = 0  # Reset to the start of the new path
		Globals.current_line = (Globals.current_line + 1) % paths.size()  # Cycle to the next path
		current_path = paths[Globals.current_line]  # Update to the new path
		move_wagon_to_line(current_path, Globals.geo_map_camp)  # Move wagon on the new path
		_update_turn_button_visibility()


func _on_ui_camp_action():
	if Globals.geo_map_camp in mountain_points:
		get_tree().change_scene_to_file("res://scenes/mountain.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/desert.tscn")
