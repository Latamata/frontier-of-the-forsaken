extends Node2D

func _ready() -> void:
	Globals.geo_map_camp = 0
	Globals.current_line = 0

func _unhandled_input(event):
	if event.is_pressed():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
