# scripts/game.gd
extends Node

const WheelConfig = preload("res://scripts/wheel_config.gd")

signal coins_changed(new_total)
signal wheel_changed(current_wheel)
signal spin_completed
signal shop_requested
signal game_ended(final_coins)

# Outcome indices (mirrors WheelConfig)
const IDX_LABEL = 0
const IDX_OP = 1
const IDX_VALUE = 2
const IDX_WEIGHT = 3
const IDX_COLOR = 4

var coins: int = 0:
	set(value):
		coins = max(0, value)
		coins_changed.emit(coins)

var current_wheel: int = 1
var total_spins: int = 0
var cycle_count: int = 1
const MAX_WHEELS: int = 10
const SHOP_INTERVAL: int = 5

# Skill state
var skill_levels: Dictionary = {}
var unique_skills: Array[String] = []

# One-time skill tracking (per run)
var fortune_used: bool = false
var second_wind_used: bool = false

func _ready():
	reset_run()

func reset_run():
	coins = 0
	current_wheel = 1
	total_spins = 0
	cycle_count = 1
	skill_levels = {
		"lucky_charm": 0,
		"quick_spin": 0,
		"iron_skin": 0,
		"coin_magnet": 0,
		"sharp_mind": 0,
	}
	unique_skills = []
	fortune_used = false
	second_wind_used = false
	coins_changed.emit(coins)
	wheel_changed.emit(current_wheel)

func get_wheel_cost(wheel_num: int) -> int:
	return WheelConfig.get_cost(wheel_num)

func can_afford_wheel(wheel_num: int) -> bool:
	var cost = get_wheel_cost(wheel_num)
	if cost == 0:
		return true
	return coins >= cost

func spin_wheel():
	var cost = get_wheel_cost(current_wheel)
	if coins < cost:
		return {"success": false, "reason": "not_enough_coins"}

	coins -= cost
	total_spins += 1

	# Calculate result with skill modifiers
	var result = WheelConfig.calculate_outcome(current_wheel, self)
	var delta = result["delta"]
	var outcome = result["outcome"]

	# Apply result
	coins = max(0, coins + delta)
	coins_changed.emit(coins)

	# Check second wind (once per run)
	if coins == 0 and not second_wind_used:
		if "second_wind" in unique_skills:
			second_wind_used = true
			coins = 10
			coins_changed.emit(coins)

	# Check shop (every 5 spins)
	var show_shop = (total_spins % SHOP_INTERVAL == 0)

	# Check game end (only on wheel 10 jackpot)
	var game_over = false
	var is_jackpot = false
	if current_wheel == MAX_WHEELS:
		if outcome[IDX_OP] == WheelConfig.OP_MULTIPLY and outcome[IDX_LABEL] == "JACKPOT":
			game_over = true
			is_jackpot = true

	# Save best score on game over
	if game_over:
		SaveManager.set_best_score(coins)
		SaveManager.increment_games_played()

	# Advance to next wheel
	if not game_over:
		if current_wheel == MAX_WHEELS:
			current_wheel = 1
			cycle_count += 1
		else:
			current_wheel += 1
		wheel_changed.emit(current_wheel)

	spin_completed.emit()

	if show_shop and not game_over:
		shop_requested.emit()

	if game_over:
		game_ended.emit(coins)

	return {
		"success": true,
		"delta": delta,
		"outcome_label": outcome[IDX_LABEL],
		"outcome_color": outcome[IDX_COLOR],
		"show_shop": show_shop,
		"game_over": game_over,
		"is_jackpot": is_jackpot,
	}

func buy_skill(skill_name: String, cost: int) -> bool:
	if coins < cost:
		return false
	coins -= cost

	if skill_name in skill_levels:
		skill_levels[skill_name] += 1
	elif skill_name not in unique_skills:
		unique_skills.append(skill_name)

	coins_changed.emit(coins)
	return true

func use_fortunes_favor() -> bool:
	if "fortunes_favor" not in unique_skills or fortune_used:
		return false
	fortune_used = true
	return true
