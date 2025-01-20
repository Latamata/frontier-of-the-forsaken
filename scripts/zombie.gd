extends CharacterBody2D

# Variables
var direction = Vector2.RIGHT
var moving = true
var melee_cd = true
var target_position: Vector2
var HEALTH = 100
var target = null
var SPEED = 19.0  # Base speed
var time_since_last_path_update = 0.0
var path_update_interval = 0.1  # Pathfinding update interval

# Nodes
@onready var animated_sprite_2d = $Spritesheet
@onready var navigation_agent_2d = $NavigationAgent2D
@onready var targeting = $targeting
@onready var healthbar: ProgressBar = $Healthbar
@onready var meleetimer: Timer = $Meleetimer

# Lists
var overlapping_bodies = []  # Bodies in melee range

func _ready():
	update_healthbar()

func _physics_process(delta):
	time_since_last_path_update += delta

	if target and is_instance_valid(target):
		#print(target)
		if time_since_last_path_update > path_update_interval:
			navigation_agent_2d.target_position = target.global_position
			time_since_last_path_update = 0.0  # Reset timer
			sprite_frame_direction()

		# Move toward the target if navigation is not finished
		if not navigation_agent_2d.is_navigation_finished():
			direction = (navigation_agent_2d.get_next_path_position() - global_position).normalized()
			velocity = direction * SPEED
			move_and_slide()
		else:
			moving = false
			velocity = Vector2.ZERO
	else:
		animated_sprite_2d.animation = "default"
		find_target()

	# Handle melee
	if melee_cd and overlapping_bodies.size() > 0:
		apply_melee_damage()

func find_target():
	var bodies_in_area = targeting.get_overlapping_bodies()

	if bodies_in_area.size() > 0:
		var closest_target = null
		var closest_distance = INF  # Large initial distance

		for body in bodies_in_area:
			# Ensure the body is a valid target (e.g., has health or belongs to a specific group)
			if body.is_in_group("npc") or body.name == "player":  # Adjust as needed
				var distance = global_position.distance_to(body.global_position)
				if distance < closest_distance:
					closest_target = body
					closest_distance = distance

		target = closest_target

func sprite_frame_direction():
	if abs(direction.x) > abs(direction.y):  # Horizontal movement
		animated_sprite_2d.animation = "walking"
		animated_sprite_2d.flip_h = direction.x < 0  # Flip horizontally
	elif abs(direction.y) > abs(direction.x):  # Vertical movement
		animated_sprite_2d.animation = "walking_away" if direction.y < 0 else "walking_toward"
	animated_sprite_2d.play()

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
	SPEED = 15.0 if activate else 30.0

func _on_targeting_body_exited(body):
	if body == target:
		target = null
		navigation_agent_2d.target_position = global_position  # Stop navigation by resetting target position
		# Optionally set a temporary target to "clear" the path
		navigation_agent_2d.target_position = Vector2.ZERO  # Resetting path target to origin (or any neutral position)

	# Handle overlapping bodies
	if body.is_in_group("npc") or body in overlapping_bodies:
		overlapping_bodies.erase(body)
	if body.name == "player":
		overlapping_bodies.erase(body)


func update_healthbar():
	healthbar.value = HEALTH  # Sync healthbar with current health

func _on_melee_body_entered(body: Node2D) -> void:
	if body.is_in_group("npc") and body not in overlapping_bodies:
		overlapping_bodies.append(body)
	if body.name == 'player':
		overlapping_bodies.append(body)

func apply_melee_damage():
	for body in overlapping_bodies:
		if is_instance_valid(body):
			body.take_damage(30)  # Adjust damage amount as needed
	melee_cd = false
	meleetimer.start()

func _on_meleetimer_timeout() -> void:
	melee_cd = true
