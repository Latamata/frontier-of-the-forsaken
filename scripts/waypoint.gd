extends Area2D

signal zombie_entered()

func _ready() -> void:
	$waypoint_timout.start()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group('zombie'):
		emit_signal("zombie_entered")
		$waypoint_timout.start()
		set_deferred("monitoring", false)

func _on_waypoint_timout_timeout() -> void:
	monitoring = true
	var zombies_found := false
	for body in get_overlapping_bodies():
		if is_instance_valid(body) and body.is_in_group("zombie"):
			zombies_found = true
			emit_signal("zombie_entered")
	
	if zombies_found:
		$waypoint_timout.start()  # Restart timer if zombies still present
	#else:
		#print("No zombies in area, timer stopped")
