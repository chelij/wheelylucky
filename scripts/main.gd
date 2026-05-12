# scripts/main.gd
extends Control

@onready var stats_spins_label: Label = $StatsPanel/StatsVBox/StatsSpins
@onready var stats_cycles_label: Label = $StatsPanel/StatsVBox/StatsCycles
@onready var stats_skills_label: Label = $StatsPanel/StatsVBox/StatsSkills
@onready var stats_best_label: Label = $StatsPanel/StatsVBox/StatsBest
@onready var top_coins_display: Label = $TopBar/TopCoinsDisplay
@onready var wheel_node: Control = $Wheel
@onready var spin_button: Button = $Wheel/SpinButton
@onready var wheel_selector_container: HBoxContainer = $WheelSelector/WheelSelectorHBox

const MAX_WHEELS = 10
var wheel_buttons: Array[Button] = []

func _ready():
	# Create 10 wheel selector buttons
	for i in range(MAX_WHEELS):
		var btn = Button.new()
		btn.text = str(i + 1)
		btn.custom_minimum_size = Vector2(36, 36)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(_on_wheel_select.bind(i + 1))
		wheel_selector_container.add_child(btn)
		wheel_buttons.append(btn)

	Game.spin_completed.connect(_on_spin_completed)
	Game.shop_requested.connect(_on_shop_requested)
	Game.game_ended.connect(_on_game_ended)
	Game.coins_changed.connect(_update_top_coins)
	Game.selected_wheel_changed.connect(_update_wheel_selector)

	_update_top_coins(Game.coins)
	_update_stats()
	_update_wheel_selector(Game.selected_wheel)

func _update_top_coins(total: int):
	top_coins_display.text = str(total) + " coins"
	_update_wheel_selector(Game.selected_wheel)

func _update_wheel_selector(_selected):
	for i in range(MAX_WHEELS):
		var btn = wheel_buttons[i]
		var wheel_num = i + 1
		var unlocked = Game.is_wheel_unlocked(wheel_num)
		var can_afford = Game.can_afford_wheel(wheel_num)
		var is_selected = wheel_num == Game.selected_wheel

		btn.disabled = not unlocked
		btn.visible = true

		if is_selected:
			btn.modulate = Color(1, 0.85, 0, 1)
		elif not unlocked:
			btn.modulate = Color(0.3, 0.3, 0.3, 1)
			btn.text = "?"
		elif not can_afford:
			btn.modulate = Color(0.6, 0.3, 0.3, 1)
			btn.text = str(wheel_num)
		else:
			btn.modulate = Color(0.7, 0.9, 0.7, 1)
			btn.text = str(wheel_num)

func _on_wheel_select(wheel_num: int):
	if Game.is_wheel_unlocked(wheel_num) and not wheel_node.is_spinning:
		Game.select_wheel(wheel_num)

func _on_spin_completed():
	_update_stats()

func _on_shop_requested():
	spin_button.disabled = true

	var shop_path = preload("res://scenes/shop.tscn")
	var shop = shop_path.instantiate()
	add_child(shop)

	shop.tree_exited.connect(func(): spin_button.disabled = false)

func _on_game_ended(_final_coins: int):
	var end_path = preload("res://scenes/end_screen.tscn")
	var end_screen = end_path.instantiate()
	add_child(end_screen)

func _update_stats():
	stats_spins_label.text = "Total Spins: " + str(Game.total_spins)
	stats_cycles_label.text = "Cycles: " + str(Game.cycle_count)
	var skill_count = Game.unique_skills.size()
	var level_sum = 0
	for val in Game.skill_levels.values():
		level_sum += val
	stats_skills_label.text = "Skills: " + str(skill_count) + " unique, " + str(level_sum) + " upgrades"
	stats_best_label.text = "Best Score: " + str(SaveManager.get_best_score())
