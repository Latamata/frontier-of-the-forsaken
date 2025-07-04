extends CanvasLayer

@onready var load_button: Button = $menu_items/load
@onready var save_button: Button = $menu_items/save
const SAVE_PATH = "user://savegame.json"
signal show_tutorial_requested

func _ready() -> void:
	save_button.connect("pressed", _on_save_pressed)
	load_button.connect("pressed", _on_load_pressed)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		visible = !visible
		get_tree().paused = visible

func _on_save_pressed() -> void:
	var save_data = {
		"geo_map_camp": Globals.geo_map_camp,
		"food": Globals.food,
		"gold": Globals.gold,
		"current_line": Globals.current_line,
		"soldier_count": Globals.soldier_count,
		"bullets_unlocked": Globals.bullets_unlocked,
		"golden_musket": Globals.golden_musket,
		"golden_sword": Globals.golden_sword,
		"bullet_type": Globals.bullet_type,
		"talent_tree": Globals.talent_tree,
		"experience": Globals.experience,        # ✅ XP Save
		"wave_count": Globals.wave_count,                  # ✅ Level Save
		"level": Globals.level,                  # ✅ Level Save
		"xp_to_next": Globals.xp_to_next,      # ✅ XP-to-next Save
		"current_time": Globals.time_of_day,
		"double_resources": Globals.double_resources,
		"current_event": Globals.current_event
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("Game Saved!")

func _on_load_pressed() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found.")
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()

		var save_data = JSON.parse_string(content)
		if save_data is Dictionary:
			Globals.geo_map_camp = save_data.get("geo_map_camp", Globals.geo_map_camp)
			Globals.food = save_data.get("food", Globals.food)
			Globals.gold = save_data.get("gold", Globals.gold)
			Globals.current_line = save_data.get("current_line", Globals.current_line)
			Globals.soldier_count = save_data.get("soldier_count", Globals.soldier_count)
			Globals.bullet_type = save_data.get("bullet_type", Globals.bullet_type)
			Globals.bullets_unlocked = save_data.get("bullets_unlocked", Globals.bullets_unlocked)
			Globals.golden_musket = save_data.get("golden_musket", Globals.golden_musket)
			Globals.golden_sword = save_data.get("golden_sword", Globals.golden_sword)
			# Force all talent levels and max_levels to be integers
			Globals.talent_tree = save_data.get("talent_tree", Globals.talent_tree)
			for talent_key in Globals.talent_tree.keys():
				var talent = Globals.talent_tree[talent_key]
				talent["level"] = int(talent.get("level", 0))
				talent["max_level"] = int(talent.get("max_level", 1))
			Globals.experience = save_data.get("experience", Globals.experience)      # ✅ XP Load
			Globals.wave_count = int(save_data.get("wave_count", Globals.wave_count))    # ✅ Level Load
			Globals.level = save_data.get("level", Globals.level)                    # ✅ Level Load
			Globals.xp_to_next = save_data.get("xp_to_next", Globals.xp_to_next)    # ✅ XP-to-next Load
			Globals.time_of_day = save_data.get("current_time", Globals.time_of_day)
			Globals.current_event = save_data.get("current_event", Globals.current_event)
			Globals.double_resources = save_data.get("double_resources", Globals.double_resources)
			print("Game Loaded!")
			get_tree().change_scene_to_file("res://scenes/main_map.tscn")

func _on_exit_button_down() -> void:
	get_tree().quit()

func _on_settings_button_button_down() -> void:
	$settings.visible = true
	$menu_items.visible = false

func _on_settings_settings_closed() -> void:
	$settings.visible = false
	$menu_items.visible = true

func _on_helpinstructions_button_down() -> void:
	emit_signal("show_tutorial_requested")

func _on_restart_button_down() -> void:
	get_tree().paused = false  # Unpause the game
	get_tree().reload_current_scene()
