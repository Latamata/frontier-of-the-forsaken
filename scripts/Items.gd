extends Node2D




signal item_collected  # Custom signal to notify the Level script


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "player":  # Make sure the body is the player or another object you want to interact with
		# Emit the custom signal to notify the Level script
		emit_signal("item_collected")  # Send the item reference or other data
		print('adaslkfnas')
