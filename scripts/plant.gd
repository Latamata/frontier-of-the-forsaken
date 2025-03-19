extends Area2D

var resource_type = ''

func collected():
	queue_free()
	if resource_type == 'gold':
		Globals.add_gold(20)
	else:
		Globals.add_food(20)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		collected()
