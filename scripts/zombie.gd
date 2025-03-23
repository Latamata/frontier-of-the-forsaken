extends CharacterBody2D

# Variables
var direction = Vector2.RIGHT
var moving = true
var is_attacking = false
var melee_cd = true
var target_position: Vector2
var HEALTH = 100
var target = null
var SPEED = 0.10  # Base speed
var time_since_last_path_update = 0.0
var path_update_interval = 0.1  # Pathfinding update interval
var overlapping_bodies = []  # Bodies in melee range
var boundary_min = Vector2(0, 0)  # Example: Bottom-left corner of the area
var boundary_max = Vector2(144, 144)
var gold_coin: PackedScene = preload("res://scenes/item_drop.tscn")
# Nodes
@onready var animated_sprite_2d = $Spritesheet
@onready var navigation_agent_2d = $NavigationAgent2D
@onready var targeting = $targeting
@onready var healthbar: ProgressBar = $Healthbar
@onready var meleetimer: Timer = $Meleetimer

func _ready():
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)
	update_healthbar()

func _process(delta):
	time_since_last_path_update += delta
	if not navigation_agent_2d.is_navigation_finished():
		#print("runninh")
		direction = (navigation_agent_2d.get_next_path_position() - global_position).normalized()
		velocity = direction * SPEED
	else:
		#moving = false
		animated_sprite_2d.stop()
		velocity = Vector2.ZERO
			# Check if target goes out of bounds
	if target and is_instance_valid(target):
		# Continue chasing the target if valid
		if time_since_last_path_update > path_update_interval:
			#print('running')
			navigation_agent_2d.target_position = target.global_position
			time_since_last_path_update = 0.0  # Reset timer
			target = null  # Optionally reset the target if out of bounds
	else:
		find_target()  # Look for a new target
	# Handle melee if target is in range
	sprite_frame_direction()
	if melee_cd and overlapping_bodies.size() > 0:
		apply_melee_damage()
	#move_and_collide(velocity * delta)
	move_and_slide()
func _on_animation_finished():
	if animated_sprite_2d.animation == "attack":
		is_attacking = false  # Reset attack state
		sprite_frame_direction()  # Resume movement animation

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
		# If no valid target found, stop moving
		#if closest_target == null:
			#target = null
			#moving = false
			target = closest_target

func sprite_frame_direction():
	if !is_attacking:
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
	if !$Healthbar.visible:
		$Healthbar.visible = true
	HEALTH -= amount
	HEALTH = max(HEALTH, 0)  # Ensure health doesn't drop below 0
	healthbar.value = HEALTH  # Update health bar

	# Flash red when hit
	animated_sprite_2d.modulate = Color(1, 0, 0)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.2 seconds
	animated_sprite_2d.modulate = Color(1, 1, 1)  # Reset to normal

	if HEALTH <= 0:
		die()

func die():
	var coins = gold_coin.instantiate()  # Instantiate the coin
	coins.position = global_position  
	#coins.resource_type = 'gold'

	# Find the plantgroup node dynamically
	var plantgroup = get_tree().get_root().find_child("plantgroup", true, false)
	if plantgroup:
		plantgroup.add_child(coins)
	else:
		print("Error: 'plantgroup' node not found!")

	animated_sprite_2d.stop()  # Stop movement animation
	set_physics_process(false)  # Disable further movement
	set_process(false)

	var tween = get_tree().create_tween()
	tween.tween_property(self, "rotation_degrees", 90, 0.5)  # Rotate sideways
	tween.tween_callback(queue_free)  # Remove after animation



func slow_affect(activate):
	SPEED = 15.0 if activate else 30.0

func update_healthbar():
	healthbar.value = HEALTH  # Sync healthbar with current health

func _on_melee_body_entered(body: Node2D) -> void:
	if body.is_in_group("npc") and body not in overlapping_bodies:
		overlapping_bodies.append(body)
	if body.name == 'player':
		overlapping_bodies.append(body)

func _on_melee_body_exited(body: Node2D) -> void:
	if body in overlapping_bodies:
		overlapping_bodies.erase(body)  # Remove the specific body from the list

func apply_melee_damage():
	for body in overlapping_bodies:
		if is_instance_valid(body):
			is_attacking = true
			animated_sprite_2d.animation = "attack"
			animated_sprite_2d.play()
			body.take_damage(30)  # Adjust damage amount as needed
	melee_cd = false
	meleetimer.start()

func _on_meleetimer_timeout() -> void:
	melee_cd = true
	is_attacking = false  # Allow movement animations again
	sprite_frame_direction()  # Make sure it switches back to walking
