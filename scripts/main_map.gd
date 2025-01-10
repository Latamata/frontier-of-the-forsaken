extends Node2D

@onready var wagonpin = $wagonpin
@onready var ui = $UI
@onready var turn_button = $wagonpin/turn  # Assuming TurnButton is a child of the wagonpin
@onready var paths = [$Path2D, $Path2D2, $Path2D3]

var current_path: Path2D
var speed: float = 50  # Movement speed (pixels per second)

# Define mountain points by line and path connections
var mountain_points_by_line = [
	[1, 7, 10],  # Mountain points for Path2D
	[6, 2, 15]   # Mountain points for Path2D2
]
var path_connections = {
	0: {  # Path2D
		4: {"path_index": 2, "point_index": 0},  # Point 4 in Path2D connects to Path2D3, point 0
		8: {"path_index": 1, "point_index": 0}   # Point 8 in Path2D connects to Path2D2, point 0
	},
	1: {  # Path2D2
		8: {"path_index": 2, "point_index": 3}   # Point 8 in Path2D2 connects to Path2D3, point 3
	},
	2: {  # Path2D3
		0: {"path_index": 0, "point_index": 4},  # Point 0 in Path2D3 connects back to Path2D, point 4
		3: {"path_index": 1, "point_index": 8}   # Point 3 in Path2D3 connects to Path2D2, point 8
	}
}

var point_connections = {
	0: {  # Path2D
		4: {"line": 2, "point": 0},  # Point 4 connects to Path2D3, point 0
		8: {"line": 1, "point": 0}   # Point 8 connects to Path2D2, point 0
	},
	1: {  # Path2D2
		8: {"line": 2, "point": 3}   # Point 8 connects to Path2D3, point 3
	},
	2: {  # Path2D3
		0: {"line": 0, "point": 4},  # Point 0 connects back to Path2D, point 4
		3: {"line": 1, "point": 8}   # Point 3 connects to Path2D2, point 8
	}
}

func _ready():
	# Initialize UI and validate Globals
	ui.hide_map_ui(true)
	ui.set_UI_resources()

	if Globals.current_line < 0 or Globals.current_line >= paths.size():
		print("Invalid Globals.current_line. Falling back to default.")
		Globals.current_line = 0

	current_path = paths[Globals.current_line]
	move_wagon_to_line(current_path, Globals.geo_map_camp)

func move_wagon_to_line(target_line: Path2D, line_point: int):
	# Move the wagon to a specific point on the given path
	if not target_line or not target_line.curve:
		print("Error: Invalid target_line or curve!")
		return

	line_point = clamp(line_point, 0, target_line.curve.get_point_count() - 1)
	var point_position = target_line.curve.get_point_position(line_point)
	wagonpin.global_position = target_line.global_position + point_position
	_update_turn_button_visibility()

func _update_turn_button_visibility():
	# Show the turn button if the wagon is at a point with a connection
	var connection = path_connections.get(Globals.current_line, {}).get(Globals.geo_map_camp, null)
	turn_button.visible = connection != null

func _on_ui_move_action():
	# Move the wagon to the next point and check for connections
	if current_path and current_path.curve:
		var total_points = current_path.curve.get_point_count()
		Globals.geo_map_camp = (Globals.geo_map_camp + 1) % total_points
		move_wagon_to_line(current_path, Globals.geo_map_camp)

func _check_for_connection():
	# Automatically switch paths if there is a connection at the current point
	var current_line_connections = point_connections.get(Globals.current_line, {})
	if Globals.geo_map_camp in current_line_connections:
		var connection = current_line_connections[Globals.geo_map_camp]
		Globals.current_line = connection["line"]
		Globals.geo_map_camp = connection["point"]
		current_path = paths[Globals.current_line]
		move_wagon_to_line(current_path, Globals.geo_map_camp)

func _on_turn_button_down():
	# Handle manual path switching when the turn button is clicked
	var connection = path_connections.get(Globals.current_line, {}).get(Globals.geo_map_camp, null)
	if connection:
		Globals.current_line = connection["path_index"]
		Globals.geo_map_camp = connection["point_index"]
		current_path = paths[Globals.current_line]
		move_wagon_to_line(current_path, Globals.geo_map_camp)
		_update_turn_button_visibility()

func _on_ui_camp_action():
	# Switch to appropriate scene based on the current location
	if current_path and Globals.geo_map_camp in mountain_points_by_line[Globals.current_line]:
		get_tree().change_scene_to_file("res://scenes/mountain.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/desert.tscn")
