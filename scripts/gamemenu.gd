extends CanvasLayer

@onready var load_button: Button = $load
@onready var save_button: Button = $save
const SAVE_PATH = "user://savegame.json"

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
		"bullet_type": Globals.bullet_type,
		"talent_tree": Globals.talent_tree,
		"experience": Globals.experience,        # ✅ XP Save
		"level": Globals.level,                  # ✅ Level Save
		"xp_to_next": Globals.xp_to_next         # ✅ XP-to-next Save
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
			Globals.talent_tree = save_data.get("talent_tree", Globals.talent_tree)
			Globals.experience = save_data.get("experience", Globals.experience)      # ✅ XP Load
			Globals.level = save_data.get("level", Globals.level)                    # ✅ Level Load
			Globals.xp_to_next = save_data.get("xp_to_next", Globals.xp_to_next)    # ✅ XP-to-next Load

			print("Game Loaded!")
			get_tree().change_scene_to_file("res://scenes/main_map.tscn")

func _on_exit_button_down() -> void:
	get_tree().quit()
