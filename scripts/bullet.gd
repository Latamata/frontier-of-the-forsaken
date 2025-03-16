extends Area2D

var direction: Vector2 = Vector2.ZERO 
var speed = 260 
var pierced_through = false
func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if Globals.bullet_type == 'steel':
		if body.is_in_group('zombie') && !pierced_through:
			body.take_damage(20)
			pierced_through = true
		elif body.is_in_group('zombie'):
			print('running')
			body.take_damage(10)
			queue_free()
	else:
		if body.is_in_group('zombie'):
			body.take_damage(20)
			queue_free()
