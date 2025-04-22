extends Control

func _ready() -> void:
	update_tooltips()
	if Globals.talent_tree["gun_damage"]["level"] > 0:
		$ColorRect/Button.modulate = Color.ORANGE
func update_tooltips():
	var level = Globals.talent_tree["gun_damage"]["level"]
	var max_level = Globals.talent_tree["gun_damage"]["max_level"]
	$ColorRect/Button.tooltip_text = "Musket specialization\n%d/%d" % [level, max_level]

func _on_talent_button_pressed(talent_name: String):
	Globals.increase_talent_level(talent_name)
	update_tooltips()

func _on_button_button_down() -> void:
	$ColorRect/Button.modulate = Color.ORANGE
	_on_talent_button_pressed("gun_damage")

func _on_button_2_button_down() -> void:
	_on_talent_button_pressed("sword_damage")

func _on_button_3_button_down() -> void:
	_on_talent_button_pressed("gun_speed")

func _on_button_4_button_down() -> void:
	_on_talent_button_pressed("sword_speed")

func _on_button_5_button_down() -> void:
	_on_talent_button_pressed("talent_5")

func _on_button_6_button_down() -> void:
	_on_talent_button_pressed("talent_6")
