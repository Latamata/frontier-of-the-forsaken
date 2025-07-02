extends Node


signal collect_item()  # Define signal with a parameter
signal sword_spec_dmgrdc()  # Define signal with a parameter
signal level_up

var is_global_aiming = false
var experience: int = 0
var level: int = 1
var xp_to_next: int = 100
var master_volume: float = 0.0  # dB value, not linear

# Properties
var skill_points: int =  0 # setget add_food, get_food
var food: int =  2000 # setget add_food, get_food
var gold: int =  200 # setget add_food, get_food
var geo_map_camp: int = 0 # setget add_geo_map_camp, get_geo_map_camp
# In a global script or main game manager:
var wave_count = 0
var current_line: int = 0
var soldier_count: int = 0 # setget add_soldier_count, get_soldier_count
var soldier_total: int = 12 # setget add_soldier_count, get_soldier_count
var bullet_type = "lead"
var time_of_day = ""
var current_biome  = ""
var current_event  = ""
var bullets_unlocked = ['lead']
var double_resources = false
var golden_musket = false
var golden_sword = false

var show_campaign_tut = true
var show_battle_tut = true
# Globals.gd
var talent_tree = {
	"gun_damage": {
		"level": 0,
		"max_level": 5
	},
	"sword_damage": {
		"level": 0,
		"max_level": 5
	},
	"gun_speed": {
		"level": 0,
		"max_level": 3
	},
	"sword_speed": {
		"level": 0,
		"max_level": 3
	},
	"sword_spec_damage_reduce": {
		"level": 0,
		"max_level": 1
	},
	"gun_spec_standing_speed": {
		"level": 0,
		"max_level": 1	
	}
}

func increase_talent_level(talent_name: String) -> void:
	if skill_points <= 0:
		print("Not enough skill points.")
		return

	# Tier restrictions
	match talent_name:
		"gun_speed":
			if talent_tree["gun_damage"]["level"] < talent_tree["gun_damage"]["max_level"]:
				print("Gun speed is locked. Max gun damage first.")
				return
		"gun_spec_standing_speed":
			if talent_tree["gun_speed"]["level"] < talent_tree["gun_speed"]["max_level"]:
				print("Gun spec is locked. Max gun speed first.")
				return
		"sword_speed":
			if talent_tree["sword_damage"]["level"] < talent_tree["sword_damage"]["max_level"]:
				print("Sword speed is locked. Max sword damage first.")
				return
		"sword_spec_damage_reduce":
			if talent_tree["sword_speed"]["level"] < talent_tree["sword_speed"]["max_level"]:
				print("Sword spec is locked. Max sword speed first.")
				
				return

	if talent_tree.has(talent_name):
		var talent = talent_tree[talent_name]
		if talent["level"] < talent["max_level"]:
			talent["level"] += 1
			skill_points -= 1
			talent_tree[talent_name] = talent
			print("%s increased to level %d" % [talent_name, talent["level"]])
			
			# ✅ Emit only if it's the sword spec
			if talent_name == "sword_spec_damage_reduce" and talent["level"] > 0:
				emit_signal("sword_spec_dmgrdc")

func add_experience(amount: int) -> void:
	experience += amount
	while experience >= xp_to_next:
		experience -= xp_to_next
		level += 1
		skill_points += 1
		xp_to_next = int(xp_to_next * 1.2) # Scale as needed
		print("Level up! Now level %d" % level)
		emit_signal("level_up")

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

func add_soldier_count(value: int) -> void:
	soldier_count += value
	soldier_count = max(0, soldier_count)
	emit_signal("collect_item")

func add_geo_map_camp(value: int) -> void:
	geo_map_camp += value
	geo_map_camp = max(0, geo_map_camp)

func get_soldier_count() -> int:
	return soldier_count
