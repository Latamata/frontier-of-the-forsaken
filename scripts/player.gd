extends CharacterBody2D

var HEALTH = 100
var SPEED = 60.0
var reloaded = true
var gather = false
var direction
var targetResource

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var gun = $Musket
@export var gun_offset = Vector2(10, -15)
@export var gun_radius = 1.0
@onready var camera_2d = $"../Camera2D"
@onready var sabre = $sabre
@onready var healthbar: ProgressBar = $Healthbar

func _ready():
	# Initialize the healthbar
	update_healthbar()

func _physics_process(delta):
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		camera_2d.global_position = global_position
		sprite_frame_direction()
		velocity = direction * SPEED * delta
		move_and_collide(velocity)
	else:
		velocity = Vector2.ZERO
		animated_sprite_2d.stop()
	#rotate_sword_to_mouse()  # Keep sword aligned to the mouse

func _input(event):
	if event is InputEventMouseMotion:
		rotate_gun()
		#pass

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
	queue_free()

func rotate_gun():
	var mouse_position = get_global_mouse_position()
	var direction_to_mouse = (mouse_position - global_position).normalized()
	var angle = direction_to_mouse.angle()
	sabre.rotation = angle
	sabre.position = direction_to_mouse * gun_radius + gun_offset
	#if angle > PI / 2 or angle < -PI / 2:
		#gun.flip_v = true
	#else:
		#gun.flip_v = false
	#if angle < 0:
		#gun.z_index = 0
	#else:
		#gun.z_index = 1

func _on_reload_timeout():
	reloaded = true


func swing_sword():
	sabre.rotation = (get_global_mouse_position() - global_position).normalized().angle() + 45
	sabre.get_child(1).disabled = false  # Enable sword hitbox
	$Meleetimer.start()  # Start the timer


func _on_sabre_body_entered(body):
	#print(body)
	if body.is_in_group("plant"):
		print("running")
		body.chopped_down()
	if body.is_in_group("zombie"):
		body.take_damage(20)
		#print("hit zombie")

func rotate_sword_to_mouse():
	var mouse_position = get_global_mouse_position()
	var direction_to_mouse = (mouse_position - sabre.global_position).normalized()
	var angle = direction_to_mouse.angle()
	sabre.rotation = angle


func _on_meleetimer_timeout() -> void:
	sabre.rotation = 0
	sabre.get_child(1).disabled = true
	$Meleetimer.stop()  # Explicitly stop the timer when done
