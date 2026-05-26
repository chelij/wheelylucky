# scripts/wheel_config.gd
extends RefCounted

const SkillEffects = preload("res://scripts/skill_effects.gd")

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

# Total slots per wheel (each slot = 3 degrees)
const TOTAL_SLOTS = 120

# Outcome format: [label, op_type, value, slots, color]
# Helper to create outcome arrays
static func _mo(label, op_type, value, slots, color):
	return [label, op_type, value, slots, color]

# ── Wheel data — 120 slots per wheel ─────────────────────────────

static func _get_wheel_1():
	return [
		_mo("+25", OP_ADD, 25.0, 60, POSITIVE),
		_mo("0", OP_NONE, 0.0, 60, SAFE),
	]

static func _get_wheel_2():
	return [
		_mo("+60", OP_ADD, 60.0, 50, POSITIVE),
		_mo("-1", OP_SUBTRACT, 1.0, 30, NEGATIVE),
		_mo("x9", OP_MULTIPLY, 9.0, 10, MULTIPLY),
		_mo("0", OP_NONE, 0.0, 30, SAFE),
	]

static func _get_wheel_3():
	return [
		_mo("+160", OP_ADD, 160.0, 51, POSITIVE),
		_mo("-8", OP_SUBTRACT, 8.0, 35, NEGATIVE),
		_mo("x12", OP_MULTIPLY, 12.0, 9, MULTIPLY),
		_mo("0", OP_NONE, 0.0, 25, SAFE),
	]

static func _get_wheel_4():
	return [
		_mo("+450", OP_ADD, 450.0, 52, POSITIVE),
		_mo("-49", OP_SUBTRACT, 49.0, 40, NEGATIVE),
		_mo("x12", OP_MULTIPLY, 12.0, 8, MULTIPLY),
		_mo("0", OP_NONE, 0.0, 20, SAFE),
	]

static func _get_wheel_5():
	return [
		_mo("+1800", OP_ADD, 1800.0, 53, POSITIVE),
		_mo("-262", OP_SUBTRACT, 262.0, 45, NEGATIVE),
		_mo("x14", OP_MULTIPLY, 14.0, 7, MULTIPLY),
		_mo("0", OP_NONE, 0.0, 15, SAFE),
	]

static func _get_wheel_6():
	return [
		_mo("+7500", OP_ADD, 7500.0, 54, POSITIVE),
		_mo("-1375", OP_SUBTRACT, 1375.0, 50, NEGATIVE),
		_mo("x16", OP_MULTIPLY, 16.0, 6, MULTIPLY),
		_mo("0", OP_NONE, 0.0, 10, SAFE),
	]

static func _get_wheel_7():
	return [
		_mo("+27000", OP_ADD, 27000.0, 55, POSITIVE),
		_mo("-5962", OP_SUBTRACT, 5962.0, 50, NEGATIVE),
		_mo("x18", OP_MULTIPLY, 18.0, 5, MULTIPLY),
		_mo("0", OP_NONE, 0.0, 10, SAFE),
	]

static func _get_wheel_8():
	return [
		_mo("+190000", OP_ADD, 190000.0, 56, POSITIVE),
		_mo("-54250", OP_SUBTRACT, 54250.0, 55, NEGATIVE),
		_mo("x18", OP_MULTIPLY, 18.0, 4, MULTIPLY),
		_mo("0", OP_NONE, 0.0, 5, SAFE),
	]

static func _get_wheel_9():
	return [
		_mo("+1700000", OP_ADD, 1700000.0, 58, POSITIVE),
		_mo("-532500", OP_SUBTRACT, 532500.0, 55, NEGATIVE),
		_mo("x20", OP_MULTIPLY, 20.0, 2, MULTIPLY),
		_mo("0", OP_NONE, 0.0, 5, SAFE),
	]

static func _get_wheel_10():
	return [
		_mo("-6000000", OP_SUBTRACT, 6000000.0, 40, NEGATIVE),
		_mo("JACKPOT", OP_MULTIPLY, 10.0, 1, JACKPOT),
		_mo("0", OP_NONE, 0.0, 79, SAFE),
	]

# Outcome indices
const IDX_LABEL = 0
const IDX_OP = 1
const IDX_VALUE = 2
const IDX_SLOTS = 3
const IDX_COLOR = 4

static func get_cost(wheel_num: int) -> int:
	match wheel_num:
		1: return 0
		2: return 25
		3: return 75
		4: return 300
		5: return 1200
		6: return 5000
		7: return 18000
		8: return 140000
		9: return 1200000
		10: return 12000000
	return 12000000

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
	outcomes = apply_skill_modifiers(outcomes, game, wheel_num)
	var chosen = weighted_random(outcomes)

	# Fortune's Favor: push pointer past Minus outcome
	if chosen[IDX_OP] in [OP_SUBTRACT, OP_DIVIDE]:
		if "fortunes_favor" in game.unique_skills:
			var slot_index = _find_slot_index(chosen, outcomes)
			var total_slots = _total_slots(outcomes)
			var pushed_index = (slot_index + SkillEffects.FORTUNES_FAVOR_PUSH_SLOTS) % total_slots
			chosen = _outcome_at_slot(outcomes, pushed_index)

	var delta = apply_outcome(chosen, game.coins, game)
	return {"delta": delta, "outcome": chosen}

# ── Slot-index helpers for Fortune's Favor push ─────────────────

static func _total_slots(outcomes):
	var total = 0
	for o in outcomes:
		total += int(o[IDX_SLOTS])
	return total

static func _find_slot_index(target, outcomes):
	var cumulative = 0
	for o in outcomes:
		cumulative += int(o[IDX_SLOTS])
		if target == o:
			return cumulative - 1
	return 0

static func _outcome_at_slot(outcomes, slot_index):
	var remaining = slot_index
	for o in outcomes:
		var count = int(o[IDX_SLOTS])
		if remaining < count:
			return o
		remaining -= count
	return outcomes[-1]

# ── Skill modifiers ─────────────────────────────────────────────

static func apply_skill_modifiers(outcomes, game, wheel_num):
	# Lucky Charm: move Minus slots into Plus/Multiply outcomes (slot-based)
	var lucky_level = game.skill_levels.get("lucky_charm", 0)
	if lucky_level > 0:
		for _i in range(lucky_level):
			var pos = []
			var src = []
			for o in outcomes:
				if o[IDX_OP] in [OP_ADD, OP_MULTIPLY]:
					pos.append(o)
				elif o[IDX_OP] == OP_SUBTRACT and int(o[IDX_SLOTS]) > 0:
					src.append(o)
			if pos.size() > 0 and src.size() > 0:
				src.sort_custom(func(s): return int(s[IDX_SLOTS])) # most slots first
				src[-1][IDX_SLOTS] -= 1
				pos[_i % pos.size()][IDX_SLOTS] += 1

	# Momentum: move non-Plus slots into Plus outcomes (slot-based)
	if "momentum" in game.unique_skills and game.momentum_stacks > 0:
		var max_bonus = SkillEffects.MOMENTUM_MAX_BONUS_SLOTS
		var per_stack = SkillEffects.MOMENTUM_POSITIVE_SLOTS_PER_STACK
		var bonus_slots = min(game.momentum_stacks * per_stack, max_bonus)
		for _i in range(bonus_slots):
			var plus = [o for o in outcomes if o[IDX_OP] == OP_ADD]
			var src = []
			for o in outcomes:
				if o[IDX_OP] != OP_ADD and int(o[IDX_SLOTS]) > 0:
					src.append(o)
			if plus.size() > 0 and src.size() > 0:
				src.sort_custom(func(s): return int(s[IDX_SLOTS]))
				src[-1][IDX_SLOTS] -= 1
				plus[_i % plus.size()][IDX_SLOTS] += 1

	# Risk Taker: remove 0 outcomes, redistribute slots
	if "risk_taker" in game.unique_skills:
		if wheel_num == 1:
			# W1: all Plus — already the case (60/60)
			var plus = []
			for o in outcomes:
				if o[IDX_OP] == OP_ADD:
					plus.append(o)
			if plus.size() > 0:
				plus[0][IDX_SLOTS] = TOTAL_SLOTS
				for o in outcomes:
					if o[IDX_OP] != OP_ADD:
						o[IDX_SLOTS] = 0
		elif wheel_num == 10:
			# W10: convert some 0 slots to JACKPOT
			var jackpot = null
			var zero_outcome = null
			for o in outcomes:
				if o[IDX_LABEL] == "JACKPOT":
					jackpot = o
				elif o[IDX_OP] == OP_NONE and o[IDX_LABEL] != "JACKPOT":
					zero_outcome = o
			if jackpot and zero_outcome:
				var converted = int(float(zero_outcome[IDX_SLOTS]) * SkillEffects.RISK_TAKER_W10_ZERO_TO_JACKPOT_RATE)
				zero_outcome[IDX_SLOTS] -= converted
				jackpot[IDX_SLOTS] += converted
		else:
			# Remove 0 outcomes, redistribute their slots
			var zero_total = 0
			for o in outcomes:
				if o[IDX_OP] == OP_NONE and o[IDX_LABEL] != "JACKPOT":
					zero_total += int(o[IDX_SLOTS])

			var new_outcomes = []
			for o in outcomes:
				if not (o[IDX_OP] == OP_NONE and o[IDX_LABEL] != "JACKPOT"):
					new_outcomes.append(o)
			outcomes = new_outcomes

			# Distribute zero slots proportionally
			var total_remaining = 0
			for o in outcomes:
				total_remaining += int(o[IDX_SLOTS])
			if total_remaining > 0 and zero_total > 0:
				while zero_total > 0 and outcomes.size() > 0:
					var idx = (TOTAL_SLOTS - zero_total) % max(1, outcomes.size())
					outcomes[idx][IDX_SLOTS] += 1
					zero_total -= 1

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

# ── Weighted random — works with slot counts ───────────────────

static func weighted_random(outcomes):
	var total_weight = 0.0
	for o in outcomes:
		total_weight += float(o[IDX_SLOTS])
	if total_weight <= 0:
		return outcomes[0]
	var roll = randf() * total_weight
	var cumulative = 0.0
	for o in outcomes:
		cumulative += float(o[IDX_SLOTS])
		if roll <= cumulative:
			return o
	return outcomes[-1]

# ── Apply outcome — multiplier pays from spin cost ──────────────

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
			# Multiplier pays from spin cost, not current coins
			var spin_cost = game.last_spin_cost
			var sharp = game.skill_levels.get("sharp_mind", 0)
			result = current_coins + round(float(spin_cost) * value * (1.0 + 0.025 * sharp))
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
