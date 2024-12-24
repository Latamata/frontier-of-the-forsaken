extends Node2D

var inventory = []  # Stores the player's items

signal item_added(item_type)  # Emit a signal when an item is added to the inventory

# Function to add an item to the inventory
func add_item_to_inventory(item_type: String):
	inventory.append(item_type)  # Add the item type to the inventory
	emit_signal("item_added", item_type)  # Emit the signal when an item is added

# Example of how you could display or interact with the inventory
func display_inventory():
	for item in inventory:
		print(item)
