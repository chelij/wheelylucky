# scripts/skill_effects.gd
extends RefCounted

# Skill balance index. Edit these values to tune skill effects.

# Lucky Charm: each level moves this many Minus slots into Plus/Multiply outcomes.
const LUCKY_CHARM_POSITIVE_SLOTS_PER_LEVEL = 1

# Quick Spin: each level multiplies spin duration by this value. Lower is faster.
const QUICK_SPIN_DURATION_MULTIPLIER_PER_LEVEL = 0.90

# Discount Card: each level reduces wheel spin costs by this fraction.
const DISCOUNT_CARD_SPIN_COST_DISCOUNT_PER_LEVEL = 0.015

# Coin Magnet: each level adds this fraction of positive Plus value after Plus spins.
const COIN_MAGNET_ADD_VALUE_PER_LEVEL = 0.10

# Sharp Mind: each level adds this fraction of visible multiplier payout after Multiply spins.
const SHARP_MIND_MULTIPLY_VALUE_PER_LEVEL = 0.25

# Free Gift: None/Minus outcomes refund this fraction of the spin cost per level.
const FREE_GIFT_REFUND_PER_LEVEL = 0.02

# Shop Savvy: each level reduces shop purchase prices by this fraction.
const SHOP_SAVVY_PRICE_DISCOUNT_PER_LEVEL = 0.02

# Market Bell: base shop roll chance after each non-game-ending spin.
const MARKET_BELL_BASE_SHOP_CHANCE = 0.10

# Market Bell: each level adds this much to the shop chance and miss bonus step.
const MARKET_BELL_SHOP_CHANCE_PER_LEVEL = 0.01

# Collector: each level increases the chance that a shop offer includes a unique.
const COLLECTOR_UNIQUE_CHANCE_PER_LEVEL = 0.10

# Risk Taker: on W10, converts this fraction of None slots into jackpot slots.
const RISK_TAKER_W10_ZERO_TO_JACKPOT_RATE = 0.10

# Fortune's Favor: each Minus hit pushes the pointer result this many slots farther.
const FORTUNES_FAVOR_PUSH_SLOTS = 3

# Banker: after each spin, gain this fraction of current coins as interest.
const BANKER_INTEREST_RATE = 0.10

# Second Wind: if coins end below the spun wheel cost, this chance refunds that spin cost.
const SECOND_WIND_REFUND_CHANCE = 0.50

# Momentum: each Plus spin moves this many non-Plus slots into Plus outcomes.
const MOMENTUM_POSITIVE_SLOTS_PER_STACK = 2

# Momentum: maximum total Plus slots added.
const MOMENTUM_MAX_BONUS_SLOTS = 20

# First upgrade level cost. Upgrade costs scale by level squared.
const UPGRADE_COST_START = 35

# First unique cost. Unique costs scale by unique count squared.
const UNIQUE_COST_START = 700

# Upgrade levels above this get an extra steep quadratic multiplier.
const UPGRADE_EXPENSIVE_AFTER_LEVEL = 6

static func upgrade_cost_for_level(level: int) -> int:
	var cost = UPGRADE_COST_START * level * level
	if level >= 4:
		cost = int(round(float(cost) * (1.0 + 0.18 * float(level - 3))))
	if level > UPGRADE_EXPENSIVE_AFTER_LEVEL:
		cost = int(round(float(cost) * (1.0 + 0.85 * float(level - UPGRADE_EXPENSIVE_AFTER_LEVEL))))
	return cost

static func unique_cost_for_count(unique_count: int) -> int:
	return int(round(float(UNIQUE_COST_START * unique_count * unique_count) * (1.0 + 0.2 * float(max(0, unique_count - 1)))))
