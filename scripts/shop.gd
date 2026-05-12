# scripts/shop.gd
extends CanvasLayer

const SkillManager = preload("res://scripts/skill_manager.gd")

@onready var skills_container: VBoxContainer = $CenterContainer/ShopPanel/ShopVBox/ScrollContainer/SkillsVBox
@onready var coins_label: Label = $CenterContainer/ShopPanel/ShopVBox/CoinsLabel
@onready var continue_button: Button = $CenterContainer/ShopPanel/ShopVBox/ContinueButton

func _ready():
	continue_button.pressed.connect(_on_close)
	Game.coins_changed.connect(_on_coins_changed)
	_populate_skills()
	_on_coins_changed(Game.coins)

func _populate_skills():
	for child in skills_container.get_children():
		child.queue_free()

	for skill in SkillManager.get_all_skills():
		var level = Game.skill_levels.get(skill["id"], 0)
		var owned = skill["id"] in Game.unique_skills

		if owned:
			continue
		if skill["max"] > 0 and level >= skill["max"]:
			continue

		var cost = SkillManager.get_purchase_cost(skill, level)
		var can_afford = Game.coins >= cost

		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 50)

		var name = Label.new()
		name.text = skill["name"]
		if level > 0:
			name.text += " (Lv." + str(level) + ")"
		name.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		row.add_child(name)

		var desc = Label.new()
		desc.text = skill["desc"]
		desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(desc)

		var cost_lbl = Label.new()
		cost_lbl.text = str(cost)
		cost_lbl.size_flags_horizontal = Control.SIZE_SHRINK_END
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(cost_lbl)

		var buy_btn = Button.new()
		buy_btn.text = "Buy"
		buy_btn.disabled = not can_afford
		buy_btn.custom_minimum_size = Vector2(60, 30)
		buy_btn.pressed.connect(_on_buy.bind(skill))
		row.add_child(buy_btn)

		skills_container.add_child(row)

func _on_buy(skill: Dictionary):
	var level = Game.skill_levels.get(skill["id"], 0)
	var cost = SkillManager.get_purchase_cost(skill, level)
	if Game.buy_skill(skill["id"], cost):
		_populate_skills()

func _on_coins_changed(total: int):
	coins_label.text = "Coins: " + str(total)
	_populate_skills()

func _on_close():
	queue_free()
