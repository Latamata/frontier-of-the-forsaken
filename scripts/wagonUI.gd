extends Control

@onready var grid_container = $GridContainer

# Number of inventory slots (adjust as needed)
var slot_count = 9
var selected_item = null  # Store the currently selected TextureRect
var hovered_item = null  # Store the currently hovered TextureRect

func _ready():
	populate_inventory()

func _process(delta):
	#print(selected_item == grid_container.get_child(0))
	#print(selected_item)
	# If an item is selected, make it follow the mouse
	if selected_item:
		#selected_item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selected_item.position = get_global_mouse_position() - selected_item.size / 2

func populate_inventory():
	for i in range(slot_count):
		var texture_rect = TextureRect.new()
		if i == 1:
			texture_rect.texture = preload("res://assets/blackspot.png")
		else:
			texture_rect.texture = preload("res://assets/inventory.png")
		#texture_rect.mouse_filter = Control.MOUSE_FILTER_PASS  # Allow mouse input
		texture_rect.name = "Slot_%d" % i

		# Connect the `gui_input` signal
		texture_rect.connect("gui_input", Callable(self, "_on_texture_rect_gui_input").bind(texture_rect))

		# Connect mouse enter and exit signals
		texture_rect.connect("mouse_entered", Callable(self, "_on_texture_rect_mouse_entered").bind(texture_rect))
		texture_rect.connect("mouse_exited", Callable(self, "_on_texture_rect_mouse_exited").bind(texture_rect))

		grid_container.add_child(texture_rect)

#var selected_item = null  # Store the currently selected TextureRect
#var hovered_item = null  # Store the currently hovered TextureRect
var original_position = Vector2()  # Store the original position of the selected item

func _on_texture_rect_gui_input(event: InputEvent, texture_rect):
	if event is InputEventMouseButton:
		#print(hovered_item)
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:  
			# Select the TextureRect
			selected_item = texture_rect
			original_position = selected_item.position  # Store the original position
			selected_item.set_z_index(1)  # Bring it to the front
			selected_item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:  
			# Left mouse button released
			selected_item = null
			if hovered_item and selected_item != hovered_item:
				#print(hovered_item, "coconut", selected_item )
				# Swap textures between selected and hovered TextureRect
				var temp_texture = selected_item.texture
				selected_item.texture = hovered_item.texture
				hovered_item.texture = temp_texture

				# Reset the selected item
				#selected_item.set_z_index(0)  
				#selected_item = null

				# Reorganize grid layout
				grid_container.columns = 4
				grid_container.columns = 3
				print('riaodmafodf')
			else:
				# If mouse is released without swapping, return item to its original position
				if selected_item:
					print("this is running")
					selected_item.position = original_position  # Return to original spot
				
				#selected_item.set_z_index(0)
				selected_item = null
				#hovered_item = null

func _on_texture_rect_mouse_entered(texture_rect):
	if selected_item:
		selected_item.set_z_index(0)  # Temporarily reset z_index of selected_item
	hovered_item = texture_rect
	texture_rect.modulate = Color(1, 0, 0)  # Highlight in red for visual feedback

func _on_texture_rect_mouse_exited(texture_rect):
	texture_rect.modulate = Color(1, 1, 1)  # Reset to default
	if hovered_item == selected_item:
		hovered_item = null
