extends CharacterBody2D

signal collect_item()  # Define signal with a parameter
signal heal_npc

var HEALTH = 100
var SPEED = 0.10
var reloaded = true
var gather = false
var direction
var targetResource

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var gun = $Musket
@onready var sabre = $sabre
@onready var healthbar: ProgressBar = $Healthbar
@onready var camera_2d = $"../../../Camera2D"
@onready var reload_timer = $reload

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
		velocity = direction * SPEED
		move_and_collide(velocity * delta)

	else:
		velocity = Vector2.ZERO
		animated_sprite_2d.stop()


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


func rotate_weapon(current_weapon):
	var mouse_position = get_global_mouse_position()
	var direction_to_mouse = (mouse_position - global_position).normalized()
	var angle = direction_to_mouse.angle()

	current_weapon.rotation = angle
	var weapon_radius = 5.0  
	current_weapon.position = Vector2(cos(angle), sin(angle)) * weapon_radius + Vector2(0, -25)
	if angle > PI / 2 or angle < -PI / 2:
		current_weapon.flip_v = true
	else:
		current_weapon.flip_v = false
	if angle < 0:
		current_weapon.z_index = 0
	else:
		current_weapon.z_index = 1

var original_sabre_rotation = 0.0  # Store original rotation before swinging

func sword_attack():
	original_sabre_rotation = sabre.rotation  # Save initial rotation
	var attack_angle = (get_global_mouse_position() - global_position).normalized().angle()
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
	for entitity in $sabre/Area2D.get_overlapping_bodies():
		#print(entitity)
		if entitity.is_in_group('zombie'):
			entitity.take_damage(20)

#func _on_meleetimer_timeout():
	#sabre.rotation = original_sabre_rotation  # Reset to saved rotation
	##$sabre/attackanimation.visible = false

func player_shoot():
	reload_timer.start()
	reloaded = false
	$attackanimation.rotation = gun.rotation
	$attackanimation.global_position = $Musket/Marker2D.global_position 
	$attackanimation.play('smoke')

func _on_reload_timeout():
	reloaded = true

func _on_collection_area_area_entered(area: Area2D) -> void:
	
	if area.resource_type == 'health' :
		if  HEALTH < 100:
			area.collected()
			HEALTH += 1
			update_healthbar()
		else:
			emit_signal('heal_npc')
			area.collected()
	if area.resource_type == 'gold':
		area.collected()
		Globals.add_gold(1)
	elif area.resource_type == 'food':
		area.collected()
		Globals.add_food(1)
	emit_signal("collect_item")  # Pass the collected item as an argument
