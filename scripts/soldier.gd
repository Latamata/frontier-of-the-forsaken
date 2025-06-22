extends CharacterBody2D

signal soldier_died(light_holder: bool)

var direction = Vector2.RIGHT
var melee_cd = true
var is_aiming = false
#var is_attacking = false
var moving = false
var reloaded = true
var light_holder = false

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
@onready var arm: Sprite2D = $arm
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var overlapping_bodies = []  # List of bodies in melee range
var weapon_in_use = "gun"  # Track the weapon being used ("gun" or "sabre")
const ARM_POSITIONS = {
	"right": Vector2(8, -30),
	"left": Vector2(-6, -30),
	"down": Vector2(8, -30),
	"idle": Vector2(-6, -28)
}
var reload_pumps := 0
var reload_tick_in_progress = true

func _ready():
	rotate_weapon(forward_angle)
	# Initialize health bar values
	healthbar.min_value = 0
	healthbar.max_value = MAX_HEALTH
	healthbar.value = HEALTH

# Assuming you are already setting the target position
func _process(_delta):
	if moving:
		var next_position = navigation_agent_2d.get_next_path_position()
		if global_position.distance_to(next_position) < 5:
			moving = false
			navigation_agent_2d.set_target_position(global_position)
		else:
			direction = (next_position - global_position).normalized()
			velocity = direction * speed
			move_and_slide()
			sprite_frame_direction()
	else:
		# Handle per-idle-frame reload pumping
		if weapon_in_use == "gun" and not reloaded and reload_pumps > 0:
			animation_player.play("reload")
		velocity = Vector2.ZERO
		direction = Vector2.ZERO
		if animated_sprite_2d.animation != "idle":
			animated_sprite_2d.animation = "idle"
			sprite_frame_direction()
			rotate_weapon(forward_angle)
			arm.visible = true
	if is_aiming:
		if target and is_instance_valid(target) and reloaded:
			var predicted_position = predict_target_position(target)
			var direction_to_target = (predicted_position - global_position).normalized()
			var target_angle = direction_to_target.angle()
			rotate_weapon(target_angle)
		else:
			find_zombies_in_area()
	# This is the new part:
# Check if melee is active but no zombies are nearby anymore
	if weapon_in_use == "sabre":
		var still_has_close_enemies := false
		for body in $Melee.get_overlapping_bodies():
			if is_instance_valid(body) and body.is_in_group("zombie"):
				still_has_close_enemies = true
				break
		if not still_has_close_enemies:
			switch_weapon("gun")


func predict_target_position(zombie: Node2D) -> Vector2:
	if not is_instance_valid(zombie):
		return zombie.global_position

	var to_target = zombie.global_position - global_position
	var bullet_speed = 500.0  # adjust to match your projectile speed
	var zombie_velocity = Vector2.ZERO

	if "velocity" in zombie:
		zombie_velocity = zombie.velocity
	elif zombie.has_method("get_velocity"):
		zombie_velocity = zombie.get_velocity()
	
	# Time for bullet to reach the zombie
	var distance = to_target.length()
	var time_to_hit = distance / bullet_speed

	# Predict future position
	return zombie.global_position + zombie_velocity * time_to_hit

var facing_right := true
func sprite_frame_direction():
	# No movement - idle

	if abs(direction.x) > abs(direction.y):
		# Horizontal movement
		animated_sprite_2d.animation = "walking"
		animated_sprite_2d.play()
		arm.visible = true
		if direction.x > 0:
			facing_right = true
			animated_sprite_2d.flip_h = false
			arm.flip_h = false
			arm.flip_v = false
			arm.rotation = 0
			arm.position = ARM_POSITIONS["right"]
		elif direction.x < 0:
			facing_right = false
			animated_sprite_2d.flip_h = true
			arm.flip_h = true
			arm.flip_v = false
			arm.rotation = 0
			arm.position = ARM_POSITIONS["left"]

	elif abs(direction.y) > abs(direction.x):
		# Vertical movement
		animated_sprite_2d.flip_h = false

		if direction.y > 0:
			# Moving down
			animated_sprite_2d.animation = "walking_toward"
			animated_sprite_2d.play()
			animated_sprite_2d.flip_h = true
			arm.visible = true
			arm.flip_h = true
			arm.flip_v = false
			arm.rotation = 0
			arm.position = ARM_POSITIONS["down"]
		elif direction.y < 0:
			# Moving up
			animated_sprite_2d.animation = "walking_away"
			animated_sprite_2d.play()
			arm.visible = false  # Hide arm when walking away
	else:
		animated_sprite_2d.animation = "idle"
		animated_sprite_2d.play()
		animated_sprite_2d.flip_h = true
		arm.visible = true
		arm.flip_h = true
		arm.flip_v = false
		arm.rotation = 0
		#arm.position = ARM_POSITIONS["idle"] 
		arm.position = Vector2(10,-30)

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
	HEALTH = max(HEALTH, 0)
	healthbar.value = HEALTH

	if HEALTH <= 0:
		
		die()
		emit_signal("soldier_died", light_holder)

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
	#print(reloaded)
	if reloaded and not moving:
		
#if not reloaded and reload_pumps > 0 and not reload_tick_in_progress:
		# 🔫 Immediate fire
		$attackanimation.global_position = $Musket/Marker2D.global_position
		$attackanimation.rotation = gun.rotation
		$attackanimation.play("smoke")
		# 🕒 Delay + reload animation + reload complete
		call_deferred("_start_reload_animation")
		return true
	return false

func _start_reload_animation() -> void:
	await get_tree().create_timer(0.5).timeout  # Add delay here (0.3 seconds — change as needed)

	reloaded = false
	#reload_tick_in_progress = false
	reload_pumps = 10  # Now you’re reloaded

func switch_weapon(weapon: String):
	weapon_in_use = weapon

	match weapon:
		"gun":
			gun.visible = true
			sabre.visible = false
		"sabre":
			gun.visible = false
			sabre.visible = true
		_:
			push_error("Unknown weapon: %s" % weapon)

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
	var offset = Vector2(-50, -5)  # Adjust as needed
	$attackanimation.global_position = $sabre/Marker2D.global_position + offset

	$attackanimation.play('default')
	$SwordSound.play()

func apply_melee_damage(body):
	if weapon_in_use == "sabre" and melee_cd:
		rotate_weapon(forward_angle)
		target = body
		melee_cd = false
		$Meleetimer.start()
		#var forward_angle = (body.global_position - global_position).angle()
		rotate_weapon(forward_angle)
		sword_attack()
		#is_attacking = true
		body.take_damage(30)

func _on_meleetimer_timeout() -> void:
	for body in $Melee.get_overlapping_bodies():
		if is_instance_valid(body) and body.is_in_group("zombie"):
			apply_melee_damage(body)
	melee_cd = true

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == 'reload':
		reload_pumps -= 1
		#reload_tick_in_progress = false
		if reload_pumps <= 0:
			reload_pumps = 0
			reloaded = true
			rotate_weapon(forward_angle)
var point_light: PointLight2D = null

func add_point_light():
	if point_light:  # Avoid creating multiple lights
		return
	point_light = PointLight2D.new()
	point_light.texture = preload("res://assets/circle_light.png")
	point_light.energy = 0.14
	point_light.z_index = -1
	point_light.position = Vector2(0, -10)
	point_light.scale = Vector2(6.84, 6.62)
	point_light.color = Color("#ffffff5f")
	add_child(point_light)

func remove_point_light():
	if point_light and point_light.is_inside_tree():
		point_light.queue_free()
		point_light = null

func _on_melee_body_entered(body: Node2D) -> void:
	if body.is_in_group("zombie"):
		# Auto-switch weapon based on enemy proximity
		var has_close_enemy = false
		for zombie in $Melee.get_overlapping_bodies():
			if is_instance_valid(zombie) and zombie.is_in_group("zombie"):
				has_close_enemy = true
				$Meleetimer.start()
				break
		if has_close_enemy:
			if weapon_in_use != "sabre":
				switch_weapon("sabre")
