extends Control

#var enable_gold = true
@onready var info: RichTextLabel = $Panel/Info
#@onready var buy_bullet: Button = $Panel/buy_bullet/
#@onready var buy_bullet_steel: Button = $Panel/buy_bullet_steel
#@onready var holy_bullet: Button = $Panel/holy_bullet
@onready var golden_musket: Button = $Panel/golden_musket
@onready var golden_sword: Button = $Panel/golden_sword
@onready var item_list: ItemList = $Panel/ItemList

signal bought_something

func _ready() -> void:
	match Globals.bullet_type:
		"lead":
			item_list.select(0)
		"steel":
			item_list.select(1)
		"holy_bullet":
			item_list.select(2)


# Helper function to update button states and set info text
func update_bullet_buttons(button: Button, bullet_type: String, button_list: Array) -> void:
	for b in button_list:
		b.disabled = false
		b.flat = false
	
	button.disabled = true
	button.flat = true
	info.text = "Item: " + bullet_type.capitalize() + "\nCost: " + str(get_bullet_cost(bullet_type)) + "g\nDamage: " + str(get_bullet_damage(bullet_type)) + "g"

	if Globals.bullet_type == bullet_type:
		info.text += "\n[color=green]Selected[/color]"

# Function to get the cost of each bullet type
func get_bullet_cost(bullet_type: String) -> int:
	match bullet_type:
		"lead":
			return 15
		"steel":
			return 150
		"holy_bullet":
			return 500
	return 0  # Default in case of an unknown bullet type

# Function to get the damage of each bullet type
func get_bullet_damage(bullet_type: String) -> int:
	match bullet_type:
		"lead":
			return 15
		"steel":
			return 15
		"holy_bullet":
			return 25
	return 0  # Default in case of an unknown bullet type

# Update for Soldier
func _on_buy_soldier_mouse_entered() -> void:
	info.text = "
	Item: Soldier
	Cost: 25g"

func _on_buy_soldier_button_down() -> void:
	if Globals.gold >= 25 && Globals.soldier_count < Globals.soldier_total:
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
func _on_buy_bullet_button_down() -> void:
	print('leadbullet')
	if "lead" in Globals.bullets_unlocked:
		Globals.bullet_type = 'lead'
		#update_bullet_buttons(buy_bullet, 'lead', [buy_bullet_steel, holy_bullet])
		emit_signal("bought_something")
	elif Globals.gold >= 15:
		Globals.gold -= 15
		Globals.bullets_unlocked.append('lead')
		Globals.bullet_type = 'lead'
		#update_bullet_buttons(buy_bullet, 'lead', [buy_bullet_steel, holy_bullet])
		emit_signal("bought_something")

# Update for Bullet (Steel Bullet)
func _on_buy_bullet_steel_button_down() -> void:
	print('seelbullet')
	if "steel" in Globals.bullets_unlocked:
		Globals.bullet_type = 'steel'
		#update_bullet_buttons(buy_bullet_steel, 'steel', [buy_bullet, holy_bullet])
		emit_signal("bought_something")
	elif Globals.gold >= 150:
		Globals.gold -= 150
		Globals.bullets_unlocked.append('steel')
		Globals.bullet_type = 'steel'
		#update_bullet_buttons(buy_bullet_steel, 'steel', [buy_bullet, holy_bullet])
		emit_signal("bought_something")

# Update for Bullet (Holy Bullet)
func _on_holy_bullet_button_down() -> void:
	print('holybullet')
	if "holy_bullet" in Globals.bullets_unlocked:
		Globals.bullet_type = 'holy_bullet'
		#update_bullet_buttons(holy_bullet, 'holy_bullet', [buy_bullet, buy_bullet_steel])
		emit_signal("bought_something")
	elif Globals.gold >= 500:
		Globals.gold -= 500
		Globals.bullets_unlocked.append('holy_bullet')
		Globals.bullet_type = 'holy_bullet'
		#update_bullet_buttons(holy_bullet, 'holy_bullet', [buy_bullet, buy_bullet_steel])
		emit_signal("bought_something")


func _on_button_button_down() -> void:
	visible = false



func _on_golden_musket_button_down() -> void:
	if !Globals.golden_musket:
		if Globals.gold >= 500:
			Globals.gold -= 500
			emit_signal("bought_something")
			Globals.bullets_unlocked.append('golden_musket')
			Globals.golden_musket = true
		elif "golden_musket" in Globals.bullets_unlocked:
			Globals.golden_musket = true
	else:
		Globals.golden_musket = false
	
	golden_musket.material.set_shader_parameter("toggle_gold", Globals.golden_musket)
 



func _on_golden_sword_button_down() -> void:
	if !Globals.golden_sword:
		if Globals.gold >= 0:
			Globals.gold -= 0
			emit_signal("bought_something")
			Globals.bullets_unlocked.append('golden_sword')
			Globals.golden_sword = true
		elif "golden_sword" in Globals.bullets_unlocked:
			Globals.golden_sword = true
	else:
		Globals.golden_sword = false
	
	golden_sword.material.set_shader_parameter("toggle_gold", Globals.golden_sword)
	
	print(golden_sword.material)


func _on_item_list_item_selected(index: int) -> void:
	match index:
		0:
			_on_buy_bullet_button_down()
		1:
			_on_buy_bullet_steel_button_down()
		2:
			_on_holy_bullet_button_down()
