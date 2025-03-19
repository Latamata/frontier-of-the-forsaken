extends CanvasLayer

signal fire_action
signal turn_action
signal weapon_toggle
signal aim_action
signal auto_shoot_action
signal camp_action
signal move_action
signal ui_interaction_started()

signal ui_interaction_ended()
#@onready var food: RichTextLabel = $resources/food

@onready var gold: RichTextLabel = $resources/gold
@onready var battlemap = $battlemapUI
@onready var mapgeo = $mapgeoUI
#@onready var inventory: Control = $inventory



func _ready() -> void:
	update_resources()
	#pass
	#inventory.connect("item_dropped", Callable(self, "_on_inventory_signal"))


func hide_map_ui(hideorshow):
	if hideorshow:
		mapgeo.visible = true
		battlemap.visible = false
	else:
		mapgeo.visible = false
		battlemap.visible = true
func update_resources() -> void:
	#print(Globals.food)
	
	$resources/food.text = str(Globals.food)
	$resources/gold.text = str(Globals.gold)
#-----------------GEOGRAPHIC MAP UI----------------------
func _on_camp_button_down():
	emit_signal("camp_action")
	#print("Camp button pressed - Signal emitted")

func _on_move_button_down():
	#print(Globals.food)
	$resources/food.text = str(Globals.food)
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

#func _on_inventory_button_button_down() -> void:
	#inventory.hideorshow()

func _on_button_pressed() -> void:
	emit_signal("turn_action")

func _on_auto_shoot_button_down() -> void:
	emit_signal("auto_shoot_action")

func _on_button_button_down() -> void:
	$mapgeoUI/shop.visible = !$mapgeoUI/shop.visible

func _on_shop_bought_something() -> void:
	update_resources() 
	#print('rinngs')
