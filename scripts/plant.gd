extends Area2D

signal item_collected(item)  # Signal to emit when the item is collected

func chopped_down():
	queue_free()  # Removes the object from the scene
	Globals.add_food(20)  # Add food to global resource
	# Emit the signal with the item (e.g., a food item)
	emit_signal("item_collected", preload("res://assets/blackspot.png"))
