extends Node2D

signal item_picked_up(item_type)

var itemType = "weapon"

func _on_area_2d_body_entered(body):
	if body.name == "player":
		emit_signal("item_picked_up", itemType)  # Emit a signal with the item type
		queue_free()  # Remove the item from the scene
