extends Node2D

var itemType = "weapon"

func _on_area_2d_body_entered(body):
	if body.name == "player":
		queue_free()

