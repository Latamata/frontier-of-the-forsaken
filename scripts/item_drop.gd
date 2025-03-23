extends Area2D

var resource_type = ''
var resource_types = ["food", "gold", "health"]
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

#getting file changed ouside editor message for this file
func _ready() -> void:
	get_random_resource()
	if resource_type == "gold":
		$AnimatedSprite2D.animation = "gold"  # Set the animation but don't play it automatically
		$AnimatedSprite2D.play() # Set the animation but don't play it automatically
	elif resource_type == "health":
		$AnimatedSprite2D.animation = "health"  # Set the animation but don't play it automatically
		$AnimatedSprite2D.play() # Set the animation but don't play it automatically
	elif resource_type == "food":
			$AnimatedSprite2D.animation = "food"  # Set the animation but don't play it automatically
			$AnimatedSprite2D.play() # Set the animation but don't play it automatically

func collected():
	queue_free()
	if resource_type == 'gold':
		Globals.add_gold(20)
	elif resource_type == 'food':
		Globals.add_food(20)
	else:
		print('add health to player')
func get_random_resource():
	print("hiii")
	var chosen_type = resource_types[randi() % resource_types.size()]
	resource_type = chosen_type
