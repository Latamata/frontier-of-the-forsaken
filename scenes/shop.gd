extends Control
@onready var info: RichTextLabel = $Panel/Info

signal bought_something

func _ready() -> void:
	# Check the bullet type and adjust button states accordingly
	if Globals.bullet_type == 'lead':
		$Panel/buy_bullet.flat = true
		$Panel/buy_bullet_steel.flat = false
	elif Globals.bullet_type == 'steel':
		$Panel/buy_bullet.flat = false
		$Panel/buy_bullet_steel.flat = true
	else:
		# In case of no bullet type being selected, you can reset the buttons
		$Panel/buy_bullet.flat = false
		$Panel/buy_bullet_steel.flat = false

# Update for Soldier
func _on_buy_soldier_mouse_entered() -> void:
	info.text = "
	Item: Soldier
	Cost: 25g"

func _on_buy_soldier_button_down() -> void:
	if Globals.gold >= 25:
		Globals.gold -= 25
		Globals.soldier_count += 1
		emit_signal("bought_something")

# Update for Food
func _on_buy_food_mouse_entered() -> void:
	info.text = "
	Item: Food
	Cost: 15g"

func _on_buy_food_button_down() -> void:
	if Globals.gold >= 25:
		Globals.gold -= 25
		Globals.food += 10
		emit_signal("bought_something")

# Update for Bullet (Iron Bullet)
func _on_buy_bullet_mouse_entered() -> void:
	# Set the main info text about the bullet
	info.text = "
	Item: Iron bullet
	Cost: 15g
	Damage: 15g"
	
	# Check if the bullet type is 'lead', and if so, append 'selected' to the info text
	if Globals.bullet_type == 'lead':
		info.text += "\n[color=green]Selected[/color]"

func _on_buy_bullet_button_down() -> void:
	if Globals.bullets_unlocked:
		# Toggle bullet type after unlocking
		Globals.bullet_type = 'lead'
		$Panel/buy_bullet_steel.flat = false
		$Panel/buy_bullet.flat = true
	elif Globals.gold >= 15:
		# First-time purchase
		$Panel/buy_bullet_steel.flat = false
		$Panel/buy_bullet.flat = true
		Globals.gold -= 15
		Globals.bullets_unlocked = true
		Globals.bullet_type = 'lead'
		emit_signal("bought_something")
	if Globals.bullet_type == 'lead':
		info.text += "\n[color=green]Selected[/color]"

# Update for Bullet (Steel Bullet)
func _on_buy_bullet_steel_mouse_entered() -> void:
	info.text = "
	Item: Steel bullet
	Cost: 15g
	Damage: 15g"
	
	# Check if the bullet type is 'steel', and if so, append 'selected' to the info text
	if Globals.bullet_type == 'steel':
		info.text += "\n[color=green]Selected[/color]"

func _on_buy_bullet_steel_button_down() -> void:
	if Globals.bullets_unlocked:
		# Toggle bullet type
		Globals.bullet_type = 'steel'
		$Panel/buy_bullet.flat = false
		$Panel/buy_bullet_steel.flat = true
	elif Globals.gold >= 15:
		# First-time purchase
		$Panel/buy_bullet_steel.flat = true
		$Panel/buy_bullet.flat = false
		Globals.gold -= 15
		Globals.bullets_unlocked = true
		Globals.bullet_type = 'steel'
		print(Globals.bullet_type)
		emit_signal("bought_something")
	if Globals.bullet_type == 'steel':
		info.text += "\n[color=green]Selected[/color]"
