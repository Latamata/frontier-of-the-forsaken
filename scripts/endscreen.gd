extends Node2D

func _ready() -> void:
	Globals.reset()

func _unhandled_input(event):
	if event.is_pressed():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_audio_stream_player_2d_finished() -> void:
	$AudioStreamPlayer2D.play()
