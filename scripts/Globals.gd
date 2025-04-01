extends Node

var is_global_aiming = false
signal collect_item()  # Define signal with a parameter

# Properties
var food: int =  120 # setget add_food, get_food
var gold: int =  500 # setget add_food, get_food
var geo_map_camp: int = 0 # setget add_geo_map_camp, get_geo_map_camp
# In a global script or main game manager:
var wave_count = 1
var current_line: int = 0
var soldier_count: int = 10 # setget add_soldier_count, get_soldier_count
var bullet_type = "lead"
var bullets_unlocked = ['lead']
# Optional: Setter/Getter for geo_map_camp if needed
func set_current_line(value ) -> void:
	current_line = value
	#print("Globals.current_line updated to:", value)

# Adders and Getters
func add_food(value: int) -> void:
	food += value
	food = max(0, food)  # Ensure no negative food
	emit_signal("collect_item")  # Pass the collected item as an argument

func add_gold(value: int) -> void:
	gold += value
	gold = max(0, gold)  # Ensure no negative food
	emit_signal("collect_item")  # Pass the collected item as an argument

func add_geo_map_camp(value: int) -> void:
	geo_map_camp += value
	geo_map_camp = max(0, geo_map_camp)

func add_soldier_count(value: int) -> void:
	soldier_count += value
	soldier_count = max(0, soldier_count)

func get_soldier_count() -> int:
	return soldier_count
