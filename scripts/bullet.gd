extends Area2D

var direction: Vector2 = Vector2.ZERO 
var speed = 260 

var smoke: PackedScene = preload("res://scenes/smoke.tscn")
func _ready() -> void:
	#_spawn_smoke()
	pass
func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group('zombie'):
		body.take_damage(20)
		queue_free()



func _spawn_smoke():
	var smoke_instance = smoke.instantiate()
	smoke_instance.position = position  
	smoke_instance.direction = direction.normalized()  # Ensure movement is normalized
	smoke_instance.emitting = true
	get_parent().add_child(smoke_instance)
