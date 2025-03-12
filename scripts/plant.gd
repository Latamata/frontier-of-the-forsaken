extends Area2D


@onready var pickup_indicator:  = $ColorRect
var player: Node2D = null  # Store reference to the player
var player_nearby: bool = false  # Flag to track if player is nearby
var resource_type = ''
func collected():
	queue_free()
	if resource_type == 'gold':
		Globals.add_gold(20)
	else:
		Globals.add_food(20)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		pickup_indicator.visible = true
		player = body
		player_nearby = true  # Set the flag when the player enters the area

func _on_body_exited(body: Node2D) -> void:
	if body.name == "player":
		pickup_indicator.visible = false
		player = null
		player_nearby = false  # Reset the flag when the player exits

func try_collect():
	# Triggered when the player presses "E" and is nearby
	if player_nearby:
		print("Collecting plant!")
		collected()
