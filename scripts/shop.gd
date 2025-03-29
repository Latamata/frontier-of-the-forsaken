extends Control

@onready var info: RichTextLabel = $Panel/Info
@onready var buy_bullet: Button = $Panel/buy_bullet
@onready var buy_bullet_steel: Button = $Panel/buy_bullet_steel
@onready var holy_bullet: Button = $Panel/holy_bullet

signal bought_something

func _ready() -> void:
	# Check if 'lead' or 'steel' is in the unlocked bullets list
	if Globals.bullet_type == 'lead':
		buy_bullet.disabled = true
		buy_bullet.flat = true
	if Globals.bullet_type == 'steel':
		buy_bullet_steel.disabled = true
		buy_bullet_steel.flat = true
	if Globals.bullet_type == 'holy_bullet':
		holy_bullet.disabled = true
		holy_bullet.flat = true
	if "lead" in Globals.bullets_unlocked:
		if Globals.bullet_type == 'lead':
			$Panel/buy_bullet.flat = true
			$Panel/buy_bullet_steel.flat = false
	if "holy_bullet" in Globals.bullets_unlocked:
		print()
	if "steel" in Globals.bullets_unlocked:
		if Globals.bullet_type == 'steel':
			$Panel/buy_bullet.flat = false
			$Panel/buy_bullet_steel.flat = true
	else:
		# In case no bullet type is selected, reset the buttons
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
	if "lead" in Globals.bullets_unlocked:
		buy_bullet.disabled = true
		buy_bullet_steel.disabled = false
		holy_bullet.disabled = false
		# Toggle bullet type after unlocking
		Globals.bullet_type = 'lead'
		buy_bullet_steel.flat = false
		buy_bullet.flat = true
	elif Globals.gold >= 15:
		buy_bullet.disabled = true
		buy_bullet_steel.disabled = false
		holy_bullet.disabled = false
		# First-time purchase
		buy_bullet_steel.flat = false
		buy_bullet.flat = true
		Globals.gold -= 15
		
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
	if "steel" in Globals.bullets_unlocked:
		buy_bullet.disabled = false
		holy_bullet.disabled = false
		buy_bullet_steel.disabled = true
		# Toggle bullet type
		Globals.bullet_type = 'steel'
		buy_bullet.flat = false
		buy_bullet_steel.flat = true
	elif Globals.gold >= 15:
		holy_bullet.disabled = false
		buy_bullet.disabled = false
		buy_bullet_steel.disabled = true
		# First-time purchase
		Globals.bullets_unlocked.append('steel')
		buy_bullet_steel.flat = true
		buy_bullet.flat = false
		Globals.gold -= 15
		Globals.bullet_type = 'steel'
		emit_signal("bought_something")
	if Globals.bullet_type == 'steel':
		info.text += "\n[color=green]Selected[/color]"


func _on_holy_bullet_button_down() -> void:
	if "holy_bullet" in Globals.bullets_unlocked:
		buy_bullet_steel.disabled = false
		buy_bullet.disabled = false
		holy_bullet.disabled = true
		# Toggle bullet type
		Globals.bullet_type = 'holy_bullet'
		buy_bullet.flat = false
		buy_bullet_steel.flat = false
	elif Globals.gold >= 500:
		buy_bullet.disabled = false
		buy_bullet_steel.disabled = false
		holy_bullet.disabled = true
		Globals.bullets_unlocked.append('holy_bullet')
		# First-time purchase
		buy_bullet_steel.flat = false
		buy_bullet.flat = false
		Globals.gold -= 15
		Globals.bullet_type = 'holy_bullet'
		emit_signal("bought_something")
	if Globals.bullet_type == 'holy_bullet':
		info.text += "\n[color=green]Selected[/color]"



func _on_holy_bullet_mouse_entered() -> void:
	info.text = "
	Item: Holy Bullet
	Cost: 150g
	Damage: 25"
	
	# Check if the bullet type is 'steel', and if so, append 'selected' to the info text
	if Globals.bullet_type == 'holy_bullet':
		info.text += "\n[color=green]Selected[/color]"
