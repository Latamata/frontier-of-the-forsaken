extends CanvasLayer

signal fire_action
signal turn_action
signal weapon_toggle
signal aim_action
signal camp_action
signal move_action
signal ui_interaction_started()
signal ui_interaction_turn
signal ui_interaction_ended()
signal inventory_item_dropped(item)  # <-- New signal
@onready var food: RichTextLabel = $mapgeoUI/food
@onready var battlemap = $battlemapUI
@onready var mapgeo = $mapgeoUI
@onready var inventory: Control = $inventory



func _ready() -> void:
	update_resources()
	inventory.connect("item_dropped", Callable(self, "_on_inventory_signal"))

func _on_inventory_item_dropped(item):
	print("Inventory item dropped signal received in UI!")
	emit_signal("inventory_item_dropped", item)  # <-- Re-emitting the signal

func hide_map_ui(hideorshow):
	if hideorshow:
		mapgeo.visible = true
		battlemap.visible = false
	else:
		mapgeo.visible = false
		battlemap.visible = true
func update_resources() -> void:
	food.text = str(Globals.food)

#-----------------GEOGRAPHIC MAP UI----------------------
func _on_camp_button_down():
	emit_signal("camp_action")
	#print("Camp button pressed - Signal emitted")

func _on_move_button_down():
	#print(Globals.food)
	food.text = str(Globals.food)
	emit_signal("move_action")

#-----------------BATTLE MAP UI----------------------
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

func _on_geomap_button_down() -> void:
	get_tree().change_scene_to_file( "res://scenes/main_map.tscn" )

func _on_weapontoggle_button_down() -> void:
	emit_signal("weapon_toggle") 

func _on_inventory_button_button_down() -> void:
	inventory.hideorshow()


func _on_button_pressed() -> void:
	emit_signal("turn_action")
