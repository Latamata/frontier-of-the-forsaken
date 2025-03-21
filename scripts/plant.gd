extends Area2D

var resource_type = 'food'
#getting file changed ouside editor message for this file
func collected():
	queue_free()
	if resource_type == 'gold':
		Globals.add_gold(20)
	else:
		Globals.add_food(20)
