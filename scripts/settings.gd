extends CanvasLayer

signal settings_closed

@onready var sound_setting: HScrollBar = $ColorRect/sound_setting
@onready var sound_label: RichTextLabel = $ColorRect/sound_label


func _ready():
	sound_setting.value = Globals.master_volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(Globals.master_volume))
	sound_label.text = "Volume: " + str(round(Globals.master_volume * 100)) + "%"

func _on_sound_setting_value_changed(value: float) -> void:
	Globals.master_volume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	sound_label.text = "Volume: " + str(round(value * 100)) + "%"

func _on_button_button_down() -> void:
	emit_signal("settings_closed")
	visible = false  # Or queue_free() if you're removing it
