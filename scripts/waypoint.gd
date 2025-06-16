extends Area2D

# Signal to notify parent or controller that a zombie entered this waypoint
signal zombie_entered()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group('zombie'):
		print('zombie crossed point')
		emit_signal("zombie_entered")
		$waypoint_timout.start()
		set_deferred("monitoring", false)

func _on_waypoint_timout_timeout() -> void:
	monitoring = true
