extends Area2D

var direction: Vector2 = Vector2.ZERO 
var speed = 260 
var pierced_through = false
func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group('zombie') && !pierced_through:
		body.take_damage(20)
		pierced_through = true
		queue_free()
	elif body.is_in_group('zombie'):
		body.take_damage(10)
		queue_free()
