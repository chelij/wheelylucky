# scripts/game.gd
extends Node

const WheelConfig = preload("res://scripts/wheel_config.gd")

signal coins_changed(new_total)
signal wheel_changed(current_wheel)
signal selected_wheel_changed(selected_wheel)
signal spin_completed
signal shop_available_changed(is_available)
signal skills_changed
signal game_ended(final_coins)

const IDX_LABEL = 0
const IDX_OP = 1
const IDX_VALUE = 2
const IDX_WEIGHT = 3
const IDX_COLOR = 4

var coins: int = 0:
	set(value):
		coins = max(0, value)
		coins_changed.emit(coins)

# highest_unlocked tracks the highest wheel the player has reached (and spun)
var highest_unlocked: int = 1
var selected_wheel: int = 1
var total_spins: int = 0
var cycle_count: int = 1
var shop_available: bool = false
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
	highest_unlocked = 1
	selected_wheel = 1
	total_spins = 0
	cycle_count = 1
	shop_available = false
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
	wheel_changed.emit(selected_wheel)
	selected_wheel_changed.emit(selected_wheel)
	shop_available_changed.emit(shop_available)
	skills_changed.emit()

func get_wheel_cost(wheel_num: int) -> int:
	return WheelConfig.get_cost(wheel_num)

func can_afford_wheel(wheel_num: int) -> bool:
	var cost = get_wheel_cost(wheel_num)
	if cost == 0:
		return true
	return coins >= cost

func is_wheel_unlocked(wheel_num: int) -> bool:
	return wheel_num <= highest_unlocked

func select_wheel(wheel_num: int):
	if wheel_num < 1 or wheel_num > MAX_WHEELS:
		return
	if not is_wheel_unlocked(wheel_num):
		return
	selected_wheel = wheel_num
	selected_wheel_changed.emit(selected_wheel)
	wheel_changed.emit(selected_wheel)

func begin_spin() -> Dictionary:
	var wheel_num = selected_wheel
	var cost = get_wheel_cost(wheel_num)
	if coins < cost:
		return {"success": false, "reason": "not_enough_coins"}

	coins -= cost
	total_spins += 1
	coins_changed.emit(coins)

	# Unlock next wheel if we reached a new high
	if wheel_num >= highest_unlocked and wheel_num < MAX_WHEELS:
		highest_unlocked = wheel_num + 1

	return {"success": true, "wheel_num": wheel_num, "cost": cost}

func spin_wheel(pre_chosen_outcome = null):
	var wheel_num = selected_wheel

	# Use the pre-determined visual outcome so pointer matches result
	var outcome
	if pre_chosen_outcome != null:
		outcome = pre_chosen_outcome
	else:
		# Fallback: calculate independently (shouldn't happen in normal flow)
		var calc = WheelConfig.calculate_outcome(wheel_num, self)
		outcome = calc["outcome"]
		var delta = calc["delta"]
		coins = max(0, coins + delta)
		coins_changed.emit(coins)
		# Skip normal delta calc since we already applied it
		return _finish_spin(outcome, delta)

	# Apply result — outcome already has skill modifiers baked in from wheel.gd
	if outcome == null:
		return {"success": false, "reason": "no_outcome"}

	var delta = WheelConfig.apply_outcome(outcome, coins, self)
	coins = max(0, coins + delta)
	coins_changed.emit(coins)

	return _finish_spin(outcome, delta)

func _finish_spin(outcome, delta: int) -> Dictionary:
	var spun_wheel = selected_wheel

	# Check second wind (once per run)
	if coins == 0 and not second_wind_used:
		if "second_wind" in unique_skills:
			second_wind_used = true
			coins = 10
			coins_changed.emit(coins)

	# Check game end (only on wheel 10 jackpot)
	var game_over = false
	var is_jackpot = false
	if spun_wheel == MAX_WHEELS:
		if outcome[IDX_OP] == WheelConfig.OP_MULTIPLY and outcome[IDX_LABEL] == "JACKPOT":
			game_over = true
			is_jackpot = true

	# Make shop button available every 5 completed spins.
	if total_spins > 0 and total_spins % SHOP_INTERVAL == 0 and not game_over:
		shop_available = true
		shop_available_changed.emit(shop_available)

	if spun_wheel == MAX_WHEELS and not game_over:
		cycle_count += 1
		selected_wheel = 1
		selected_wheel_changed.emit(selected_wheel)
		wheel_changed.emit(selected_wheel)

	# Save best score on game over
	if game_over:
		SaveManager.set_best_score(coins)
		SaveManager.increment_games_played()

	spin_completed.emit()

	if game_over:
		game_ended.emit(coins)

	return {
		"success": true,
		"delta": delta,
		"outcome_label": outcome[IDX_LABEL],
		"outcome_color": outcome[IDX_COLOR],
		"show_shop": shop_available,
		"game_over": game_over,
		"is_jackpot": is_jackpot,
	}

func consume_shop_available() -> bool:
	if not shop_available:
		return false
	shop_available = false
	shop_available_changed.emit(shop_available)
	return true

func buy_skill(skill_name: String, cost: int) -> bool:
	if coins < cost:
		return false
	coins -= cost

	if skill_name in skill_levels:
		skill_levels[skill_name] += 1
	elif skill_name not in unique_skills:
		unique_skills.append(skill_name)

	coins_changed.emit(coins)
	skills_changed.emit()
	return true

func use_fortunes_favor() -> bool:
	if "fortunes_favor" not in unique_skills or fortune_used:
		return false
	fortune_used = true
	return true
