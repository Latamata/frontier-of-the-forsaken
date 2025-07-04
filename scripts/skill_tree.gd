extends ColorRect

@onready var level_experience: RichTextLabel = $level_experience
@onready var gun_damage_level: RichTextLabel = $gun_damage_level
@onready var sword_damage_level: RichTextLabel = $sword_damage_level
@onready var gun_speed_level: RichTextLabel = $gun_speed_level
@onready var sword_speed_level: RichTextLabel = $sword_speed_level
@onready var sword_specialty_skill: RichTextLabel = $sword_specialty_skill
@onready var gun_specialty_skill: RichTextLabel = $gun_specialty_skill

# Map buttons to their talent names
@onready var talent_buttons := {
	"gun_damage": $Button,
	"sword_damage": $Button2,
	"gun_speed": $Button3,
	"sword_speed": $Button4,
	"gun_spec_standing_speed": $Button5,
	"sword_spec_damage_reduce": $Button6,
}

func _ready() -> void:
	update_tooltips()
	update_all_button_colors()
	update_level_display()  # <-- Add this


func update_tooltips():
	var level
	var max_level
	gun_damage_level.text = str(Globals.talent_tree["gun_damage"]["level"])
	gun_speed_level.text = str(Globals.talent_tree["gun_speed"]["level"])
	gun_specialty_skill.text = str(Globals.talent_tree["gun_spec_standing_speed"]["level"])
	sword_damage_level.text = str(Globals.talent_tree["sword_damage"]["level"])
	sword_speed_level.text = str(Globals.talent_tree["sword_speed"]["level"])
	sword_specialty_skill.text = str(Globals.talent_tree["sword_spec_damage_reduce"]["level"])
	level = Globals.talent_tree["gun_spec_standing_speed"]["level"]
	max_level = Globals.talent_tree["gun_spec_standing_speed"]["max_level"]
	talent_buttons["gun_spec_standing_speed"].tooltip_text = "Run and reload\n%d/%d" % [level, max_level]
	
	level = Globals.talent_tree["sword_spec_damage_reduce"]["level"]
	max_level = Globals.talent_tree["sword_spec_damage_reduce"]["max_level"]
	talent_buttons["sword_spec_damage_reduce"].tooltip_text = "Sword block 50 damage\n%d/%d" % [level, max_level]

	level = Globals.talent_tree["gun_damage"]["level"]
	max_level = Globals.talent_tree["gun_damage"]["max_level"]
	talent_buttons["gun_damage"].tooltip_text = "Musket Damage\n%d/%d" % [level, max_level]

	level = Globals.talent_tree["sword_damage"]["level"]
	max_level = Globals.talent_tree["sword_damage"]["max_level"]
	talent_buttons["sword_damage"].tooltip_text = "Sword Damage\n%d/%d" % [level, max_level]
	
	level = Globals.talent_tree["gun_speed"]["level"]
	max_level = Globals.talent_tree["gun_speed"]["max_level"]
	talent_buttons["gun_speed"].tooltip_text = "Musket reload\n%d/%d" % [level, max_level]

	level = Globals.talent_tree["sword_speed"]["level"]
	max_level = Globals.talent_tree["sword_speed"]["max_level"]
	talent_buttons["sword_speed"].tooltip_text = "Sword speed\n%d/%d" % [level, max_level]


func update_all_button_colors():
	for talent_name in talent_buttons.keys():
		var button = talent_buttons[talent_name]
		var level = Globals.talent_tree[talent_name]["level"]
		if level > 0:
			button.modulate = Color.ORANGE
		else:
			button.modulate = Color.WHITE

func _on_talent_button_pressed(talent_name: String):
	if Globals.skill_points > 0:
		Globals.increase_talent_level(talent_name)
		update_tooltips()
		update_all_button_colors()
	else:
		print("No skill points available!")
	update_level_display()

func update_level_display():
	level_experience.text = "Level %d\nXP: %d / %d\nSkill Points: %d" % [
		Globals.level,
		Globals.experience,
		Globals.xp_to_next,
		Globals.skill_points
	]


func _on_button_button_down() -> void:
	_on_talent_button_pressed("gun_damage")
	
func _on_button_2_button_down() -> void:
	_on_talent_button_pressed("sword_damage")

func _on_button_3_button_down() -> void:
	_on_talent_button_pressed("gun_speed")

func _on_button_4_button_down() -> void:
	_on_talent_button_pressed("sword_speed")

func _on_button_5_button_down() -> void:
	_on_talent_button_pressed("gun_spec_standing_speed")

func _on_button_6_button_down() -> void:
	_on_talent_button_pressed("sword_spec_damage_reduce")


func _on_exit_button_down() -> void:
	#print('runing') 
	visible = false
