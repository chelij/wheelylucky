# scripts/main.gd
extends Control

@onready var stats_spins_label: Label = $StatsPanel/StatsVBox/StatsSpins
@onready var stats_cycles_label: Label = $StatsPanel/StatsVBox/StatsCycles
@onready var stats_skills_label: Label = $StatsPanel/StatsVBox/StatsSkills
@onready var stats_best_label: Label = $StatsPanel/StatsVBox/StatsBest
@onready var top_coins_display: Label = $TopBar/TopCoinsDisplay
@onready var wheel_instance: Control = $CenterContainer/WheelHolder/WheelInstance/WheelDrawing
@onready var spin_button: Button = $CenterContainer/WheelHolder/WheelInstance/WheelDrawing/SpinButton

var _shop_open: bool = false

func _ready():
	Game.spin_completed.connect(_on_spin_completed)
	Game.shop_requested.connect(_on_shop_requested)
	Game.game_ended.connect(_on_game_ended)
	Game.coins_changed.connect(_update_top_coins)
	Game.wheel_changed.connect(_update_stats)

	_update_top_coins(Game.coins)
	_update_stats()

func _update_top_coins(total: int):
	top_coins_display.text = str(total) + " coins"

func _on_spin_completed():
	_update_stats()

func _on_shop_requested():
	_shop_open = true
	spin_button.disabled = true

	var shop_path = preload("res://scenes/shop.tscn")
	var shop = shop_path.instantiate()
	add_child(shop)

	# Listen for shop close via tree_exited
	shop.tree_exited.connect(_on_shop_closed)

func _on_shop_closed():
	_shop_open = false
	_update_stats()

func _on_game_ended(final_coins: int):
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
