extends Control
@onready var grid_container = $GridContainer

# Number of inventory slots (adjust as needed)
var slot_count = 9
var selected_item = null  # Store the currently selected TextureRect
var hovered_item = null  # Store the currently hovered TextureRect
var itemlist = []
func _ready():
	populate_inventory()


func populate_inventory():
	for i in range(slot_count):
		var texture_rect = TextureRect.new()
		
		#if i == 1:
		itemlist.append(true)
			#texture_rect.filled = true
			#texture_rect.texture = preload("res://assets/rose.png")
		#else:
			#itemlist.append(false)
			#texture_rect.texture = preload("res://assets/inventory.png")
		texture_rect.name = "Slot_%d" % i
		
		texture_rect.texture = preload("res://assets/inventory.png")
		# Connect the gui_input signal
		texture_rect.connect("gui_input", Callable(self, "_on_texture_rect_gui_input").bind(texture_rect))

		# Connect mouse enter and exit signals
		texture_rect.connect("mouse_entered", Callable(self, "_on_texture_rect_mouse_entered").bind(texture_rect))
		texture_rect.connect("mouse_exited", Callable(self, "_on_texture_rect_mouse_exited").bind(texture_rect))

		grid_container.add_child(texture_rect)

var original_position = Vector2()  # Store the original position of the selected item

func _on_texture_rect_gui_input(event: InputEvent, texture_rect):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:  
			# Check if the selected item has a valid texture (non-empty slot)
			if texture_rect.texture != preload("res://assets/inventory.png"):
				selected_item = texture_rect
				original_position = selected_item.position

		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:  
			if hovered_item and selected_item:
				# Get indices of selected and hovered slots
				var selected_index = grid_container.get_children().find(selected_item)
				var hovered_index = grid_container.get_children().find(hovered_item)
				
				# Case 1: Dropping onto an empty slot
				if itemlist[hovered_index] == false and selected_item.texture != preload("res://assets/inventory.png"):
					hovered_item.texture = selected_item.texture  # Move texture
					selected_item.texture = preload("res://assets/inventory.png")  # Clear original slot

					itemlist[hovered_index] = true  # Update hovered slot as occupied
					itemlist[selected_index] = false  # Mark original slot as empty

				# Case 2: Swapping between occupied slots
				elif itemlist[hovered_index] == true:
					# Swap textures and states
					var temp_texture = selected_item.texture
					selected_item.texture = hovered_item.texture
					hovered_item.texture = temp_texture

					var temp_state = itemlist[selected_index]
					itemlist[selected_index] = itemlist[hovered_index]
					itemlist[hovered_index] = temp_state

			# Reset z_index and clear selection
			if selected_item:
				selected_item = null

		# If no valid drop, reset to original position
		elif selected_item:
			selected_item.position = original_position
			selected_item = null

func update_itemlist():
	for i in range(grid_container.get_child_count()):
		var slot = grid_container.get_child(i)
		itemlist[i] = slot.texture != preload("res://assets/inventory.png")

func _on_texture_rect_mouse_entered(texture_rect):
	hovered_item = texture_rect
	texture_rect.modulate = Color(1, 0, 0)  # Highlight in red for visual feedback

func _on_texture_rect_mouse_exited(texture_rect):
	texture_rect.modulate = Color(1, 1, 1)  # Reset to default
	if hovered_item == selected_item:
		hovered_item = null

func add_next_slot(_placeholder):
	#var ListCount = 0

	for i in range(itemlist.size()):  # Iterate by index
		var item = itemlist[i]

		if item:
			# Update the corresponding child's texture in grid_container
			var slot = grid_container.get_child(i)
			slot.texture = preload("res://assets/blackspot.png")
			itemlist[i] = false  
			return
		#ListCount +=1

func hideorshow() -> void:
	if grid_container.visible:
		grid_container.visible = false
		$ColorRect.visible = false
		#hideandshow.visible = true
	else:
		grid_container.visible = true
		$ColorRect.visible = true
		#hideandshow.visible = false
