# scripts/game.gd
extends Node

const WheelConfig = preload("res://scripts/wheel_config.gd")
const SkillManager = preload("res://scripts/skill_manager.gd")
const SkillEffects = preload("res://scripts/skill_effects.gd")

signal coins_changed(new_total)
signal wheel_changed(current_wheel)
signal selected_wheel_changed(selected_wheel)
signal spin_completed
signal shop_available_changed(is_available)
signal skills_changed
signal game_ended(final_coins, elapsed_seconds)


var coins: int = 0:
	set(value):
		coins = max(0, value)
		if suppress_coin_changed:
			pending_coin_changed_emit = true
		else:
			coins_changed.emit(coins)

var selected_wheel: int = 1
var total_spins: int = 0
var cycle_count: int = 1
var shop_available: bool = false
var pending_shop_skills: Array[Dictionary] = []
var last_spin_cost: int = 0
var _current_spin_wheel: int = 0
var shop_miss_count: int = 0
var momentum_stacks: int = 0
const MAX_WHEELS: int = 10
var run_color_counts: Dictionary = {}
var run_coins_earned: int = 0
var run_coins_spent: int = 0
var run_spin_costs: int = 0
var run_shop_spent: int = 0
var run_base_payout: int = 0
var run_skill_payout: int = 0
var run_highest_wheel: int = 1
var dev_coin_gain_multiplier: float = 1.0
var suppress_coin_changed := false
var pending_coin_changed_emit := false

# Skill state
var skill_levels: Dictionary = {}
var unique_skills: Array[String] = []
var bought_skill_order: Array[String] = []

var run_start_time_msec: int = 0

func _ready():
	reset_run()

func reset_run(record_start: bool = false):
	coins = 0
	selected_wheel = 1
	total_spins = 0
	cycle_count = 1
	shop_available = false
	pending_shop_skills = []
	last_spin_cost = 0
	shop_miss_count = 0
	momentum_stacks = 0
	skill_levels = {
		"lucky_charm": 0,
		"quick_spin": 0,
		"discount_card": 0,
		"coin_magnet": 0,
		"sharp_mind": 0,
		"free_gift": 0,
		"shop_savvy": 0,
		"market_bell": 0,
		"collector": 0,
	}
	unique_skills = []
	bought_skill_order = []
	run_color_counts = _empty_color_counts()
	run_coins_earned = 0
	run_coins_spent = 0
	run_spin_costs = 0
	run_shop_spent = 0
	run_base_payout = 0
	run_skill_payout = 0
	run_highest_wheel = 1
	run_start_time_msec = Time.get_ticks_msec()
	suppress_coin_changed = false
	pending_coin_changed_emit = false
	if record_start:
		SaveManager.increment_games_started()
		SaveManager.clear_saved_run()
	wheel_changed.emit(selected_wheel)
	selected_wheel_changed.emit(selected_wheel)
	shop_available_changed.emit(shop_available)
	skills_changed.emit()

func _empty_color_counts() -> Dictionary:
	return {
		"green": 0,
		"red": 0,
		"gold": 0,
		"grey": 0,
		"jackpot": 0,
	}

func get_wheel_cost(wheel_num: int) -> int:
	var cost = float(WheelConfig.get_cost(wheel_num))
	var discount_level = skill_levels.get("discount_card", 0)
	cost *= max(0.0, 1.0 - SkillEffects.DISCOUNT_CARD_SPIN_COST_DISCOUNT_PER_LEVEL * discount_level)
	if "double_down" in unique_skills and wheel_num != MAX_WHEELS:
		cost *= 2.0
	return int(round(cost))

func can_afford_wheel(wheel_num: int) -> bool:
	var cost = get_wheel_cost(wheel_num)
	if cost == 0:
		return true
	return coins >= cost

func is_wheel_unlocked(wheel_num: int) -> bool:
	return wheel_num == 1 or can_afford_wheel(wheel_num)

func select_wheel(wheel_num: int):
	if wheel_num < 1 or wheel_num > MAX_WHEELS:
		return
	if not is_wheel_unlocked(wheel_num):
		return
	selected_wheel = wheel_num
	run_highest_wheel = max(run_highest_wheel, selected_wheel)
	selected_wheel_changed.emit(selected_wheel)
	wheel_changed.emit(selected_wheel)

func begin_spin() -> Dictionary:
	var wheel_num = selected_wheel
	var cost = get_wheel_cost(wheel_num)
	if coins < cost:
		return {"success": false, "reason": "not_enough_coins"}

	if shop_available:
		shop_available = false
		pending_shop_skills = []
		shop_available_changed.emit(shop_available)
		shop_miss_count = 0

	coins -= cost
	last_spin_cost = cost
	_current_spin_wheel = wheel_num
	total_spins += 1
	run_coins_spent += cost
	run_spin_costs += cost
	run_highest_wheel = max(run_highest_wheel, wheel_num)

	return {"success": true, "wheel_num": wheel_num, "cost": cost}

func spin_wheel(pre_chosen_outcome = null):
	var wheel_num = _current_spin_wheel if _current_spin_wheel > 0 else selected_wheel
	var coins_before_base := coins

	# Use the pre-determined visual outcome so pointer matches result
	var outcome
	if pre_chosen_outcome != null:
		outcome = pre_chosen_outcome
	else:
		# Fallback: calculate independently (shouldn't happen in normal flow)
		var calc = WheelConfig.calculate_outcome(wheel_num, self)
		outcome = calc["outcome"]
		var delta = calc["delta"]
		var coin_events := _build_post_outcome_coin_events(outcome, delta)
		coins = max(0, coins + delta)
		if delta > 0:
			run_coins_earned += delta
			run_base_payout += delta
		# Skip normal delta calc since we already applied it
		return _finish_spin(outcome, delta, coin_events, coins_before_base)

	# Apply result — outcome already has skill modifiers baked in from wheel.gd
	if outcome == null:
		return {"success": false, "reason": "no_outcome"}

	var delta = WheelConfig.apply_outcome(outcome, coins, self)
	if delta > 0 and dev_coin_gain_multiplier > 1.0:
		delta = int(round(float(delta) * dev_coin_gain_multiplier))
	coins = max(0, coins + delta)
	if delta > 0:
		run_coins_earned += delta
		run_base_payout += delta

	var coin_events := _build_post_outcome_coin_events(outcome, delta)
	return _finish_spin(outcome, delta, coin_events, coins_before_base)

func _build_post_outcome_coin_events(outcome, base_delta: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if outcome == null:
		return events

	if outcome[WheelConfig.IDX_OP] == WheelConfig.OP_ADD:
		var magnet_level := int(skill_levels.get("coin_magnet", 0))
		if magnet_level > 0 and base_delta > 0:
			var amount := int(round(float(base_delta) * SkillEffects.COIN_MAGNET_ADD_VALUE_PER_LEVEL * magnet_level))
			_add_skill_coin_event(events, "coin_magnet", amount)

	if outcome[WheelConfig.IDX_OP] == WheelConfig.OP_MULTIPLY:
		var sharp_level := int(skill_levels.get("sharp_mind", 0))
		if sharp_level > 0 and base_delta > 0:
			var amount := int(round(float(base_delta) * SkillEffects.SHARP_MIND_MULTIPLY_VALUE_PER_LEVEL * sharp_level))
			_add_skill_coin_event(events, "sharp_mind", amount)

	return events

func _add_skill_coin_event(events: Array[Dictionary], skill_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var skill := SkillManager.get_skill_by_id(skill_id)
	events.append({
		"skill_id": skill_id,
		"skill_name": skill.get("name", skill_id),
		"delta": amount,
	})

func _finish_spin(outcome, delta: int, coin_events: Array[Dictionary] = [], coins_before_base: int = 0) -> Dictionary:
	if outcome == null:
		return {"success": false, "reason": "null_outcome"}
	var spun_wheel = _current_spin_wheel if _current_spin_wheel > 0 else selected_wheel
	suppress_coin_changed = true
	var ordered_coin_events := _build_ordered_skill_coin_events(outcome, coin_events)
	_apply_coin_events_to_state(ordered_coin_events)

	# Check game end (only on wheel 10 jackpot)
	var game_over = false
	var is_jackpot = false
	if spun_wheel == MAX_WHEELS:
		if outcome[WheelConfig.IDX_LABEL] == "JACKPOT":
			game_over = true
			is_jackpot = true

	_update_momentum(outcome)
	_roll_shop_after_spin(game_over)
	_record_spin_color(outcome)

	if spun_wheel == MAX_WHEELS and not game_over:
		cycle_count += 1

	# Wheel affordability check deferred to caller after all effects finish

	# Save best score on game over
	if game_over:
		SaveManager.set_best_score(coins)
		SaveManager.increment_games_won()
		SaveManager.add_run_history(get_run_summary())
		SaveManager.clear_saved_run()
	else:
		save_current_run()

	spin_completed.emit()

	var resolution_events := _build_resolution_events(outcome, delta, coins_before_base, ordered_coin_events)

	return {
		"success": true,
		"delta": delta,
		"outcome_label": outcome[WheelConfig.IDX_LABEL],
		"outcome_color": outcome[WheelConfig.IDX_COLOR],
		"spun_wheel": spun_wheel,
		"show_shop": shop_available,
		"game_over": game_over,
		"is_jackpot": is_jackpot,
		"coin_events": ordered_coin_events,
		"resolution_events": resolution_events,
	}

func _build_ordered_skill_coin_events(outcome, base_events: Array[Dictionary]) -> Array[Dictionary]:
	var sorted_base := _sort_skill_coin_events(base_events)
	var ordered: Array[Dictionary] = []
	var pending_by_id := {}
	for event in sorted_base:
		pending_by_id[str(event.get("skill_id", ""))] = event.duplicate(true)

	var temp_total := coins
	var free_gift_refund := _apply_free_gift(outcome)
	if free_gift_refund > 0:
		pending_by_id["free_gift"] = _make_skill_coin_event("free_gift", free_gift_refund)

	for skill_id in bought_skill_order:
		if pending_by_id.has(skill_id):
			var event := pending_by_id[skill_id]
			ordered.append(event)
			temp_total += int(event.get("delta", 0))
			pending_by_id.erase(skill_id)
			continue
		if skill_id == "second_wind" and "second_wind" in unique_skills and temp_total < last_spin_cost and randf() < SkillEffects.SECOND_WIND_REFUND_CHANCE:
			var second_event := _make_skill_coin_event("second_wind", last_spin_cost)
			ordered.append(second_event)
			temp_total += last_spin_cost
			continue
		if skill_id == "banker" and "banker" in unique_skills and temp_total > 0:
			var interest := int(round(float(temp_total) * SkillEffects.BANKER_INTEREST_RATE))
			var banker_event := _make_skill_coin_event("banker", interest)
			ordered.append(banker_event)
			temp_total += interest

	for event in pending_by_id.values():
		if event is Dictionary:
			ordered.append((event as Dictionary).duplicate(true))
	return ordered

func _make_skill_coin_event(skill_id: String, amount: int) -> Dictionary:
	var skill := SkillManager.get_skill_by_id(skill_id)
	return {
		"skill_id": skill_id,
		"skill_name": skill.get("name", skill_id),
		"delta": amount,
	}

func _sort_skill_coin_events(events: Array[Dictionary]) -> Array[Dictionary]:
	var sorted: Array[Dictionary] = []
	for event in events:
		if event is Dictionary:
			sorted.append(event.duplicate(true))
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _skill_order_index(str(a.get("skill_id", ""))) < _skill_order_index(str(b.get("skill_id", "")))
	)
	return sorted

func _skill_order_index(skill_id: String) -> int:
	var index := bought_skill_order.find(skill_id)
	return index if index >= 0 else 999999

func _build_resolution_events(outcome, delta: int, coins_before_base: int, coin_events: Array[Dictionary]) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var display_total := coins_before_base
	if delta != 0:
		display_total = max(0, display_total + delta)
		events.append({
			"type": "base",
			"delta": delta,
			"display_total": display_total,
			"outcome_label": outcome[WheelConfig.IDX_LABEL],
			"outcome_color": outcome[WheelConfig.IDX_COLOR],
			"spun_wheel": selected_wheel,
		})
	for event in coin_events:
		if not event is Dictionary:
			continue
		display_total += int(event.get("delta", 0))
		event["display_total"] = display_total
		events.append(event)
	return events

func _apply_coin_events_to_state(coin_events: Array[Dictionary]) -> void:
	for event in coin_events:
		if not event is Dictionary:
			continue
		var amount := int(event.get("delta", 0))
		if amount <= 0:
			continue
		coins += amount
		run_coins_earned += amount
		run_skill_payout += amount

func flush_coin_changed() -> void:
	suppress_coin_changed = false
	if pending_coin_changed_emit:
		pending_coin_changed_emit = false
		coins_changed.emit(coins)

func _update_momentum(outcome) -> void:
	if "momentum" not in unique_skills:
		return
	if outcome[WheelConfig.IDX_OP] == WheelConfig.OP_ADD:
		var max_stacks := int(SkillEffects.MOMENTUM_MAX_BONUS_SLOTS / SkillEffects.MOMENTUM_POSITIVE_SLOTS_PER_STACK)
		momentum_stacks = min(
			max_stacks,
			momentum_stacks + 1
		)
	elif outcome[WheelConfig.IDX_OP] == WheelConfig.OP_SUBTRACT:
		momentum_stacks = 0

func _apply_free_gift(outcome) -> int:
	if outcome[WheelConfig.IDX_OP] not in [WheelConfig.OP_NONE, WheelConfig.OP_SUBTRACT] or outcome[WheelConfig.IDX_LABEL] == "JACKPOT":
		return 0
	var free_gift = skill_levels.get("free_gift", 0)
	if free_gift <= 0:
		return 0
	var refund := int(round(float(last_spin_cost) * SkillEffects.FREE_GIFT_REFUND_PER_LEVEL * free_gift))
	return refund

func _record_spin_color(outcome) -> void:
	var color_key := get_color_key_for_outcome(outcome)
	run_color_counts[color_key] = int(run_color_counts.get(color_key, 0)) + 1
	SaveManager.add_spin(color_key)

func get_color_key_for_outcome(outcome) -> String:
	if outcome[WheelConfig.IDX_LABEL] == "JACKPOT":
		return "jackpot"
	match outcome[WheelConfig.IDX_OP]:
		WheelConfig.OP_ADD:
			return "green"
		WheelConfig.OP_SUBTRACT:
			return "red"
		WheelConfig.OP_MULTIPLY:
			return "gold"
		_:
			return "grey"

func _roll_shop_after_spin(game_over: bool) -> void:
	if game_over:
		return
	var market_level = skill_levels.get("market_bell", 0)
	var step = SkillEffects.MARKET_BELL_BASE_SHOP_CHANCE + SkillEffects.MARKET_BELL_SHOP_CHANCE_PER_LEVEL * market_level
	var chance = min(1.0, step * float(shop_miss_count + 1))
	if randf() < chance:
		var offered_skills = _roll_shop_skills()
		if _has_affordable_shop_skill(offered_skills):
			pending_shop_skills = offered_skills
			shop_available = true
			shop_miss_count = 0
		else:
			pending_shop_skills = []
			shop_available = false
	else:
		pending_shop_skills = []
		shop_available = false
		shop_miss_count += 1
	shop_available_changed.emit(shop_available)

func _has_affordable_shop_skill(skills: Array[Dictionary]) -> bool:
	for skill in skills:
		var level = skill_levels.get(skill["id"], 0)
		var cost_level = unique_skills.size() if skill["max"] == 0 else level
		if coins >= _get_discounted_shop_cost(skill, cost_level):
			return true
	return false

func _get_discounted_shop_cost(skill: Dictionary, level: int) -> int:
	var base_cost = SkillManager.get_purchase_cost(skill, level)
	var savvy_level = skill_levels.get("shop_savvy", 0)
	return max(1, int(round(float(base_cost) * max(0.0, 1.0 - SkillEffects.SHOP_SAVVY_PRICE_DISCOUNT_PER_LEVEL * savvy_level))))

func _roll_shop_skills() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var upgradeables: Array[Dictionary] = []
	var uniques: Array[Dictionary] = []

	for skill in SkillManager.UPGRADEABLE_SKILLS:
		var level = skill_levels.get(skill["id"], 0)
		if skill["max"] < 0 or level < skill["max"]:
			upgradeables.append(skill)

	for skill in SkillManager.UNIQUE_SKILLS:
		if skill["id"] not in unique_skills:
			uniques.append(skill)

	var collector_level = skill_levels.get("collector", 0)
	var unique_chance = min(1.0, 0.5 + SkillEffects.COLLECTOR_UNIQUE_CHANCE_PER_LEVEL * collector_level) * pow(0.5, unique_skills.size())
	if uniques.size() > 0 and randf() < unique_chance:
		choices.append(uniques[randi() % uniques.size()])

	var skill_choice_count = 4 if "golden_ticket" in unique_skills else 3
	while choices.size() < skill_choice_count and upgradeables.size() > 0:
		var picked = _pick_weighted_upgradeable(upgradeables)
		choices.append(picked)
		upgradeables.erase(picked)

	return choices

func _pick_weighted_upgradeable(skills: Array[Dictionary]) -> Dictionary:
	var total_weight = 0
	for skill in skills:
		var level = skill_levels.get(skill["id"], 0)
		var remaining_levels = 10 if skill["max"] < 0 else max(1, int(skill["max"]) - level)
		total_weight += max(1, remaining_levels * remaining_levels)

	var roll = randi_range(1, total_weight)
	var cursor = 0
	for skill in skills:
		var level = skill_levels.get(skill["id"], 0)
		var remaining_levels = 10 if skill["max"] < 0 else max(1, int(skill["max"]) - level)
		cursor += max(1, remaining_levels * remaining_levels)
		if roll <= cursor:
			return skill
	return skills[0]

func select_highest_affordable_at_or_below_selected() -> void:
	if can_afford_wheel(selected_wheel):
		return
	var fallback_wheel = 1
	for wheel_num in range(selected_wheel - 1, 0, -1):
		if can_afford_wheel(wheel_num):
			fallback_wheel = wheel_num
			break
	if fallback_wheel == selected_wheel:
		return
	selected_wheel = fallback_wheel
	selected_wheel_changed.emit(selected_wheel)
	wheel_changed.emit(selected_wheel)

func get_elapsed_seconds() -> int:
	if run_start_time_msec <= 0:
		return 0
	return int(max(0, Time.get_ticks_msec() - run_start_time_msec) / 1000)

func get_highest_affordable_wheel() -> int:
	for wheel_num in range(MAX_WHEELS, 0, -1):
		if is_wheel_unlocked(wheel_num):
			return wheel_num
	return 1

func consume_shop_available() -> bool:
	if not shop_available:
		return false
	shop_available = false
	shop_available_changed.emit(shop_available)
	return true

func get_pending_shop_skills() -> Array[Dictionary]:
	return pending_shop_skills.duplicate()

func set_pending_shop_skill_ids(ids: Array) -> void:
	pending_shop_skills = _pending_shop_skills_from_ids(ids)

func buy_skill(skill_name: String, cost: int) -> bool:
	if coins < cost:
		return false
	coins -= cost
	run_coins_spent += cost
	run_shop_spent += cost

	if skill_name not in bought_skill_order:
		bought_skill_order.append(skill_name)

	if skill_name in skill_levels:
		skill_levels[skill_name] += 1
	elif skill_name not in unique_skills:
		unique_skills.append(skill_name)

	SaveManager.add_skill_level(skill_name)
	save_current_run()
	skills_changed.emit()
	return true

func save_current_run() -> void:
	SaveManager.save_run({
		"coins": coins,
		"selected_wheel": selected_wheel,
		"total_spins": total_spins,
		"cycle_count": cycle_count,
		"shop_available": shop_available,
		"pending_shop_skill_ids": _pending_shop_skill_ids(),
		"last_spin_cost": last_spin_cost,
		"shop_miss_count": shop_miss_count,
		"momentum_stacks": momentum_stacks,
		"skill_levels": skill_levels.duplicate(true),
		"unique_skills": unique_skills.duplicate(),
		"bought_skill_order": bought_skill_order.duplicate(),
		"run_color_counts": run_color_counts.duplicate(true),
		"run_coins_earned": run_coins_earned,
		"run_coins_spent": run_coins_spent,
		"run_spin_costs": run_spin_costs,
		"run_shop_spent": run_shop_spent,
		"run_base_payout": run_base_payout,
		"run_skill_payout": run_skill_payout,
		"run_highest_wheel": run_highest_wheel,
		"elapsed_seconds": get_elapsed_seconds(),
	})

func get_run_summary() -> Dictionary:
	return {
		"timestamp": Time.get_datetime_string_from_system(false, true),
		"final_coins": coins,
		"spins": total_spins,
		"elapsed_seconds": get_elapsed_seconds(),
		"highest_wheel": max(run_highest_wheel, selected_wheel),
		"skills_bought": _get_skill_purchase_count(),
		"coins_earned": run_coins_earned,
		"coins_spent": run_coins_spent,
		"spin_costs": run_spin_costs,
		"shop_spent": run_shop_spent,
		"base_payout": run_base_payout,
		"skill_payout": run_skill_payout,
		"color_counts": run_color_counts.duplicate(true),
		"skills": _get_owned_skill_summaries(),
	}

func _get_skill_purchase_count() -> int:
	var total := 0
	for skill_id in bought_skill_order:
		total += 1 if skill_id in unique_skills else int(skill_levels.get(skill_id, 0))
	return total

func _get_owned_skill_summaries() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for skill_id in bought_skill_order:
		var skill := SkillManager.get_skill_by_id(skill_id)
		if skill.is_empty():
			continue
		var is_unique := skill_id in unique_skills
		var level := 1 if is_unique else int(skill_levels.get(skill_id, 0))
		if level > 0:
			items.append({"id": skill_id, "name": skill.get("name", skill_id), "level": level, "unique": is_unique})
	return items

func load_saved_run() -> bool:
	var state := SaveManager.load_run()
	if state.is_empty():
		return false
	coins = int(state.get("coins", 0))
	selected_wheel = int(state.get("selected_wheel", 1))
	total_spins = int(state.get("total_spins", 0))
	cycle_count = int(state.get("cycle_count", 1))
	shop_available = bool(state.get("shop_available", false))
	pending_shop_skills = _pending_shop_skills_from_ids(state.get("pending_shop_skill_ids", []))
	last_spin_cost = int(state.get("last_spin_cost", 0))
	shop_miss_count = int(state.get("shop_miss_count", 0))
	momentum_stacks = int(state.get("momentum_stacks", 0))
	skill_levels = state.get("skill_levels", skill_levels)
	unique_skills = _to_string_array(state.get("unique_skills", []))
	bought_skill_order = _to_string_array(state.get("bought_skill_order", []))
	run_color_counts = state.get("run_color_counts", _empty_color_counts())
	for color_key in _empty_color_counts().keys():
		if not run_color_counts.has(color_key):
			run_color_counts[color_key] = 0
	run_coins_earned = int(state.get("run_coins_earned", 0))
	run_coins_spent = int(state.get("run_coins_spent", 0))
	run_spin_costs = int(state.get("run_spin_costs", 0))
	run_shop_spent = int(state.get("run_shop_spent", 0))
	run_base_payout = int(state.get("run_base_payout", 0))
	run_skill_payout = int(state.get("run_skill_payout", 0))
	run_highest_wheel = int(state.get("run_highest_wheel", selected_wheel))
	var elapsed_msec := int(state.get("elapsed_seconds", 0)) * 1000
	run_start_time_msec = Time.get_ticks_msec() - elapsed_msec
	suppress_coin_changed = false
	pending_coin_changed_emit = false
	wheel_changed.emit(selected_wheel)
	selected_wheel_changed.emit(selected_wheel)
	shop_available_changed.emit(shop_available)
	skills_changed.emit()
	return true

func _to_string_array(value) -> Array[String]:
	var result: Array[String] = []
	for item in value:
		result.append(str(item))
	return result

func _to_skill_dict_array(value) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in value:
		if item is Dictionary:
			result.append(item.duplicate(true))
	return result

func _pending_shop_skill_ids() -> Array[String]:
	var ids: Array[String] = []
	for item in pending_shop_skills:
		if item is Dictionary:
			ids.append(str(item.get("id", "")))
	return ids

func _pending_shop_skills_from_ids(value) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in value:
		var skill := SkillManager.get_skill_by_id(str(item))
		if not skill.is_empty():
			result.append(skill.duplicate(true))
	return result
