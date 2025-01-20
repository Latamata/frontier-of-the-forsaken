extends Node2D

# Assume you have an `item_id` variable set up to uniquely identify this item
var item_id: String = "Gun"  # Replace with the actual item ID

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "player":  # Make sure the body is the player
		queue_free()  # Remove the item from the scene
