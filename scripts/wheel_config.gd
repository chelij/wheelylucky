# scripts/wheel_config.gd
extends RefCounted

# Operation types
const OP_ADD = 0
const OP_SUBTRACT = 1
const OP_MULTIPLY = 2
const OP_DIVIDE = 3
const OP_NONE = 4

# Colors
const POSITIVE = Color(0.2, 0.8, 0.3)
const SAFE = Color(0.5, 0.5, 0.5)
const NEGATIVE = Color(0.8, 0.2, 0.2)
const MULTIPLY = Color(0.8, 0.7, 0.1)
const DIVIDE = Color(0.6, 0.3, 0.8)
const JACKPOT = Color(1.0, 0.85, 0.0)

# Outcome format: [label, op_type, value, weight, color]
# Helper to create outcome arrays
static func _mo(label, op_type, value, weight, color):
	return [label, op_type, value, weight, color]

# Wheel data — weights sum to 100 per wheel
static func _get_wheel_1():
	return [
		_mo("+1", OP_ADD, 1.0, 50.0, POSITIVE),
		_mo("0", OP_NONE, 0.0, 50.0, SAFE),
	]

static func _get_wheel_2():
	return [
		_mo("+10", OP_ADD, 10.0, 45.0, POSITIVE),
		_mo("0", OP_NONE, 0.0, 35.0, SAFE),
		_mo("-5", OP_SUBTRACT, 5.0, 20.0, NEGATIVE),
	]

static func _get_wheel_3():
	return [
		_mo("+15", OP_ADD, 15.0, 35.0, POSITIVE),
		_mo("0", OP_NONE, 0.0, 30.0, SAFE),
		_mo("-8", OP_SUBTRACT, 8.0, 35.0, NEGATIVE),
	]

static func _get_wheel_4():
	return [
		_mo("+20", OP_ADD, 20.0, 30.0, POSITIVE),
		_mo("x2", OP_MULTIPLY, 2.0, 10.0, MULTIPLY),
		_mo("0", OP_NONE, 0.0, 25.0, SAFE),
		_mo("-12", OP_SUBTRACT, 12.0, 35.0, NEGATIVE),
	]

static func _get_wheel_5():
	return [
		_mo("+25", OP_ADD, 25.0, 25.0, POSITIVE),
		_mo("x2", OP_MULTIPLY, 2.0, 15.0, MULTIPLY),
		_mo("0", OP_NONE, 0.0, 20.0, SAFE),
		_mo("-15", OP_SUBTRACT, 15.0, 40.0, NEGATIVE),
	]

static func _get_wheel_6():
	return [
		_mo("+30", OP_ADD, 30.0, 25.0, POSITIVE),
		_mo("x3", OP_MULTIPLY, 3.0, 10.0, MULTIPLY),
		_mo("/2", OP_DIVIDE, 2.0, 10.0, DIVIDE),
		_mo("0", OP_NONE, 0.0, 15.0, SAFE),
		_mo("-20", OP_SUBTRACT, 20.0, 40.0, NEGATIVE),
	]

static func _get_wheel_7():
	return [
		_mo("+35", OP_ADD, 35.0, 20.0, POSITIVE),
		_mo("x3", OP_MULTIPLY, 3.0, 15.0, MULTIPLY),
		_mo("/2", OP_DIVIDE, 2.0, 15.0, DIVIDE),
		_mo("0", OP_NONE, 0.0, 10.0, SAFE),
		_mo("-25", OP_SUBTRACT, 25.0, 40.0, NEGATIVE),
	]

static func _get_wheel_8():
	return [
		_mo("+40", OP_ADD, 40.0, 15.0, POSITIVE),
		_mo("x3", OP_MULTIPLY, 3.0, 15.0, MULTIPLY),
		_mo("x5", OP_MULTIPLY, 5.0, 5.0, MULTIPLY),
		_mo("/2", OP_DIVIDE, 2.0, 15.0, DIVIDE),
		_mo("0", OP_NONE, 0.0, 10.0, SAFE),
		_mo("-30", OP_SUBTRACT, 30.0, 40.0, NEGATIVE),
	]

static func _get_wheel_9():
	return [
		_mo("+50", OP_ADD, 50.0, 12.0, POSITIVE),
		_mo("x3", OP_MULTIPLY, 3.0, 12.0, MULTIPLY),
		_mo("x5", OP_MULTIPLY, 5.0, 8.0, MULTIPLY),
		_mo("/2", OP_DIVIDE, 2.0, 18.0, DIVIDE),
		_mo("0", OP_NONE, 0.0, 9.0, SAFE),
		_mo("-40", OP_SUBTRACT, 40.0, 41.0, NEGATIVE),
	]

static func _get_wheel_10():
	return [
		_mo("JACKPOT", OP_MULTIPLY, 10.0, 1.0, JACKPOT),
		_mo("-50%", OP_DIVIDE, 2.0, 99.0, NEGATIVE),
	]

# Outcome indices
const IDX_LABEL = 0
const IDX_OP = 1
const IDX_VALUE = 2
const IDX_WEIGHT = 3
const IDX_COLOR = 4

static func get_cost(wheel_num: int) -> int:
	if wheel_num == 1:
		return 0
	match wheel_num:
		2: return 5
		3: return 8
		4: return 12
		5: return 17
		6: return 23
		7: return 30
		8: return 38
		9: return 47
		10: return 60
	return 60

static func get_outcomes(wheel_num: int):
	var raw_outcomes
	match wheel_num:
		1: raw_outcomes = _get_wheel_1()
		2: raw_outcomes = _get_wheel_2()
		3: raw_outcomes = _get_wheel_3()
		4: raw_outcomes = _get_wheel_4()
		5: raw_outcomes = _get_wheel_5()
		6: raw_outcomes = _get_wheel_6()
		7: raw_outcomes = _get_wheel_7()
		8: raw_outcomes = _get_wheel_8()
		9: raw_outcomes = _get_wheel_9()
		10: raw_outcomes = _get_wheel_10()
		_: raw_outcomes = _get_wheel_1()

	# Return deep copies
	var copies = []
	for o in raw_outcomes:
		copies.append([o[0], o[1], o[2], o[3], o[4]])
	return copies

static func calculate_outcome(wheel_num: int, game):
	var outcomes = get_outcomes(wheel_num)
	outcomes = apply_skill_modifiers(outcomes, game)
	var chosen = weighted_random(outcomes)

	# Fortune's Favor: reroll if negative
	if chosen[IDX_OP] in [OP_SUBTRACT, OP_DIVIDE]:
		if game.use_fortunes_favor():
			var safe = []
			for o in outcomes:
				if o[IDX_OP] not in [OP_SUBTRACT, OP_DIVIDE]:
					safe.append(o)
			if safe.size() > 0:
				chosen = weighted_random(safe)

	var delta = apply_outcome(chosen, game.coins, game)
	return {"delta": delta, "outcome": chosen}

static func apply_skill_modifiers(outcomes, game):
	# Lucky Charm: shift weight from 0/- to positive
	var lucky_level = game.skill_levels.get("lucky_charm", 0)
	if lucky_level > 0:
		var shift_total = 0.2 * lucky_level
		var positives = []
		var sources = []
		for o in outcomes:
			if o[IDX_OP] in [OP_ADD, OP_MULTIPLY]:
				positives.append(o)
			else:
				sources.append(o)

		if positives.size() > 0 and sources.size() > 0:
			var source_weight = 0.0
			for o in sources:
				source_weight += o[IDX_WEIGHT]
			var available = min(shift_total, source_weight)
			if source_weight > 0.0 and available > 0.0:
				for o in sources:
					var take = available * (o[IDX_WEIGHT] / source_weight)
					o[IDX_WEIGHT] = max(0.0, o[IDX_WEIGHT] - take)
				for o in positives:
					o[IDX_WEIGHT] += available / positives.size()

	# Risk Taker: remove 0 outcomes, redistribute weight
	if "risk_taker" in game.unique_skills:
		var new_outcomes = []
		var zero_weight = 0.0
		for o in outcomes:
			if o[IDX_OP] == OP_NONE:
				zero_weight += o[IDX_WEIGHT]
			else:
				new_outcomes.append(o)
		outcomes = new_outcomes
		if zero_weight > 0 and outcomes.size() > 0:
			var total = 0.0
			for o in outcomes:
				total += o[IDX_WEIGHT]
			if total > 0:
				for o in outcomes:
					o[IDX_WEIGHT] += zero_weight * (o[IDX_WEIGHT] / total)

	return outcomes

static func apply_display_modifiers(outcomes, game):
	for o in outcomes:
		match o[IDX_OP]:
			OP_ADD:
				var magnet = game.skill_levels.get("coin_magnet", 0)
				var value = round(o[IDX_VALUE] * (1.0 + 0.01 * magnet))
				if "double_down" in game.unique_skills:
					value = round(value * 2.0)
				o[IDX_LABEL] = "+" + _format_number(value)
			OP_SUBTRACT:
				var iron = game.skill_levels.get("iron_skin", 0)
				var value = round(o[IDX_VALUE] * max(0.1, 1.0 - 0.01 * iron))
				o[IDX_LABEL] = "-" + _format_number(value)
			OP_MULTIPLY:
				var sharp = game.skill_levels.get("sharp_mind", 0)
				var value = o[IDX_VALUE] * (1.0 + 0.025 * sharp)
				if "double_down" in game.unique_skills:
					value = 2.0 * value - 1.0
				if o[IDX_LABEL] != "JACKPOT":
					o[IDX_LABEL] = "x" + _format_number(value)
			OP_DIVIDE:
				if "banker" in game.unique_skills:
					o[IDX_LABEL] = "-1"
				else:
					var iron = game.skill_levels.get("iron_skin", 0)
					var value = max(1.0, round(o[IDX_VALUE] * max(0.1, 1.0 - 0.01 * iron)))
					o[IDX_LABEL] = "/" + _format_number(value)
	return outcomes

static func _format_number(value: float) -> String:
	return str(int(round(value)))

static func weighted_random(outcomes):
	var total_weight = 0.0
	for o in outcomes:
		total_weight += o[IDX_WEIGHT]
	if total_weight <= 0:
		return outcomes[0]
	var roll = randf() * total_weight
	var cumulative = 0.0
	for o in outcomes:
		cumulative += o[IDX_WEIGHT]
		if roll <= cumulative:
			return o
	return outcomes[-1]

static func apply_outcome(outcome, current_coins: int, game) -> int:
	var result: float = float(current_coins)
	var op_type = outcome[IDX_OP]
	var value = outcome[IDX_VALUE]

	match op_type:
		OP_ADD:
			var magnet = game.skill_levels.get("coin_magnet", 0)
			result = current_coins + round(value * (1.0 + 0.01 * magnet))
		OP_SUBTRACT:
			var iron = game.skill_levels.get("iron_skin", 0)
			var iron_mult = max(0.1, 1.0 - 0.01 * iron)
			result = current_coins - round(value * iron_mult)
		OP_MULTIPLY:
			if current_coins == 0:
				result = value
			else:
				var sharp = game.skill_levels.get("sharp_mind", 0)
				result = round(current_coins * value * (1.0 + 0.025 * sharp))
		OP_DIVIDE:
			if "banker" in game.unique_skills:
				result = float(current_coins - 1)
			else:
				var iron = game.skill_levels.get("iron_skin", 0)
				var iron_mult = max(0.1, 1.0 - 0.01 * iron)
				result = round(current_coins / max(1.0, round(value * iron_mult)))
		OP_NONE:
			result = float(current_coins)

	# Double Down: 2x the positive gain
	if "double_down" in game.unique_skills:
		if result > current_coins:
			result = current_coins + (result - current_coins) * 2

	return int(result) - current_coins
