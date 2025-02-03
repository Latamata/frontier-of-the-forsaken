extends Node

var is_global_aiming = false

# Properties
var food: int =  100 # setget add_food, get_food
var geo_map_camp: int = 0 # setget add_geo_map_camp, get_geo_map_camp
# In a global script or main game manager:
var current_line: int = 0
var soldier_count: int = 12 # setget add_soldier_count, get_soldier_count
var wagon_speed: int = 1 # setget add_wagon_speed, get_wagon_speed

# Optional: Setter/Getter for geo_map_camp if needed
func set_current_line(value ) -> void:
	current_line = value
	print("Globals.current_line updated to:", value)

# Adders and Getters
func add_food(value: int) -> void:
	food += value
	food = max(0, food)  # Ensure no negative food

func get_food() -> int:
	return food

func add_geo_map_camp(value: int) -> void:
	geo_map_camp += value
	geo_map_camp = max(0, geo_map_camp)

func add_soldier_count(value: int) -> void:
	soldier_count += value
	soldier_count = max(0, soldier_count)

func get_soldier_count() -> int:
	return soldier_count

func add_wagon_speed(value: int) -> void:
	wagon_speed += value
	wagon_speed = max(0, wagon_speed)  # Ensure speed can't be negative

func get_wagon_speed() -> int:
	return wagon_speed
