extends Control

signal settings_closed

@onready var sound_setting: HScrollBar = $ColorRect/sound_setting
@onready var sound_label: RichTextLabel = $ColorRect/sound_label


func _on_sound_setting_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)
	sound_label.text = "Volume: " + str(value)

func _on_button_button_down() -> void:
	emit_signal("settings_closed")
	visible = false  # Or queue_free() if you're removing it
