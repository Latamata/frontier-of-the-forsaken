extends Area2D

#var velocity = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO 
var speed = 260 

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body is CharacterBody2D:
		body.player_die()
		queue_free()
	else:
		queue_free()

func _on_timer_timeout():
	queue_free()  
