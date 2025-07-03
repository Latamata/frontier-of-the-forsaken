extends Control

@onready var info: RichTextLabel = $Panel/Info
@onready var golden_musket: Button = $Panel/golden_musket
@onready var golden_sword: Button = $Panel/golden_sword
@onready var item_list: ItemList = $Panel/ItemList
@onready var coin_sound: AudioStreamPlayer2D = $coin_sound

signal bought_something

func _ready() -> void:
	#print(Globals.golden_musket)
	if Globals.golden_musket:
		golden_musket.material.set_shader_parameter("toggle_gold", Globals.golden_musket)
	if Globals.golden_sword:
		golden_sword.material.set_shader_parameter("toggle_gold", Globals.golden_sword)

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
			return 0
		"steel":
			return 90
		"holy_bullet":
			return 180
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
	Cost: 30g"

func _on_buy_soldier_button_down() -> void:
	if Globals.gold >= 30 && Globals.soldier_count < Globals.soldier_total:
		Globals.gold -= 30
		Globals.soldier_count += 1
		emit_signal("bought_something")

# Update for Food
func _on_buy_food_mouse_entered() -> void:
	info.text = "
	Item: Food
	Cost: 25g"

func _on_buy_food_button_down() -> void:
	if Globals.gold >= 25:
		Globals.gold -= 25
		Globals.food += 10
		emit_signal("bought_something")

# Update for Bullet (lead Bullet)
func _on_buy_bullet_button_down() -> void:
	#print('leadbullet')
	if "lead" in Globals.bullets_unlocked:
		Globals.bullet_type = 'lead'
		emit_signal("bought_something")
	elif Globals.gold >= 15:
		Globals.gold -= 15
		Globals.bullets_unlocked.append('lead')
		Globals.bullet_type = 'lead'
		#update_bullet_buttons(buy_bullet, 'lead', [buy_bullet_steel, holy_bullet])
		emit_signal("bought_something")

# Update for Bullet (Steel Bullet)
func _on_buy_bullet_steel_button_down() -> void:
	#print('seelbullet')
	if "steel" in Globals.bullets_unlocked:
		Globals.bullet_type = 'steel'
		#update_bullet_buttons(buy_bullet_steel, 'steel', [buy_bullet, holy_bullet])
		emit_signal("bought_something")
	elif Globals.gold >= 90:
		coin_sound.play()
		Globals.gold -= 90
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

	elif Globals.gold >= 180:
		coin_sound.play()
		Globals.gold -= 180
		Globals.bullets_unlocked.append('holy_bullet')
		Globals.bullet_type = 'holy_bullet'
		#update_bullet_buttons(holy_bullet, 'holy_bullet', [buy_bullet, buy_bullet_steel])
		emit_signal("bought_something")

func _on_button_button_down() -> void:
	visible = false

func _on_golden_musket_button_down() -> void:
	if !Globals.golden_musket:
		if "golden_musket" in Globals.bullets_unlocked:
			Globals.golden_musket = true
		elif Globals.gold >= 200:
			coin_sound.play()
			Globals.gold -= 200
			Globals.bullets_unlocked.append('golden_musket')
			Globals.golden_musket = true
			emit_signal("bought_something")
	golden_musket.material.set_shader_parameter("toggle_gold", Globals.golden_musket)

func _on_golden_sword_button_down() -> void:
	if !Globals.golden_sword:
		if "golden_sword" in Globals.bullets_unlocked:
			Globals.golden_sword = true
		elif Globals.gold >= 150:
			coin_sound.play()
			Globals.gold -= 150
			Globals.bullets_unlocked.append('golden_sword')
			Globals.golden_sword = true
			emit_signal("bought_something")
	golden_sword.material.set_shader_parameter("toggle_gold", Globals.golden_sword)

func _on_item_list_item_selected(index: int) -> void:
	match index:
		0:
			info.text = "Item: Lead Bullet\nCost: %dg\nDamage: %d" % [
				get_bullet_cost("lead"),
				get_bullet_damage("lead")
			]
			_on_buy_bullet_button_down()
		1:
			info.text = "Item: Steel Bullet\nCost: %dg\nDamage: %d" % [
				get_bullet_cost("steel"),
				get_bullet_damage("steel")
			]
			_on_buy_bullet_steel_button_down()
		2:
			info.text = "Item: Holy Bullet\nCost: %dg\nDamage: %d" % [
				get_bullet_cost("holy_bullet"),
				get_bullet_damage("holy_bullet")
			]
			_on_holy_bullet_button_down()

func _on_golden_sword_mouse_entered() -> void:
	info.text = "Item: Golden Sword\nCost: 150g\nEffect: Toggles gold visuals on sword"

func _on_golden_musket_mouse_entered() -> void:
	info.text = "Item: Golden Musket\nCost: 200g\nEffect: Toggles gold visuals on musket"

func hide_or_show(hors):
	visible = hors
