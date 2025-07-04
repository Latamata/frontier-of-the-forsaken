extends Control

@onready var battlemapinstruction: Control = $battlemapinstruction
@onready var campaignmapinstruction: Control = $campaignmapinstruction

func _ready() -> void:
	visibility_layer = true
func _on_button_button_down() -> void:
	hide_instruction("battle", false)
	visible = false

func _on_closecmi_button_down() -> void:
	hide_instruction("campaign", false)
	visible = false

func hide_instruction(mode: String, show_hide) -> void:
	if mode == "battle":
		battlemapinstruction.visible = show_hide
		Globals.show_battle_tut = show_hide
	elif mode == "campaign":
		campaignmapinstruction.visible = show_hide
		Globals.show_campaign_tut = show_hide
