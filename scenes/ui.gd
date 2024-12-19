extends CanvasLayer

signal fire_action
signal aim_action
signal camp_action
signal move_action
signal ui_interaction_started()
signal ui_interaction_turn
signal ui_interaction_ended()
@onready var battlemap = $battlemapUI
@onready var mapgeo = $mapgeoUI
@onready var inventory = $Panel
@onready var foodamount = $resourcesUI/foodamount
@onready var wateramount = $resourcesUI/wateramount
@onready var grid_container = $Panel/GridContainer
var buttons = []


func _ready():
	# Get all the TextureButtons in the GridContainer
	buttons = grid_container.get_children()
	# Loop through each button and connect its "pressed" signal
	for button in buttons:
		button.connect("button_down", Callable(self, "_on_texture_button_pressed").bind(button))

func _on_texture_button_pressed(button):
	# Print the button's global position
	#print("Button clicked at global position:", button.global_position)
	#button.position 
	# Identify the button index based on its position in the array
	var index = buttons.find(button)
	if index != -1:
		print("Button at index", index, "was pressed")


func _process(_delta):
	if Input.is_action_just_pressed("inventory") :
		inventory_manage()

func hide_map_ui(hideorshow):
	if hideorshow:
		mapgeo.visible = true
		battlemap.visible = false
	else:
		mapgeo.visible = false
		battlemap.visible = true

func inventory_manage():
	if inventory.visible:
		inventory.visible = false
		get_tree().paused = false  # Unpause the game when closing the inventory
	else:
		inventory.visible = true
		get_tree().paused = true   # Pause the game when opening the inventory

func _on_camp_button_down():
	
	emit_signal("camp_action")
	#print("Camp button pressed - Signal emitted")

func _on_move_button_down():
	Globals.add_food(-20)
	set_UI_resources()
	emit_signal("move_action")
	#print("Move button pressed - Signal emitted")

func set_UI_resources():
	call_deferred("_update_ui_resources")

func _update_ui_resources():
	if foodamount == null:
		print("Error: foodamount node not found!")
		return
	foodamount.text = str(Globals.food)
	wateramount.text = str(Globals.water)


func _on_button_button_down():
	get_tree().change_scene_to_file( "res://scenes/main_map.tscn" )

func _on_aim_button_down():
	
	emit_signal("aim_action")
	#print("Move button pressed - Signal emitted")

func _on_fire_button_down():
	emit_signal("fire_action")
	#print("Move button pressed - Signal emitted")

func _on_battlemap_ui_mouse_entered():
	emit_signal("ui_interaction_started") 
	#print("mouse exited the ui thing")


func _on_battlemap_ui_mouse_exited():
	emit_signal("ui_interaction_ended") 
	#print("mouse exited the ui thing")



