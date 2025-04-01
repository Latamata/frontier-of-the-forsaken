extends Node2D

@onready var pickupindicator: Label = $pickupindicator
var player: Node2D = null  # Store the player reference

func _ready():
	set_process(false)	  # Disable _process by default

func _process(delta: float) -> void:
	if player.looting:  # Check input when player is inside
		collected()

func _on_area_2d_body_entered(body: Node2D) -> void:
	pickupindicator.visible = true
	player = body  # Store player reference
	set_process(true)  # Enable _process to check for input

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:  # Only disable if the exiting body is the stored player
		pickupindicator.visible = false
		player = null  # Clear player reference
		set_process(false)  # Disable _process when the player leaves



func collected():
	Globals.add_food(100)
	print("Player looted this treasure")
	queue_free()  # Optional: Remove the object after collecting
