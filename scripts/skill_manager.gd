# scripts/skill_manager.gd
extends RefCounted

class SkillDef:
	var id: String
	var name: String
	var description: String
	var base_cost: int
	var max_level: int  # 0 = unique
	var category: String

const UPGRADEABLE_SKILLS: Array[Dictionary] = [
	{"id": "lucky_charm", "name": "Lucky Charm", "desc": "+0.2% positive weight per level", "base": 10, "max": 10},
	{"id": "quick_spin", "name": "Quick Spin", "desc": "-1.2% spin duration per level", "base": 5, "max": 5},
	{"id": "iron_skin", "name": "Iron Skin", "desc": "-1% negative effect per level", "base": 8, "max": 10},
	{"id": "coin_magnet", "name": "Coin Magnet", "desc": "+1% add values per level", "base": 7, "max": 10},
	{"id": "sharp_mind", "name": "Sharp Mind", "desc": "+2.5% multiply values per level", "base": 6, "max": 5},
]

const UNIQUE_SKILLS: Array[Dictionary] = [
	{"id": "double_down", "name": "Double Down", "desc": "2x all positive outcomes", "base": 100, "max": 0},
	{"id": "risk_taker", "name": "Risk Taker", "desc": "Remove all 0 outcomes", "base": 75, "max": 0},
	{"id": "fortunes_favor", "name": "Fortune's Favor", "desc": "Reroll negatives once per run", "base": 150, "max": 0},
	{"id": "banker", "name": "Banker", "desc": "Divide loses max 1 coin", "base": 50, "max": 0},
	{"id": "second_wind", "name": "Second Wind", "desc": "Restore 10 coins at 0, once", "base": 80, "max": 0},
]

static func get_all_skills() -> Array[Dictionary]:
	return UPGRADEABLE_SKILLS + UNIQUE_SKILLS

static func get_skill_by_id(id: String) -> Dictionary:
	for skill in get_all_skills():
		if skill["id"] == id:
			return skill
	return {}

static func get_purchase_cost(skill: Dictionary, current_level: int) -> int:
	if skill["max"] == 0:  # unique
		return skill["base"]
	var next_level = current_level + 1
	var reduced_base = max(1, int(round(float(skill["base"]) / 10.0)))
	return int(reduced_base * (2.0 * next_level - 1.0))
