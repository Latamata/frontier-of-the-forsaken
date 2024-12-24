extends CharacterBody2D

var direction = Vector2.RIGHT
var moving = true
var target_position: Vector2
var health = 100
var target = null
var SPEED = 9.0  # Base speed
var time_since_last_path_update = 0.0
var path_update_interval = 0.1  # Update pathfinding every 0.1 seconds

@onready var animated_sprite_2d = $Spritesheet
@onready var navigation_agent_2d = $NavigationAgent2D
@onready var targeting = $targeting

func _physics_process(delta):
	# Update the path only after the interval has passed
	time_since_last_path_update += delta

	if target && is_instance_valid(target):
		if time_since_last_path_update > path_update_interval:
			navigation_agent_2d.target_position = target.global_position
			time_since_last_path_update = 0.0  # Reset the timer
			sprite_frame_direction() 
		# Move toward the target if navigation is not finished
		if not navigation_agent_2d.is_navigation_finished():
			direction = (navigation_agent_2d.get_next_path_position() - global_position).normalized()
			velocity = direction * SPEED
			move_and_collide(velocity * delta)
		else:
			moving = false
			velocity = Vector2.ZERO  # Stop movement when reaching the target

	else:
	# Look for a new target
		find_target()

func find_target():
	var bodies_in_area = targeting.get_overlapping_bodies()
	
	if bodies_in_area.size() > 0:
		#print(bodies_in_area[0].name)
		var closest_target = null
		var closest_distance = INF  # Start with a very large distance

		for body in bodies_in_area:
			# Only target bodies that are in the "zombie" group
			if body.is_in_group("npc") or body.name == 'player':
				var distance = global_position.distance_to(body.global_position)
				if distance < closest_distance:
					closest_target = body
					closest_distance = distance

		# Set the closest valid target
		target = closest_target


func sprite_frame_direction():
	if abs(direction.x) > abs(direction.y):  # Prioritize horizontal movement
		animated_sprite_2d.animation = "walking"
		animated_sprite_2d.play()
		animated_sprite_2d.flip_h = direction.x < 0
	elif abs(direction.y) > abs(direction.x):  # Vertical movement
		if direction.y < 0:
			#animated_sprite_2d.animation = "up_walk"
			animated_sprite_2d.play()
		elif direction.y > 0:
			#animated_sprite_2d.animation = "down_walk"
			animated_sprite_2d.play()

func move_to_position(new_target_position: Vector2):
	target_position = new_target_position
	navigation_agent_2d.target_position = target_position
	moving = true

func player_die():
	health -= 25
	animated_sprite_2d.frame = 3  # Assuming frame 3 is the "damaged" animation frame
	if health <= 0:
		#animated_sprite_2d.animation = "die"
		#animated_sprite_2d.play()
		# Optionally: Add a delay before freeing the zombie
		queue_free()



func _on_targeting_body_exited(body):
	# Reset target if the current target leaves the area
	#print(body)
	if body == target:
		target = null


func _on_melee_body_entered(body):
	if body.is_in_group("npc"):
		body.player_die()
