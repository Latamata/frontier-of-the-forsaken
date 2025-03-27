extends CharacterBody2D

var direction = Vector2.RIGHT
var melee_cd = true
var is_aiming = false
var is_attacking = false
var moving = false
var reloaded = true
var target_position: Vector2
var speed = 19.0
var forward_angle: float = 0
var target
var HEALTH = 100  # NPC's starting health

@export var MAX_HEALTH = 100  # Used to set the health max on the loading of healthbar
@onready var gun_marker = $Musket/Marker2D
@onready var gun = $Musket
@export var gun_offset = Vector2(0, -25)
@export var gun_radius = 20.0
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var targeting = $targeting
@onready var healthbar: ProgressBar = $Healthbar
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var sabre: Sprite2D = $sabre
@onready var meleetimer: Timer = $Meleetimer

var overlapping_bodies = []  # List of bodies in melee range
var weapon_in_use = "gun"  # Track the weapon being used ("gun" or "sabre")

func _ready():
	# Initialize health bar values
	healthbar.min_value = 0
	healthbar.max_value = MAX_HEALTH
	healthbar.value = HEALTH

# Assuming you are already setting the target position
func _process(_delta):
	if moving:
		# Ask NavigationAgent2D for the next point on the path
		var next_position = navigation_agent_2d.get_next_path_position()
		
		# If close enough to the target, stop moving
		if global_position.distance_to(next_position) < 5:
			moving = false
			navigation_agent_2d.set_target_position(global_position)  # Reset the target position
		else:
			# Calculate the direction and move
			direction = (next_position - global_position).normalized()
			velocity = direction * speed
			move_and_slide()
			sprite_frame_direction()
	else:
		animated_sprite_2d.animation = "idle"
	
	# Check if we are aiming and if the target is within melee range
	if is_aiming:
		if target and is_instance_valid(target):
			var direction_to_target = (target.global_position - global_position).normalized()
			var target_angle = direction_to_target.angle()
			
			# Rotate the weapon based on the target's position
			rotate_weapon(target_angle)

		else:
			find_zombies_in_area()
	else:
		rotate_weapon(forward_angle)

func sprite_frame_direction():
	if abs(direction.x) > abs(direction.y):  # Horizontal movement
		animated_sprite_2d.animation = "walking"
		animated_sprite_2d.flip_h = direction.x < 0  # Flip for left direction
		animated_sprite_2d.play()
	elif abs(direction.y) > abs(direction.x):  # Vertical movement
		if direction.y < 0:
			animated_sprite_2d.animation = "walking_away"  # Moving upward
		else:
			animated_sprite_2d.animation = "walking_toward"  # Moving downward
		animated_sprite_2d.play()
	else:
		animated_sprite_2d.animation = "idle"

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

func rotate_weapon(target_angle: float):
	# Rotate the current weapon based on which weapon is in use
	if weapon_in_use == "gun":
		# Rotate the gun to aim at the target
		gun.rotation = target_angle
		var direction_to_target = Vector2(cos(target_angle), sin(target_angle))
		gun.position = direction_to_target * gun_radius + gun_offset

		if target_angle > PI / 2 or target_angle < -PI / 2:
			gun.flip_v = true
		else:
			gun.flip_v = false
		gun.z_index = 0 if target_angle < 0 else 1

	elif weapon_in_use == "sabre":
		# Rotate the sabre to face the same direction as the NPC
		# You can choose to follow the NPC's facing direction or the target's angle
		sabre.rotation = forward_angle
		if abs(forward_angle) > PI / 2:
			sabre.flip_v = true
		else:
			sabre.flip_v = false
		sabre.z_index = 1

func take_damage(amount: int):
	if !$Healthbar.visible:
		$Healthbar.visible = true
	HEALTH -= amount
	HEALTH = max(HEALTH, 0)  # Ensure health doesn't drop below 0
	healthbar.value = HEALTH  # Update health bar

	if HEALTH <= 0:
		die()

func die():
	animated_sprite_2d.stop()  # Stop movement animation
	set_physics_process(false)  # Disable further movement
	set_process(false)

	var tween = get_tree().create_tween()
	tween.tween_property(self, "rotation_degrees", 90, 0.5)  # Rotate sideways
	tween.tween_callback(queue_free)  # Remove after animation

	Globals.add_soldier_count(-1)

func slow_affect(activate):
	if activate:
		speed = 15.0
	else:
		speed = 30.0

func move_to_position(new_target_position: Vector2):
	target_position = new_target_position
	navigation_agent_2d.set_target_position(target_position)
	moving = true

func fire_gun():
	if reloaded and not moving:  # Prevent shooting while moving
		$attackanimation.global_position = $Musket/Marker2D.global_position
		$attackanimation.rotation = gun.rotation
		$attackanimation.play("smoke")
		reloaded = false
		$gunreload.start()


func _on_gunreload_timeout() -> void:
	reloaded = true

# Switch to gun
func switch_to_gun():
	if weapon_in_use != "gun":
		weapon_in_use = "gun"
		gun.visible = true
		sabre.visible = false
		#animated_sprite_2d.animation = "idle"
	else:
		weapon_in_use = "sabre"
		gun.visible = false
		sabre.visible = true
		#animated_sprite_2d.animation = "melee_attack"

var original_sabre_rotation = 0.0  # Store original rotation before swinging
func sword_attack():
	original_sabre_rotation = sabre.rotation  # Save initial rotation
	
	#if target and is_instance_valid(target):
	var attack_angle = (target.global_position - global_position).normalized().angle()
	var final_rotation = attack_angle + deg_to_rad(45)  # Define target rotation
	
	# Create a tween for smooth rotation over time
	var tween = get_tree().create_tween()
	tween.tween_property(sabre, "rotation", final_rotation, 0.2) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUAD)  # First tween

	tween.tween_property(sabre, "rotation", original_sabre_rotation, 0.2) \
		.set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_QUAD)  # Second tween (automatically runs after the first)

	# Play attack animation at correct position
	$attackanimation.rotation = sabre.rotation
	$attackanimation.global_position = $sabre/Marker2D.global_position
	$attackanimation.play('default')


func apply_melee_damage():
	if melee_cd:
		for body in $Melee.get_overlapping_bodies():
			if is_instance_valid(body):
				target = body
				melee_cd = false
				$Meleetimer.start()
				# Make NPC face the target before attacking
				forward_angle = (body.global_position - global_position).angle()
				rotate_weapon(forward_angle)

				# Perform the attack
				sword_attack()
				is_attacking = true
				body.take_damage(30)  # Adjust damage amount as needed
		
		melee_cd = false
		meleetimer.start()


func _on_meleetimer_timeout() -> void:
	melee_cd = true
