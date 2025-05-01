extends CharacterBody2D


# Variables
var direction = Vector2.RIGHT
#var moving = true
var is_attacking = false
var melee_cd = true
var target_position: Vector2
var HEALTH = 100
var DAMAGE = 35
var target = null
var SPEED = 30  # Base speed
var speed_modifier = 0  # Base speed
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
@onready var melee: Area2D = $Melee

func _ready():
	update_healthbar()

func _process(delta):
	time_since_last_path_update += delta
	
	# If attacking, don't move
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return  # Stop further execution
	
	if melee_cd && target:
		melee_cd = false
		meleetimer.start()  # Start cooldown timer
		apply_melee_damage()

	elif not navigation_agent_2d.is_navigation_finished():
		#print('rinning')
		direction = (navigation_agent_2d.get_next_path_position() - global_position).normalized()
		velocity = direction * (SPEED + speed_modifier)
		#velocity = direction * SPEED
		move_and_slide()
	else:
		animated_sprite_2d.stop()
		velocity = Vector2.ZERO
		
	if target and is_instance_valid(target):
		# Continue chasing the target if valid
		if time_since_last_path_update > path_update_interval:
			#print('running')
			navigation_agent_2d.target_position = target.global_position
			time_since_last_path_update = 0.0  # Reset timer
			#if target.global_position.distance_to(global_position) > 200:  # or some logic
			target = null
	else:
		find_target()  # Look for a new target
	#print(target)
	


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
	#moving = true

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
	# XP reward
	Globals.add_experience(10)  # Or whatever amount makes sense

	# Gold drop
	var coins = gold_coin.instantiate()
	coins.position = global_position

	var plantgroup = get_tree().get_root().find_child("plantgroup", true, false)
	if plantgroup:
		plantgroup.add_child(coins)
	else:
		print("Error: 'plantgroup' node not found!")

	animated_sprite_2d.stop()
	set_physics_process(false)
	set_process(false)

	var tween = get_tree().create_tween()
	tween.tween_property(self, "rotation_degrees", 90, 0.5)
	tween.tween_callback(queue_free)

func slow_affect(activate):
	if activate:
		speed_modifier = -15  # Slow them down by 15
	else:
		speed_modifier = 0  # No slow


func update_healthbar():
	healthbar.value = HEALTH  # Sync healthbar with current health

func apply_melee_damage():
	
	# Check if target is within melee range
	if target in melee.get_overlapping_bodies():
		$AudioStreamPlayer2D.play()
		is_attacking = true
		# Play attack animation
		animated_sprite_2d.animation = "attack"
		animated_sprite_2d.play()

		# Deal damage
		target.take_damage(DAMAGE)

# Ensure attack animation resets `is_attacking`
func _on_Spritesheet_animation_finished():
	if animated_sprite_2d.animation == "attack":
		is_attacking = false
		sprite_frame_direction()  # Resume normal movement animation

# Melee cooldown timer callback
func _on_meleetimer_timeout():
	melee_cd = true
	is_attacking = false  # Ensure we can attack again
	sprite_frame_direction()
