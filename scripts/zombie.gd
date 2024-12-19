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
		# Set the first body as the target
		target = bodies_in_area[0]
		#move_to_position(target.global_position)
func sprite_frame_direction():
	if direction.x < 0 and abs(direction.x) > abs(direction.y):
		animated_sprite_2d.animation = "walking"
		animated_sprite_2d.play()
		animated_sprite_2d.flip_h = true
	elif direction.x > 0 and abs(direction.x) > abs(direction.y):
		animated_sprite_2d.animation = "walking"
		animated_sprite_2d.play()
		animated_sprite_2d.flip_h = false
	elif direction.y < 0 and abs(direction.y) > abs(direction.x):
		pass
		#animated_sprite_2d.animation = "new_animation"
		#animated_sprite_2d.play()
	elif direction.y > 0 and abs(direction.y) > abs(direction.x):
		#animated_sprite_2d.animation = "another_animation"
		#animated_sprite_2d.play()
		pass
func move_to_position(new_target_position: Vector2):
	target_position = new_target_position
	navigation_agent_2d.target_position = target_position
	moving = true

func player_die():
	health -= 25
	animated_sprite_2d.frame = 3
	if health < 50:
		queue_free()

func _on_targeting_body_exited(body):
	# Reset target if the current target leaves the area
	#print(body)
	if body == target:
		target = null


func _on_melee_body_entered(body):
	if body.is_in_group("npc"):
		body.player_die()
