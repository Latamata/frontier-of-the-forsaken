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
@onready var current_map: RichTextLabel = $mapgeoUI/current_map
@onready var events: RichTextLabel = $mapgeoUI/Events

func _ready() -> void:
	update_resources()

func _process(_delta: float) -> void:
	$battlemapUI/RichTextLabel.text = str(int($battlemapUI/campaign_map_timer.time_left))

func update_currentmap_UI(map):
	current_map.text = map
func update_event_UI(event):
	events.text = 'Events: ' + event
func hide_map_ui(hideorshow):
	if hideorshow:
		mapgeo.visible = true
		battlemap.visible = false
	else:
		mapgeo.visible = false
		battlemap.visible = true

func update_resources() -> void:
	$resources/food.text = str(Globals.food)
	$resources/gold.text = str(Globals.gold)
	$resources/infanty_amount.text = str(Globals.soldier_count) + '/' + str(Globals.soldier_total)

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

var can_fire = true
var fire_cooldown = 0.5  # cooldown duration in seconds

func _on_fire_button_down():
	if not can_fire:
		return  # ignore button press if still cooling down

	can_fire = false
	emit_signal("fire_action")
	# start cooldown timer to reset can_fire
	get_tree().create_timer(fire_cooldown).connect("timeout", Callable(self, "_reset_fire_cooldown"))

func _reset_fire_cooldown():
	can_fire = true


func _on_battlemap_ui_mouse_entered():
	emit_signal("ui_interaction_started") 
	#print("mouse exited the ui thing")

func _on_battlemap_ui_mouse_exited():
	emit_signal("ui_interaction_ended") 
	#print("mouse exited the ui thing")

func _on_geomap_button_down() -> void:
	$battlemapUI/campaign_map_timer.start()
	$battlemapUI/RichTextLabel.visible = true

func _on_weapontoggle_button_down() -> void:
	emit_signal("weapon_toggle") 

func _on_button_pressed() -> void:
	emit_signal("turn_action")

func _on_auto_shoot_button_down() -> void:
	emit_signal("auto_shoot_action")

func _on_button_button_down() -> void:
	$mapgeoUI/shop.visible = !$mapgeoUI/shop.visible

func _on_shop_bought_something() -> void:
	update_resources() 
	#print('rinngs')
func update_wave(wave_number):
	$battlemapUI/wave.text = "Wave: " + str(wave_number)

func _on_campaign_map_timer_timeout() -> void:
	get_tree().change_scene_to_file( "res://scenes/main_map.tscn" )

func update_xp_talents() -> void:
	$battlemapUI/talents.update_level_display() 
func _on_talents_button_down() -> void:
	if $battlemapUI/talents.visible:
		$battlemapUI/talents.visible = false
	else:
		$battlemapUI/talents.visible = true
	#$talents.visible = !$talents.visible

func turn_screen_red():
	$red_died_screen.visible = true
