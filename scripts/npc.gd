extends CharacterBody2D

var direction = Vector2.RIGHT
var melee_cd = true
var is_aiming = false
var moving = false
var reloaded = true
var target_position: Vector2
var SPEED = 19.0
var forward_angle: float = 0
var target
var HEALTH = 100  # NPC's starting health
@export var MAX_HEALTH = 100  # Maximum health of the NPC for scaling
@onready var gun_marker = $Musket/Marker2D
@onready var gun = $Musket
@export var gun_offset = Vector2(0, -25)
@export var gun_radius = 20.0
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var navigation_agent_2d = $NavigationAgent2D
@onready var targeting = $targeting
@onready var healthbar: ProgressBar = $Healthbar
@onready var meleetimer: Timer = $Meleetimer

var overlapping_bodies = []  # List of bodies in melee range

func _ready():
	# Initialize health bar values
	healthbar.min_value = 0
	healthbar.max_value = MAX_HEALTH
	healthbar.value = HEALTH

func _physics_process(delta):
	if moving:
		if not navigation_agent_2d.is_navigation_finished():
			direction = (navigation_agent_2d.get_next_path_position() - global_position).normalized()
			velocity = direction * SPEED * delta  # Multiply by delta for move_and_collide
			sprite_frame_direction()
		else:
			print('running')
			moving = false
			velocity = Vector2.ZERO
	else:
		var forward_direction = Vector2(cos(forward_angle), sin(forward_angle)).normalized()
		direction = forward_direction
		velocity = forward_direction * (SPEED * delta)  # Adjust the multiplier to control the "step" size
		sprite_frame_direction()

		# Gradually reduce velocity to simulate stopping
		velocity = velocity.move_toward(Vector2.ZERO, SPEED * delta)
		if velocity.length() < 0.01:  # Threshold to ensure clean stop
			velocity = Vector2.ZERO
			animated_sprite_2d.stop()

	move_and_collide(velocity)



	if is_aiming:
		if target and is_instance_valid(target):
			var direction_to_target = (target.global_position - global_position).normalized()
			var target_angle = direction_to_target.angle()
			rotate_gun(target_angle)
		else:
			find_zombies_in_area()
	else:
		rotate_gun(forward_angle)

	# Apply melee damage if cooldown allows
	if melee_cd and overlapping_bodies.size() > 0:
		apply_melee_damage()

func sprite_frame_direction():
	if abs(direction.x) > abs(direction.y):  # Horizontal movement
		animated_sprite_2d.animation = "walking"
		animated_sprite_2d.flip_h = direction.x < 0  # Flip for left direction
	elif abs(direction.y) > abs(direction.x):  # Vertical movement
		
		if direction.y < 0:
			animated_sprite_2d.animation = "walking_away"  # Moving upward
		else:
			animated_sprite_2d.animation = "walking_toward"  # Moving downward
	animated_sprite_2d.play()

func find_zombies_in_area():
	var bodies_in_area = targeting.get_overlapping_bodies()
	if bodies_in_area.size() == 0:
		target = null
		is_aiming = false
		return

	var closest_distance = INF
	for body in bodies_in_area:
		if body.is_in_group("zombie") and is_instance_valid(body):
			var distance_to_body = global_position.distance_to(body.global_position)
			if distance_to_body < closest_distance:
				closest_distance = distance_to_body
				target = body

func rotate_gun(target_angle: float):
	gun.rotation = target_angle
	var direction_to_target = Vector2(cos(target_angle), sin(target_angle))
	gun.position = direction_to_target * gun_radius + gun_offset

	if target_angle > PI / 2 or target_angle < -PI / 2:
		gun.flip_v = true
	else:
		gun.flip_v = false
	gun.z_index = 0 if target_angle < 0 else 1

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

func fire_gun():
	if reloaded:
		reloaded = false
		$gunreloadtimer.start()

func _on_timer_timeout():
	reloaded = true

func _on_takedamage_timeout():
	take_damage(0)

func move_to_position(new_target_position: Vector2):
	# Set the target position for the NavigationAgent2D
	target_position = new_target_position
	navigation_agent_2d.target_position = target_position
	moving = true

func _on_melee_body_entered(body: Node2D) -> void:
	if body.is_in_group("zombie") and body not in overlapping_bodies:
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
