extends CharacterBody2D

var direction = Vector2.RIGHT
var melee_cd = true
var is_aiming = false
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
#@onready var navigation_agent_2d = $NavigationAgent2D
@onready var targeting = $targeting
@onready var healthbar: ProgressBar = $Healthbar
#@onready var meleetimer: Timer = $Meleetimer
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

var overlapping_bodies = []  # List of bodies in melee range

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
	if is_aiming:
		#print('running')
		if target and is_instance_valid(target):
			var direction_to_target = (target.global_position - global_position).normalized()
			var target_angle = direction_to_target.angle()
			rotate_gun(target_angle)
		else:
			find_zombies_in_area()
	else:
		rotate_gun(forward_angle)

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
	#tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1.0)  # Fade out
	tween.tween_callback(queue_free)  # Remove after animation

	Globals.add_soldier_count(-1)

func slow_affect(activate):
	if activate:
		speed = 15.0
	else:
		speed = 30.0

func move_to_position(new_target_position: Vector2):
	#print("Moving to: ", new_target_position)  # Debug print
	target_position = new_target_position
	navigation_agent_2d.set_target_position(target_position)
	moving = true

func fire_gun():
	if reloaded:
		$attackanimation.global_position = $Musket/Marker2D.global_position
		$attackanimation.rotation = gun.rotation
		$attackanimation.play("smoke")
		reloaded = false
		$gunreload.start()

func _on_gunreload_timeout() -> void:
	reloaded = true
