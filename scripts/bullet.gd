extends Area2D

var direction: Vector2 = Vector2.ZERO 
var speed = 260 

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group('zombie'):
		body.take_damage(20)
		queue_free()
