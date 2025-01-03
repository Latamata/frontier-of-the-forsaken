extends Control

@onready var grid_container = $GridContainer
@onready var hideandshow: Button = $hideandshow

signal hovered_wagon
signal hovered_wagon_exit
signal item_added(item_texture)  # Define the signal

var slot_count = 9
var selected_item = null
var hovered_item = null
var itemlist = []

func _ready():
	populate_inventory()

func populate_inventory():
	for i in range(slot_count):
		var texture_rect = TextureRect.new()

		# Set the stretch mode to avoid scaling
		
		# Optional: Adjust size using the texture's inherent size
		texture_rect.texture = preload("res://assets/inventory.png")  # Empty inventory slot

		# Ensure parent container enforces size constraints
		itemlist.append(false)  # Initialize slots with false (empty)
		texture_rect.name = "Slot_%d" % i
		texture_rect.connect("gui_input", Callable(self, "_on_texture_rect_gui_input").bind(texture_rect))
		texture_rect.connect("mouse_entered", Callable(self, "_on_texture_rect_mouse_entered").bind(texture_rect))
		texture_rect.connect("mouse_exited", Callable(self, "_on_texture_rect_mouse_exited").bind(texture_rect))
		grid_container.add_child(texture_rect)


var original_position = Vector2()

# Handle mouse input for selecting and moving items in inventory
func _on_texture_rect_gui_input(event: InputEvent, texture_rect):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if texture_rect.texture != preload("res://assets/inventory.png"):
				selected_item = texture_rect
				original_position = selected_item.position
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if hovered_item and selected_item:
				var selected_index = grid_container.get_children().find(selected_item)
				var hovered_index = grid_container.get_children().find(hovered_item)

				if itemlist[hovered_index] == false and selected_item.texture != preload("res://assets/inventory.png"):
					hovered_item.texture = selected_item.texture
					selected_item.texture = preload("res://assets/inventory.png")
					itemlist[hovered_index] = true
					itemlist[selected_index] = false
					emit_signal("item_added", hovered_item.texture)  # Emit the signal when item is added

				elif itemlist[hovered_index] == true:
					var temp_texture = selected_item.texture
					selected_item.texture = hovered_item.texture
					hovered_item.texture = temp_texture

					var temp_state = itemlist[selected_index]
					itemlist[selected_index] = itemlist[hovered_index]
					itemlist[hovered_index] = temp_state

			if selected_item:
				selected_item = null

		elif selected_item:
			selected_item.position = original_position
			selected_item = null

# Update the list of items in inventory
func update_itemlist():
	for i in range(grid_container.get_child_count()):
		var slot = grid_container.get_child(i)
		itemlist[i] = slot.texture != preload("res://assets/inventory.png")

# Handle mouse enter and exit events for visual feedback
func _on_texture_rect_mouse_entered(texture_rect):
	hovered_item = texture_rect
	texture_rect.modulate = Color(1, 0, 0)  # Highlight slot in red

func _on_texture_rect_mouse_exited(texture_rect):
	texture_rect.modulate = Color(1, 1, 1)  # Reset to default color
	if hovered_item == selected_item:
		hovered_item = null

# Add a new item to the next available slot
func add_next_slot(item_texture: Texture):
	for i in range(itemlist.size()):
		if not itemlist[i]:  # Find the first empty slot
			var slot = grid_container.get_child(i)
			slot.texture = item_texture  # Use the passed-in item texture
			itemlist[i] = true  # Mark slot as filled
			emit_signal("item_added", item_texture)  # Emit signal with the item texture as argument
			return


# Handle hide and show functionality for inventory
func _on_hideandshow_mouse_entered() -> void:
	emit_signal("hovered_wagon")

func _on_hideandshow_mouse_exited() -> void:
	emit_signal("hovered_wagon_exit")

func _on_hideandshow_button_down() -> void:
	grid_container.visible = not grid_container.visible
