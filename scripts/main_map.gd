extends Node2D

var path_follow : PathFollow2D
@onready var path_2d = $Path2D
@onready var wagonpin = $wagonpin
@onready var ui = $UI
@onready var path_2d_2 = $Path2D2
var speed : float = 50  # Movement speed (pixels per second)
var current_path : Path2D = path_2d
var mountain_points = [7,10,6,2,15]

func _ready():
	# Debugging: Ensure UI is initialized
	if ui == null:
		print("Error: UI node not found!")
		return

	# Hide UI at the start
	ui.hide_map_ui(true)
	ui.set_UI_resources()

	# Place the wagonpin at the global location based on Globals.geo_map_camp
	#want to get this loading not just the position but also the line
	wagonpin.position = path_2d.curve.get_point_position(Globals.geo_map_camp)


func _on_ui_camp_action():
	#print(Globals.geo_map_camp )
	# Handle camp action based on Globals.geo_map_camp
	#this definatly needs work in detecting the correct points where each map will be loaded
	if Globals.geo_map_camp in mountain_points:
		get_tree().change_scene_to_file("res://scenes/mountain.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/desert.tscn")

func move_wagon_to_line(target_line: Path2D, line_point: int):
	var new_position = target_line.global_position + target_line.curve.get_point_position(line_point)
	#print("Moving wagon to new position:", new_position)
	wagonpin.global_position = new_position

func _on_ui_move_action():
	var total_points = path_2d.curve.get_point_count()
	if Globals.geo_map_camp == 7:
		path_2d_2.visible = true
	
	if Globals.geo_map_camp < total_points - 1:
		Globals.geo_map_camp += 1
		move_wagon_to_line(path_2d, Globals.geo_map_camp)
	else:
		Globals.geo_map_camp = 0

func _on_turn_button_down():
	if Globals.geo_map_camp == 7:
		print("Switching to path 2")
		Globals.geo_map_camp = 1
		current_path = path_2d_2  # Update current_path reference
		move_wagon_to_line(current_path, 1)
	else:
		move_wagon_to_line(current_path, Globals.geo_map_camp)
