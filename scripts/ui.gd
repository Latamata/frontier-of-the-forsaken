extends CanvasLayer

signal fire_action
signal aim_action
signal auto_shoot_action
signal camp_action
signal move_action
signal ui_interaction_started()

signal ui_interaction_ended()
@onready var food: RichTextLabel = $resources/food
@onready var gold: RichTextLabel = $resources/gold
@onready var battlemap = $battlemapUI
@onready var mapgeo = $mapgeoUI
@onready var current_map: RichTextLabel = $mapgeoUI/current_map
@onready var events: RichTextLabel = $mapgeoUI/Events
@onready var tuts = $instructions
var travel_mode = false
@onready var shop: Control = $shop
@onready var geomap: Button = $battlemapUI/geomap
@onready var reload_timer: ProgressBar = $battlemapUI/reloadtimer
@onready var talents: Control = $battlemapUI/talents


func _ready() -> void:
	update_resources()
	$instructions.visible = false
	#_on_aim_button_down()
	#_on_auto_shoot_button_down()
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
	food.text = str(Globals.food)
	gold.text = str(Globals.gold)
	$resources/infanty_amount.text = str(Globals.soldier_count) + '/' + str(Globals.soldier_total)

#-----------------GEOGRAPHIC MAP UI----------------------
func hide_show_camp_button(hideorshow):
	geomap.visible = hideorshow

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

func _on_battlemap_ui_mouse_exited():
	emit_signal("ui_interaction_ended") 

func _on_geomap_button_down() -> void:
	hide_show_camp_button(false)
	if travel_mode:
		$battlemapUI/campaign_map_timer.start()
		$battlemapUI/RichTextLabel.visible = true


func _on_auto_shoot_button_down() -> void:
	emit_signal("auto_shoot_action")

func _on_shop_bought_something() -> void:
	update_resources() 

func update_wave(wave_number):
	$battlemapUI/wave.text = "Wave: " + str(wave_number)

func _on_campaign_map_timer_timeout() -> void:
	get_tree().change_scene_to_file( "res://scenes/main_map.tscn" )

func update_xp_talents() -> void:
	talents.update_level_display() 

func _on_talents_button_down() -> void:
	#print('running')
	if talents.visible:
		talents.visible = false
	else:
		talents.visible = true

func turn_screen_red():
	$red_died_screen.visible = true

func hide_or_show_wavecomplete(show_it):
	if show_it:
		$battlemapUI/wavecomplete.visible = true
	else:
		$battlemapUI/wavecomplete.visible = false

func _on_shop_button_button_down() -> void:
	shop.hide_or_show(true) 

func set_reload(value: float, max_reload: float) -> void:
	reload_timer.value = value
	reload_timer.max_value = max_reload # Start with remaining time

func _on_player_ui_mouse_entered() -> void:
	emit_signal("ui_interaction_started") 

func _on_player_ui_mouse_exited() -> void:
	emit_signal("ui_interaction_ended") 

func _on_instructions_mouse_entered() -> void:
	emit_signal("ui_interaction_started") 

func _on_instructions_mouse_exited() -> void:
	emit_signal("ui_interaction_ended") 


func _on_talents_mouse_entered() -> void:
	#print('runinng'
	emit_signal("ui_interaction_started") 


func _on_talents_mouse_exited() -> void:
	emit_signal("ui_interaction_ended") 
