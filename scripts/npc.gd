extends CharacterBody2D

var direction = Vector2.RIGHT
var is_aiming = false
var moving = false
var reloaded = true
var target_position: Vector2
const SPEED = 19.0
var forward_angle: float = 0
var target
var HEALTH = 100
@onready var gun_marker = $Musket/Marker2D 
@onready var gun = $Musket 
@export var gun_offset = Vector2(0, 0)  # Position offset for the gun (if needed)
@export var gun_radius = 20.0  # Adjust the radius as necessary
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var navigation_agent_2d = $NavigationAgent2D
@onready var targeting = $targeting

func _physics_process(delta):
	if moving:
		
		if navigation_agent_2d.is_navigation_finished() == false:
			direction = (navigation_agent_2d.get_next_path_position() - global_position).normalized()
			velocity = direction * SPEED
			sprite_frame_direction()  # Update the sprite frame based on the direction
		else:
			moving = false
			velocity = Vector2.ZERO
	else:
		if forward_angle >= 0:
			animated_sprite_2d.flip_h = false
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)
		animated_sprite_2d.stop()
	move_and_slide()
	

	if is_aiming:
		if target and is_instance_valid(target):
			var direction_to_target = (target.global_position - global_position).normalized()
			var target_angle = direction_to_target.angle()
			rotate_gun(target_angle)
		else:
			find_zombies_in_area()
	else:
		rotate_gun(forward_angle)

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
	else:
		#animated_sprite_2d.animation = "idle"
		#animated_sprite_2d.stop()
		pass
#animated_sprite_2d.frame = 0
func find_zombies_in_area():
	var bodies_in_area = targeting.get_overlapping_bodies()
	if bodies_in_area.size() == 0:
		target = null
		# Optionally, lower weapon or stop aiming
		is_aiming = false
		return

	var closest_distance = INF
	var closest_target = null

	for body in bodies_in_area:
		if body.is_in_group("zombie") and is_instance_valid(body):
			var distance_to_body = global_position.distance_to(body.global_position)
			if distance_to_body < closest_distance:
				closest_distance = distance_to_body
				closest_target = body

	target = closest_target

func move_to_position(new_target_position: Vector2):
	target_position = new_target_position
	navigation_agent_2d.target_position = target_position
	moving = true

func rotate_gun(target_angle: float):
	# Rotate the gun to the target angle
	gun.rotation = target_angle

	# Calculate the direction based on the angle
	var direction_to_target = Vector2(cos(target_angle), sin(target_angle))
	gun.position = direction_to_target * gun_radius + gun_offset

	if target_angle  > PI / 2 or target_angle  < -PI / 2:
		gun.flip_v = true
	else:
		gun.flip_v = false
	if target_angle  < 0:
		gun.z_index = 0
	else:
		gun.z_index = 1

func player_die():
	$takedamage.start()

func fire_gun():
	reloaded = false
	$Timer.start()
func _on_timer_timeout():
	reloaded = true

func _on_takedamage_timeout():
	HEALTH -= 50
	if HEALTH <= 0:
		queue_free()
		Globals.add_soldier_count(-1) 
