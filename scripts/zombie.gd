extends CharacterBody2D

var direction = Vector2.RIGHT
var moving = true
var melee_cd = true
var target_position: Vector2
var HEALTH = 100
var target = null
var SPEED = 19.0  # Base speed
var time_since_last_path_update = 0.0
var path_update_interval = 0.1  # Update pathfinding every 0.1 seconds

@onready var animated_sprite_2d = $Spritesheet
@onready var navigation_agent_2d = $NavigationAgent2D
@onready var targeting = $targeting
@onready var healthbar: ProgressBar = $Healthbar
@onready var meleetimer: Timer = $Meleetimer

var overlapping_bodies = []  # List of bodies in melee range
func _ready():
	# Initialize the healthbar
	update_healthbar()

func _physics_process(delta):
	# Update the path only after the interval has passed
	time_since_last_path_update += delta

	if target and is_instance_valid(target):
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
		find_target()
	if melee_cd and overlapping_bodies.size() > 0:
		apply_melee_damage()

func find_target():
	var bodies_in_area = targeting.get_overlapping_bodies()
	
	if bodies_in_area.size() > 0:
		var closest_target = null
		var closest_distance = INF  # Start with a very large distance

		for body in bodies_in_area:
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
			animated_sprite_2d.play()
		elif direction.y > 0:
			animated_sprite_2d.play()
	else:
		animated_sprite_2d.animation = "default"
func move_to_position(new_target_position: Vector2):
	target_position = new_target_position
	navigation_agent_2d.target_position = target_position
	moving = true
func take_damage(amount: int):
	HEALTH -= amount
	HEALTH = max(HEALTH, 0)  # Ensure health doesn't drop below 0
	healthbar.value = HEALTH  # Update health bar

	if HEALTH <= 0:
		die()

func die():
	queue_free()
	Globals.add_soldier_count(-1)

func slow_affect(activate):
	if activate:
		SPEED = 15.0
	else:
		SPEED = 30.0

func _on_targeting_body_exited(body):
	# Reset target if the current target leaves the area
	if body == target:
		target = null

func update_healthbar():
	# Sync the healthbar with the current health
	healthbar.value = HEALTH

func _on_melee_body_entered(body: Node2D) -> void:
	if body.is_in_group("npc") and body not in overlapping_bodies:
		overlapping_bodies.append(body)

func _on_melee_body_exited(body: Node2D) -> void:
	if body in overlapping_bodies:
		overlapping_bodies.erase(body)

func apply_melee_damage():
	for body in overlapping_bodies:
		if is_instance_valid(body):
			body.take_damage(30)  # Adjust damage amount as needed
	melee_cd = false
	meleetimer.start()

func _on_meleetimer_timeout() -> void:
	melee_cd = true
