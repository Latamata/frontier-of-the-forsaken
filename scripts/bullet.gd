extends Area2D

var direction: Vector2 = Vector2.ZERO 
var speed = 260 
var pierced_through = false
func _ready() -> void:
	if Globals.bullet_type == 'lead':
		$Sprite2D.region_rect = Rect2(310, 43, 99, 78)  # Example dimensions
	elif Globals.bullet_type == 'steel':
		$Sprite2D.region_rect = Rect2(23, 161, 89, 74)  # Example dimensionsel
	elif Globals.bullet_type == 'holy_bullet':
		$Sprite2D.region_rect = Rect2(168, 160, 89, 74)  # Example dimensions
func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	
	if Globals.bullet_type == 'holy_bullet':
		if body.is_in_group('zombie'):
			body.take_damage(25)
	elif Globals.bullet_type == 'steel':
		if body.is_in_group('zombie') && !pierced_through:
			body.take_damage(20)
			pierced_through = true
		elif body.is_in_group('zombie'):
			body.take_damage(10)
			queue_free()
	else: #the last bullet type 'LEAD'
		if body.is_in_group('zombie'):
			body.take_damage(20)
			queue_free()


func _on_timer_timeout() -> void:
	queue_free()
