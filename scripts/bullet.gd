extends Area2D

var direction: Vector2 = Vector2.ZERO 
var speed = 260 

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body is CharacterBody2D:
		body.take_damage(20)
		queue_free()

func _on_timer_timeout():
	queue_free()  
