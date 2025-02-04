extends CharacterBody2D

var HEALTH = 100
var SPEED = 60.0
var reloaded = true
var gather = false
var direction
var targetResource

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var gun = $Musket
@onready var sabre = $sabre
@onready var healthbar: ProgressBar = $Healthbar
@onready var camera_2d = $"../../Camera2D"

var weapons = []  # List to hold weapons
var current_weapon_index = 0  # Index for switching

func _ready():
	# Initialize weapons list
	weapons = [gun, sabre]
	set_active_weapon(0)  # Start with the first weapon

	# Initialize the healthbar
	update_healthbar()

func _process(delta):
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		camera_2d.global_position = global_position
		sprite_frame_direction()
		velocity = direction * SPEED * delta
		move_and_collide(velocity)
	else:
		velocity = Vector2.ZERO
		animated_sprite_2d.stop()

	# Switch weapons using number keys or a cycle button
	#if Input.is_action_just_pressed("switch_weapon"):  # Define in InputMap
		#switch_weapon()

func _input(event):
	if event is InputEventMouseMotion:
		rotate_weapon(weapons[current_weapon_index])  # Rotate the active weapon
func get_current_weapon():
	return weapons[current_weapon_index]  # Returns the active weapon node

func switch_weapon():
	# Increment index and loop around
	current_weapon_index = (current_weapon_index + 1) % weapons.size()
	set_active_weapon(current_weapon_index)

func set_active_weapon(index):
	# Hide all weapons
	for weapon in weapons:
		weapon.hide()

	# Show selected weapon
	weapons[index].show()

	# Special handling for the sword
	if sabre is Area2D:
		var collision = sabre.get_node("CollisionShape2D")
		if index == weapons.find(sabre):  # If selecting the sword
			sabre.monitoring = true
			collision.set_deferred("disabled", false)
		else:  # If switching to gun
			sabre.monitoring = false
			collision.set_deferred("disabled", true)


func sprite_frame_direction():
	if direction == Vector2(0, -1):  # Specific case for upward movement
		animated_sprite_2d.animation = "walking_away"
		animated_sprite_2d.play()  # Play animation for consistency
	elif direction.x != 0:  # Horizontal movement
		animated_sprite_2d.animation = "walking_side"
		animated_sprite_2d.flip_h = direction.x < 0  # Flip sprite for left direction
		animated_sprite_2d.play()
	elif direction.y > 0:  # Downward movement
		animated_sprite_2d.animation = "walking_toward"
		animated_sprite_2d.play()
	else:  # No movement
		animated_sprite_2d.stop()

func update_healthbar():
	# Sync the healthbar with the current health
	healthbar.value = HEALTH

func slow_affect(activate):
	if activate:
		SPEED = 30.0
	else:
		SPEED = 60.0

func take_damage(amount: int):
	#print("running")
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
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1.0)  # Fade out
	tween.tween_callback(queue_free)  # Remove after animation


func rotate_weapon(current_weapon):
	var mouse_position = get_global_mouse_position()
	var direction_to_mouse = (mouse_position - global_position).normalized()
	var angle = direction_to_mouse.angle()

	current_weapon.rotation = angle
	var weapon_radius = 25.0  
	current_weapon.position = Vector2(cos(angle), sin(angle)) * weapon_radius + Vector2(0, -25)
	if angle > PI / 2 or angle < -PI / 2:
		current_weapon.flip_v = true
	else:
		current_weapon.flip_v = false
	if angle < 0:
		current_weapon.z_index = 0
	else:
		current_weapon.z_index = 1
func weapon_hitbox():
	if reloaded:
		var hitbox_area = weapons[current_weapon_index]  # Get current weapon

		var overlapping_bodies = hitbox_area.get_overlapping_bodies()
		for body in overlapping_bodies:
			if body.is_in_group("zombie"):
				body.take_damage(50)
				print("Hit zombie: ", body.name)

		var overlapping_areas = hitbox_area.get_overlapping_areas()
		for area in overlapping_areas:
			if area.is_in_group("plant"):	
				area.chopped_down()

		reloaded = false
		$Meleetimer.start()

func _on_meleetimer_timeout() -> void:
	reloaded = true

func _on_reload_timeout():
	reloaded = true


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group('zombie'):
		body.take_damage(40)
