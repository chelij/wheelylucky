# scripts/skill_manager.gd
## Static utility — do not instantiate.
extends RefCounted

const SkillEffects = preload("res://scripts/skill_effects.gd")

const UPGRADEABLE_SKILLS: Array[Dictionary] = [
	{"id": "lucky_charm", "name": "Lucky Charm", "desc": "+1 Plus slot per level", "base": 10, "max": -1},
	{"id": "quick_spin", "name": "Quick Spin", "desc": "Faster spin duration per level", "base": 5, "max": -1},
	{"id": "discount_card", "name": "Discount Card", "desc": "-1.5% spin cost per level", "base": 8, "max": -1},
	{"id": "coin_magnet", "name": "Coin Magnet", "desc": "Plus spins add 10% Plus value per level", "base": 7, "max": -1},
	{"id": "sharp_mind", "name": "Sharp Mind", "desc": "Multiply spins add 25% multiplier payout per level", "base": 6, "max": -1},
	{"id": "free_gift", "name": "Free Gift", "desc": "None/Minus outcomes refund 2% spin cost per level", "base": 5, "max": -1},
	{"id": "shop_savvy", "name": "Shop Savvy", "desc": "Shop prices are 2% cheaper per level", "base": 5, "max": -1},
	{"id": "market_bell", "name": "Market Bell", "desc": "+1% shop chance and miss bonus per level", "base": 5, "max": -1},
	{"id": "collector", "name": "Collector", "desc": "Uniques are 10% more likely to appear per level", "base": 5, "max": -1},
]

const UNIQUE_SKILLS: Array[Dictionary] = [
	{"id": "double_down", "name": "Double Down", "desc": "2x All Outcomes Results and Spin Costs", "base": 100, "max": 0},
	{"id": "risk_taker", "name": "Risk Taker", "desc": "Removes None Outcomes on Wheels Other Than Final Wheel", "base": 75, "max": 0},
	{"id": "fortunes_favor", "name": "Fortune's Favor", "desc": "Spins on Minus Pushes the Spin 3 Slots Farther", "base": 150, "max": 0},
	{"id": "banker", "name": "Banker", "desc": "Earn 10% Interest After Each Spin", "base": 50, "max": 0},
	{"id": "second_wind", "name": "Second Wind", "desc": "50% Chance to Refund Spin Cost if Coin Total Goes Under Spin Cost", "base": 80, "max": 0},
	{"id": "randomizer", "name": "Randomizer", "desc": "Randomizes All Outcome Positions", "base": 100, "max": 0},
	{"id": "momentum", "name": "Momentum", "desc": "Plus Spins Adds 2 Plus Slots up to 20. Minus Spins Resets", "base": 100, "max": 0},
	{"id": "golden_ticket", "name": "Golden Ticket", "desc": "Shops Offer 1 Extra Skill for Purchase", "base": 100, "max": 0},
	{"id": "double_spin", "name": "Double Spin", "desc": "Pointer Also Spins", "base": 100, "max": 0},
]

static func get_all_skills() -> Array[Dictionary]:
	return UPGRADEABLE_SKILLS + UNIQUE_SKILLS

static func get_skill_by_id(id: String) -> Dictionary:
	for skill in get_all_skills():
		if skill["id"] == id:
			return skill
	return {}

static func get_purchase_cost(skill: Dictionary, current_level: int) -> int:
	var next_level = current_level + 1
	if skill["max"] == 0:
		return SkillEffects.unique_cost_for_count(next_level)
	return SkillEffects.upgrade_cost_for_level(next_level)

static func get_effect_text(skill_id: String, current_level: int) -> String:
	var next_level = current_level + 1
	match skill_id:
		"lucky_charm":
			return "+" + str(SkillEffects.LUCKY_CHARM_POSITIVE_SLOTS_PER_LEVEL * next_level) + " Plus Slots \n-" + str(SkillEffects.LUCKY_CHARM_POSITIVE_SLOTS_PER_LEVEL * next_level) + " Minus Slots"
		"quick_spin":
			var speed = int(round((1.0 - pow(SkillEffects.QUICK_SPIN_DURATION_MULTIPLIER_PER_LEVEL, next_level)) * 100.0))
			return "Spins are " + str(speed) + "% Faster"
		"discount_card":
			return "Spins are " + _format_percent(100.0 * SkillEffects.DISCOUNT_CARD_SPIN_COST_DISCOUNT_PER_LEVEL * next_level) + " Cheaper"
		"coin_magnet":
			return "Plus Spins Add " + _format_percent(100.0 * SkillEffects.COIN_MAGNET_ADD_VALUE_PER_LEVEL * next_level) + " Plus Value"
		"sharp_mind":
			return "Multiply Spins Add " + _format_percent(100.0 * SkillEffects.SHARP_MIND_MULTIPLY_VALUE_PER_LEVEL * next_level) + " Extra Payout"
		"free_gift":
			return _format_percent(100.0 * SkillEffects.FREE_GIFT_REFUND_PER_LEVEL * next_level) + " Spin Cost Refund for None/Minus Spins"
		"shop_savvy":
			return _format_percent(100.0 * SkillEffects.SHOP_SAVVY_PRICE_DISCOUNT_PER_LEVEL * next_level) + " Shop Discount"
		"market_bell":
			return "+" + _format_percent(100.0 * SkillEffects.MARKET_BELL_SHOP_CHANCE_PER_LEVEL * next_level) + " Chance to Find Shop"
		"collector":
			return "+" + _format_percent(100.0 * SkillEffects.COLLECTOR_UNIQUE_CHANCE_PER_LEVEL * next_level) + " Chance for Uniques in Shop"
		_:
			var skill = get_skill_by_id(skill_id)
			return skill.get("desc", "")

static func _format_percent(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value))) + "%"
	return str(value).pad_decimals(1) + "%"
