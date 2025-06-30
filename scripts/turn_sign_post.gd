extends Node2D

@onready var turn_left: Button = $turn_left
@onready var turn_right: Button = $turn_right

signal direction_chosen(direction: String)

func _on_turn_right_button_down() -> void:
	emit_signal("direction_chosen", "right")
	turn_right.visible = false
	turn_left.visible = true

func _on_turn_left_button_down() -> void:
	emit_signal("direction_chosen", "left")
	turn_left.visible = false
	turn_right.visible = true

func deactivate_sign(_choice):
	#turn_left.disabled = _choice
	self.visible = _choice
