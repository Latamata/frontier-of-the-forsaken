extends Node2D



func _on_play_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/main_map.tscn")


func _on_quit_button_down() -> void:
	get_tree().quit()
