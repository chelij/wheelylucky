#!/usr/bin/env python3
"""Wheely Lucky - Playtime simulator.

Reads balance numbers directly from GD source files on every run,
so changing wheel outcomes/costs/skills in Godot is always reflected
here without having to update this script.

Usage:
    python3 scripts/sim_playtime.py [runs]              # all strategy combos
    python3 scripts/sim_playtime.py [runs] --shop X     # single shop strat
    python3 scripts/sim_playtime.py [runs] --adv X      # single advance policy
    python3 scripts/sim_playtime.py [runs] --gd-only    # parse & dump config

Shop strategies: none | cheap_only | aggressive | priority | expensive | max_buy | prio_maxlevel | random_afford
Advance policies: 1x | 1.5x | 2x | 2.5x | 3x | 4x (or any number)
"""

import random
import math
import re
import os
import argparse
from dataclasses import dataclass
from itertools import product as iter_product

# ── GD File Parser ──────────────────────────────────────────────

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


def _read_gd(filename: str) -> str:
    path = os.path.join(SCRIPT_DIR, filename)
    with open(path, "r") as f:
        return f.read()


def parse_wheel_config():
    """Parse wheel_config.gd for wheel outcomes, costs, and constants."""
    text = _read_gd("wheel_config.gd")

    m = re.search(r"const\s+TOTAL_SLOTS\s*=\s*(\d+)", text)
    total_slots = int(m.group(1)) if m else 120

    op_map = {
        "OP_ADD": "add", "OP_SUBTRACT": "sub",
        "OP_MULTIPLY": "mul",
        "OP_NONE": "none",
    }

    wheels = {}
    for wn in range(1, 11):
        pattern = rf"static func _get_wheel_{wn}\(\).*?return \[(.*?)\]"
        match = re.search(pattern, text, re.DOTALL)
        if not match:
            continue
        block = match.group(1)

        outcomes = []
        mo_pattern = r'_mo\s*\(\s*"([^"]*)"\s*,\s*(OP_\w+)\s*,\s*([\d.]+)\s*,\s*(\d+)'
        for m2 in re.finditer(mo_pattern, block):
            label = m2.group(1)
            op = op_map.get(m2.group(2), "none")
            value = float(m2.group(3))
            slots = int(m2.group(4))
            outcomes.append((label, op, value, slots))
        wheels[wn] = outcomes

    cost_block_match = re.search(
        r"static func get_cost\(.*?\).*?match wheel_num:(.+)", text, re.DOTALL)
    wheel_costs = {}
    if cost_block_match:
        for cm in re.finditer(r'(\d+):\s*return\s*(\d+)', cost_block_match.group(1)):
            wheel_costs[int(cm.group(1))] = int(cm.group(2))

    return wheels, wheel_costs, total_slots


def parse_skill_manager():
    """Parse skill_manager.gd for UPGRADEABLE_SKILLS and UNIQUE_SKILLS."""
    text = _read_gd("skill_manager.gd")

    # Each entry: (id, base_cost, max_level)
    upgradeable = []
    ublock = re.search(r"const UPGRADEABLE_SKILLS.*?=\s*\[(.+?)\n\]", text, re.DOTALL)
    if ublock:
        for m in re.finditer(
                r'"id":\s*"([^"]+)"[^}]*"base":\s*(\d+)[^}]*"max":\s*(-?\d+)',
                ublock.group(1)):
            upgradeable.append((m.group(1), int(m.group(2)), int(m.group(3))))

    unique = []
    uqblock = re.search(r"const UNIQUE_SKILLS.*?=\s*\[(.+?)\n\]", text, re.DOTALL)
    if uqblock:
        for m in re.finditer(r'"id":\s*"([^"]+)"[^}]*"max":\s*0', uqblock.group(1)):
            unique.append(m.group(1))

    return upgradeable, unique


def parse_wheel_gd():
    """Parse wheel.gd for base_spin_duration."""
    text = _read_gd("wheel.gd")
    m = re.search(r"var\s+base_spin_duration\s*:\s*float\s*=\s*([\d.]+)", text)
    return float(m.group(1)) if m else 2.5


def load_balance_config():
    """Load all balance numbers from GD files."""
    wheels, wheel_costs, total_slots = parse_wheel_config()
    upgradeable_skills, unique_skills = parse_skill_manager()
    base_spin_dur = parse_wheel_gd()

    return {
        "wheels": wheels,
        "wheel_costs": wheel_costs,
        "total_slots": total_slots,
        "upgradeable_skills": upgradeable_skills,
        "unique_skills": unique_skills,
        "base_spin_dur": base_spin_dur,
    }


def dump_config(cfg):
    """Pretty-print parsed config for verification."""
    print("Parsed GD Balance Config:")
    print(f"  Base spin duration: {cfg['base_spin_dur']}s")
    print(f"  Total slots per wheel: {cfg['total_slots']}")
    print()
    print("Wheel Costs:")
    for w, c in sorted(cfg["wheel_costs"].items()):
        print(f"  W{w}: {c}")
    print()
    print("Wheel Outcomes:")
    for w in sorted(cfg["wheels"].keys()):
        outcomes = cfg["wheels"][w]
        total = sum(o[3] for o in outcomes)
        labels = ", ".join(f"{o[0]}({o[1]}:{o[2]})x{o[3]}" for o in outcomes)
        print(f"  W{w} ({total} slots): {labels}")
    print()
    print("Upgradeable Skills (id, base_cost, max_level):")
    for sid, bcost, mx in cfg["upgradeable_skills"]:
        print(f"  {sid}: base={bcost} max={mx}")
    print()
    print("Unique Skills:")
    for s in cfg["unique_skills"]:
        print(f"  {s}")


# ── Config (loaded from GD files) ──────────────────────────────

CFG = None  # populated at runtime

SHOP_TIME_MIN = 3.0
SHOP_TIME_MAX = 8.0

# Mirrors scripts/skill_effects.gd. Keep these values in sync when simulating balance changes.
LUCKY_CHARM_POSITIVE_SLOTS_PER_LEVEL = 1
QUICK_SPIN_DURATION_MULTIPLIER_PER_LEVEL = 0.90
DISCOUNT_CARD_SPIN_COST_DISCOUNT_PER_LEVEL = 0.015
COIN_MAGNET_ADD_VALUE_PER_LEVEL = 0.10
SHARP_MIND_MULTIPLY_VALUE_PER_LEVEL = 0.25
FREE_GIFT_REFUND_PER_LEVEL = 0.02
SHOP_SAVVY_PRICE_DISCOUNT_PER_LEVEL = 0.02
MARKET_BELL_BASE_SHOP_CHANCE = 0.10
MARKET_BELL_SHOP_CHANCE_PER_LEVEL = 0.01
COLLECTOR_UNIQUE_CHANCE_PER_LEVEL = 0.10
RISK_TAKER_W10_ZERO_TO_JACKPOT_RATE = 0.10
FORTUNES_FAVOR_PUSH_SLOTS = 3
BANKER_INTEREST_RATE = 0.10
SECOND_WIND_REFUND_CHANCE = 0.50
MOMENTUM_POSITIVE_SLOTS_PER_STACK = 2
MOMENTUM_MAX_BONUS_SLOTS = 20
UPGRADE_COST_START = 25
UNIQUE_COST_START = 500
UPGRADE_EXPENSIVE_AFTER_LEVEL = 10

# Priority order for "priority" shop strategy — which skills to buy first
SKILL_PRIORITY = [
    "quick_spin",     # speed matters most
    "coin_magnet",    # post-spin Plus payout scaling
    "lucky_charm",    # shift odds toward Plus
    "sharp_mind",     # multiply scaling
    "discount_card",  # cheaper spins
    "free_gift",      # refund on None/Minus outcomes
    "shop_savvy",     # cheaper shops (meta)
    "market_bell",    # more shops (meta)
    "collector",      # uniques more likely (meta)
]


@dataclass
class RunResult:
    total_spins: int
    total_time_sec: float
    final_coins: int
    max_wheel_reached: int
    shop_opens: int
    skills_bought: int
    coins_spent_shops: int
    cycles_completed: int = 0
    won: bool = False
    wheel_spins: tuple[int, ...] = ()


class SimGame:
    def __init__(self, shop_strategy="none", advance_policy="greedy"):
        self.coins = 0
        self.selected_wheel = 1
        self.total_spins = 0
        self.cycle_count = 1
        self.max_wheel_reached = 1
        self.last_spin_cost = 0
        self.skill_levels = {s[0]: 0 for s in CFG["upgradeable_skills"]}
        self.unique_skills: list[str] = []
        self.momentum_stacks = 0
        self.shop_available = False
        self.offered_shop = []
        self.shop_miss_count = 0
        self.shop_opens = 0
        self.skills_bought = 0
        self.coins_spent_shops = 0
        self.total_time_sec = 0.0
        self.wheel_spins = [0 for _ in range(self.MAX_WHEEL + 1)]
        self.won = False

        # Strategy — instance-level, not global
        self.shop_strategy = shop_strategy
        self.advance_policy = advance_policy

    @property
    def MAX_WHEEL(self):
        return len(CFG["wheels"])

    def spin_duration(self) -> float:
        q = self.skill_levels.get("quick_spin", 0)
        return CFG["base_spin_dur"] * (QUICK_SPIN_DURATION_MULTIPLIER_PER_LEVEL ** q)

    def wheel_cost(self, w: int) -> int:
        cost = float(CFG["wheel_costs"].get(w, 0))
        d = self.skill_levels.get("discount_card", 0)
        cost *= max(0.0, 1.0 - DISCOUNT_CARD_SPIN_COST_DISCOUNT_PER_LEVEL * d)
        if "double_down" in self.unique_skills and w != self.MAX_WHEEL:
            cost *= 2.0
        return int(round(cost))

    def can_afford(self, w: int) -> bool:
        c = self.wheel_cost(w)
        return c == 0 or self.coins >= c

    # ── Outcomes with skill modifiers ───────────────────────────

    def get_outcomes(self, wn: int):
        raw = CFG["wheels"].get(wn, [])
        out = [list(item) for item in raw]

        lucky = self.skill_levels.get("lucky_charm", 0) * LUCKY_CHARM_POSITIVE_SLOTS_PER_LEVEL
        for i in range(lucky):
            pos = [o for o in out if o[1] in ("add", "mul") or o[0] == "JACKPOT"]
            src = [o for o in out if o[1] == "sub" and o[3] > 0]
            if not pos or not src:
                break
            src.sort(key=lambda x: -x[3])
            src[0][3] -= 1
            pos[i % len(pos)][3] += 1

        if "momentum" in self.unique_skills and self.momentum_stacks > 0:
            bonus_slots = min(
                self.momentum_stacks * MOMENTUM_POSITIVE_SLOTS_PER_STACK,
                MOMENTUM_MAX_BONUS_SLOTS,
            )
            for i in range(bonus_slots):
                pos = [o for o in out if o[1] == "add"]
                src = [o for o in out if o[1] != "add" and o[3] > 0]
                if not pos or not src:
                    break
                src.sort(key=lambda x: -x[3])
                src[0][3] -= 1
                pos[i % len(pos)][3] += 1

        if "risk_taker" in self.unique_skills:
            if wn == 1:
                plus = next((o for o in out if o[1] == "add"), None)
                if plus:
                    for o in out:
                        o[3] = CFG["total_slots"] if o is plus else 0
            elif wn == self.MAX_WHEEL:
                jackpot = next((o for o in out if o[0] == "JACKPOT"), None)
                zero = next((o for o in out if o[1] == "none" and o[0] != "JACKPOT"), None)
                if jackpot and zero:
                    converted_slots = int(math.floor(float(zero[3]) * RISK_TAKER_W10_ZERO_TO_JACKPOT_RATE))
                    zero[3] -= converted_slots
                    jackpot[3] += converted_slots
            elif wn != 1:
                z = sum(int(o[3]) for o in out if o[1] == "none" and o[0] != "JACKPOT")
                out = [o for o in out if not (o[1] == "none" and o[0] != "JACKPOT")]
                idx = 0
                while z > 0 and out:
                    out[idx % len(out)][3] += 1
                    z -= 1
                    idx += 1
        return out

    def pick_outcome(self, wn: int):
        picked = self.pick_outcome_with_slot(wn)
        return picked[0] if picked else None

    def pick_outcome_with_slot(self, wn: int):
        outcomes = self.get_outcomes(wn)
        total = sum(int(o[3]) for o in outcomes)
        if total <= 0:
            return None
        slot_index = random.randrange(total)
        cum = 0
        for o in outcomes:
            cum += int(o[3])
            if slot_index < cum:
                return o, slot_index, outcomes, total
        return outcomes[-1], total - 1, outcomes, total

    def outcome_at_slot(self, outcomes, slot_index: int):
        cum = 0
        for outcome in outcomes:
            cum += int(outcome[3])
            if slot_index < cum:
                return outcome
        return outcomes[-1] if outcomes else None

    def apply_outcome(self, outcome) -> int:
        op, val = outcome[1], outcome[2]
        res = float(self.coins)
        base_delta = 0

        if op == "add":
            base_delta = round(val)
            res = self.coins + base_delta
        elif op == "sub":
            base_delta = -round(val)
            res = self.coins + base_delta
        elif op == "mul":
            base_delta = round(float(self.last_spin_cost) * val)
            res = self.coins + base_delta

        if "double_down" in self.unique_skills and abs(res - self.coins) > 0:
            base_delta *= 2
            res = self.coins + base_delta

        if op == "add":
            m = self.skill_levels.get("coin_magnet", 0)
            if m > 0 and base_delta > 0:
                res += round(float(base_delta) * COIN_MAGNET_ADD_VALUE_PER_LEVEL * m)
        elif op == "mul":
            s = self.skill_levels.get("sharp_mind", 0)
            if s > 0 and base_delta > 0:
                res += round(float(base_delta) * SHARP_MIND_MULTIPLY_VALUE_PER_LEVEL * s)

        return int(max(0, res))

    # ── Shop ────────────────────────────────────────────────────

    def roll_shop(self):
        market = self.skill_levels.get("market_bell", 0)
        step = MARKET_BELL_BASE_SHOP_CHANCE + MARKET_BELL_SHOP_CHANCE_PER_LEVEL * market
        chance = min(1.0, step * float(self.shop_miss_count + 1))
        if random.random() < chance:
            offered = self._build_offered()
            if any(self.coins >= cost for _, cost in offered):
                self.offered_shop = offered
                self.shop_available = True
                self.shop_miss_count = 0
                self.shop_opens += 1
            else:
                self.offered_shop = []
                self.shop_available = False
        else:
            self.offered_shop = []
            self.shop_miss_count += 1

    def _build_offered(self):
        """Build the list of skills offered in this shop visit."""
        avail = []
        for sid, _base_cost, ml in CFG["upgradeable_skills"]:
            if ml < 0 or self.skill_levels[sid] < ml:
                next_level = self.skill_levels[sid] + 1
                cost = UPGRADE_COST_START * next_level * next_level
                if next_level > UPGRADE_EXPENSIVE_AFTER_LEVEL:
                    cost = round(float(cost) * (1.0 + ((next_level - UPGRADE_EXPENSIVE_AFTER_LEVEL) ** 2)))
                sv = self.skill_levels.get("shop_savvy", 0)
                cost = max(1, int(round(float(cost) * max(0.0, 1.0 - SHOP_SAVVY_PRICE_DISCOUNT_PER_LEVEL * sv))))
                avail.append((sid, cost))

        all_unique = CFG["unique_skills"]
        unavail = [u for u in all_unique if u not in self.unique_skills]
        col = self.skill_levels.get("collector", 0)
        uc = min(1.0, (0.5 + COLLECTOR_UNIQUE_CHANCE_PER_LEVEL * col)) * (0.5 ** len(self.unique_skills))

        count = 4 if "golden_ticket" in self.unique_skills else 3
        offered = []

        if unavail and random.random() < uc:
            u = random.choice(unavail)
            next_unique = len(self.unique_skills) + 1
            cost = UNIQUE_COST_START * next_unique * next_unique
            offered.append((u, cost))

        while len(offered) < count and avail:
            idx = random.randint(0, len(avail) - 1)
            offered.append(avail[idx])
            avail.pop(idx)

        return offered

    def _pick_skill(self, offered):
        """Pick a skill based on the active shop strategy. Returns (sid, cost) or None."""
        affordable = [(s, c) for s, c in offered if self.coins >= c]
        if not affordable:
            return None

        if self.shop_strategy == "aggressive":
            # Buy first affordable in offered order
            return affordable[0]

        elif self.shop_strategy == "cheap_only":
            # Buy cheapest affordable
            return min(affordable, key=lambda x: x[1])

        elif self.shop_strategy == "priority":
            # Buy the highest-priority skill from SKILL_PRIORITY among affordable
            pmap = {sid: i for i, sid in enumerate(SKILL_PRIORITY)}
            return min(affordable, key=lambda x: pmap.get(x[0], 99))

        elif self.shop_strategy == "expensive":
            # Buy the most expensive affordable skill.
            return max(affordable, key=lambda x: x[1])

        elif self.shop_strategy == "prio_maxlevel":
            # Buy skill with highest max_level first (read from GD)
            level_map = {sid: mx for sid, _, mx in CFG["upgradeable_skills"]}
            return min(affordable, key=lambda x: -level_map.get(x[0], 0))

        elif self.shop_strategy == "random_afford":
            # Pick random affordable skill
            return random.choice(affordable)

        return None

    def _buy(self, sid: str, cost: int):
        self.coins -= cost
        self.coins_spent_shops += cost
        if any(sid == s[0] for s in CFG["upgradeable_skills"]):
            self.skill_levels[sid] += 1
        elif sid in CFG["unique_skills"] and sid not in self.unique_skills:
            self.unique_skills.append(sid)
        self.skills_bought += 1

    def handle_shop(self) -> bool:
        if not self.shop_available or self.shop_strategy == "none":
            return False

        offered = self.offered_shop
        if not offered:
            self.shop_available = False
            return False

        bought = False

        if self.shop_strategy == "max_buy":
            # Buy as many affordable skills as possible in this visit
            affordable = [(s, c) for s, c in offered if self.coins >= c]
            affordable.sort(key=lambda x: x[1])  # cheapest first to maximize count
            for sid, cost in affordable:
                if self.coins >= cost:
                    self._buy(sid, cost)
                    bought = True
        else:
            choice = self._pick_skill(offered)
            if choice:
                self._buy(*choice)
                bought = True

        if bought:
            self.total_time_sec += random.uniform(SHOP_TIME_MIN, SHOP_TIME_MAX)

        self.shop_available = False
        self.offered_shop = []
        self.shop_miss_count = 0
        return bought

    # ── Wheel Advancement ───────────────────────────────────────

    def try_advance(self):
        # Named aliases map to numeric thresholds
        alias_map = {
            "1x": 1.0, "greedy": 1.0,
            "1.5x": 1.5, "balanced": 1.5,
            "2x": 2.0, "conservative": 2.0,
        }
        threshold = alias_map.get(self.advance_policy)
        if threshold is None:
            # Try parsing as a float (e.g. "2.5", "3", "4")
            try:
                threshold = float(self.advance_policy.replace("x", ""))
            except (ValueError, AttributeError):
                threshold = 1.0

        target = self.selected_wheel + 1
        while target <= self.MAX_WHEEL:
            needed = self.wheel_cost(target)
            if needed == 0 or self.coins >= needed * threshold:
                self.selected_wheel = target
                break
            break

    def fallback_wheel(self):
        if self.can_afford(self.selected_wheel):
            return
        fb = 1
        for w in range(self.selected_wheel - 1, 0, -1):
            if self.can_afford(w):
                fb = w
                break
        self.selected_wheel = fb

    # ── Spin ────────────────────────────────────────────────────

    def spin_limit(self) -> int:
        """Max spins per run. Lower for no-shop runs to avoid wasting time."""
        return 5000 if self.shop_strategy == "none" else 100000

    def run_spin(self) -> bool:
        wheel = self.selected_wheel
        cost = self.wheel_cost(wheel)

        if self.coins < cost and cost > 0:
            self.fallback_wheel()
            wheel = self.selected_wheel
            cost = self.wheel_cost(wheel)
            if self.coins < cost and cost > 0:
                return False

        self.coins -= cost
        self.last_spin_cost = cost
        self.total_spins += 1
        self.wheel_spins[wheel] += 1

        if wheel == 1 and "risk_taker" in self.unique_skills:
            outcomes = self.get_outcomes(wheel)
            outcome = next((o for o in outcomes if o[1] == "add"), None)
            if not outcome:
                return False
        else:
            self.total_time_sec += self.spin_duration()
            picked = self.pick_outcome_with_slot(wheel)
            if not picked:
                return False
            outcome, slot_index, outcomes, total_s = picked

            # Fortune's Favor
            if "fortunes_favor" in self.unique_skills and outcome[1] == "sub":
                outcome = self.outcome_at_slot(outcomes, (slot_index + FORTUNES_FAVOR_PUSH_SLOTS) % total_s)

        self.coins = self.apply_outcome(outcome)

        # Momentum
        if "momentum" in self.unique_skills:
            if outcome[1] == "add":
                max_stacks = MOMENTUM_MAX_BONUS_SLOTS // MOMENTUM_POSITIVE_SLOTS_PER_STACK
                self.momentum_stacks = min(max_stacks, self.momentum_stacks + 1)
            elif outcome[1] == "sub":
                self.momentum_stacks = 0

        # Free Gift
        if outcome[1] in ("none", "sub") and outcome[0] != "JACKPOT":
            fg = self.skill_levels.get("free_gift", 0)
            if fg > 0:
                self.coins += int(round(float(self.last_spin_cost) * FREE_GIFT_REFUND_PER_LEVEL * fg))

        # Banker
        if "banker" in self.unique_skills and self.coins > 0:
            self.coins += int(round(float(self.coins) * BANKER_INTEREST_RATE))

        # Second Wind
        if ("second_wind" in self.unique_skills and
                self.coins < self.last_spin_cost and
                random.random() < SECOND_WIND_REFUND_CHANCE):
            self.coins += self.last_spin_cost

        is_jackpot = (wheel == self.MAX_WHEEL and outcome[0] == "JACKPOT")
        if is_jackpot:
            self.won = True

        if wheel == self.MAX_WHEEL and not is_jackpot:
            self.cycle_count += 1
        if wheel > self.max_wheel_reached:
            self.max_wheel_reached = wheel

        if not is_jackpot:
            self.try_advance()
            self.roll_shop()
            self.handle_shop()

        return is_jackpot

    def run(self) -> RunResult:
        for _ in range(self.spin_limit()):
            if self.run_spin():
                break
        return RunResult(
            total_spins=self.total_spins,
            total_time_sec=round(self.total_time_sec, 1),
            final_coins=self.coins,
            max_wheel_reached=self.max_wheel_reached,
            shop_opens=self.shop_opens,
            skills_bought=self.skills_bought,
            coins_spent_shops=self.coins_spent_shops,
            cycles_completed=self.cycle_count,
            won=self.won,
            wheel_spins=tuple(self.wheel_spins[1:]))


# ── Stats Helpers ───────────────────────────────────────────────

def pct(sorted_list, p):
    if not sorted_list:
        return 0.0
    k = (len(sorted_list) - 1) * (p / 100.0)
    f, c = math.floor(k), math.ceil(k)
    if f == c:
        return sorted_list[int(k)]
    return (sorted_list[int(f)] * (c - k) +
            sorted_list[int(c)] * (k - f))


def fmt_time(sec):
    m, s = divmod(int(sec), 60)
    h, m = divmod(m, 60)
    if h > 0:
        return f"{h}h {m}m {s}s"
    return f"{m}m {s}s"


def print_strategy_results(name, results, max_wheel):
    """Print stats for one strategy combo."""
    times = sorted(r.total_time_sec for r in results)
    spins_list = sorted(r.total_spins for r in results)
    coins = sorted(r.final_coins for r in results)

    jackpot_runs = [r for r in results if r.won]
    stuck = sum(1 for r in results if r.total_spins >= (5000 if "none" in name else 99999))
    n = len(results)

    # Median time as primary headline, plus key stats
    med_t = pct(times, 50)
    p25_t = pct(times, 25)
    p75_t = pct(times, 75)
    med_s = pct(spins_list, 50)
    jp_rate = f"{len(jackpot_runs)/n*100:.0f}%" if n else "0%"

    print(f"\n{'─' * 60}")
    print(f"  {name}")
    print(f"{'─' * 60}")
    print(f"  Playtime:  P25={fmt_time(p25_t)} | Median={fmt_time(med_t)} | P75={fmt_time(p75_t)}")
    print(f"  Spins:     P25={pct(spins_list,25):,.0f} | Median={med_s:,.0f} | P75={pct(spins_list,75):,.0f}")
    print(f"  Coins:     Median={pct(coins,50):,.0f} | Mean={sum(coins)/n:,.0f}")
    print(f"  Jackpot:   {len(jackpot_runs)}/{n} ({jp_rate})")
    if stuck > 0:
        print(f"  Stuck:     {stuck}/{n} ({stuck/n*100:.1f}%)")

    # Shop stats (only if shop strategy is active)
    if any(r.skills_bought > 0 for r in results):
        so = sorted(r.shop_opens for r in results)
        sb = sorted(r.skills_bought for r in results)
        ss = sorted(r.coins_spent_shops for r in results)
        print(f"  Shop:      opens={pct(so,50):,.0f} | bought={pct(sb,50):,.0f} | spent={pct(ss,50):,.0f}")

    if results and results[0].wheel_spins:
        wheel_medians = []
        for wheel_idx in range(max_wheel):
            wheel_counts = sorted(r.wheel_spins[wheel_idx] for r in results)
            wheel_medians.append(f"W{wheel_idx + 1}={pct(wheel_counts,50):.0f}")
        print(f"  Wheel med: {' | '.join(wheel_medians)}")


# ── Main ───────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Wheely Lucky Playtime Simulator")
    parser.add_argument("runs", nargs="?", type=int, default=1000)
    parser.add_argument("--shop",
                        choices=["none", "cheap_only", "aggressive", "priority",
                                 "expensive", "max_buy", "prio_maxlevel", "random_afford"],
                        help="Single shop strategy (omit for all)")
    parser.add_argument("--adv", type=str, default=None,
                        help="Single advance policy: 1x, 1.5x, 2x, 2.5x, 3x, etc. (omit for all)")
    parser.add_argument("--gd-only", action="store_true",
                        help="Parse GD files and dump config, skip simulation")
    args = parser.parse_args()

    # ── Parse GD files on every run ─────────────────────────────
    global CFG
    CFG = load_balance_config()

    MAX_WHEEL = len(CFG["wheels"])

    if args.gd_only:
        dump_config(CFG)
        return

    # ── Determine strategy combos ───────────────────────────────
    shop_strats = ["none", "cheap_only", "aggressive", "priority",
                   "expensive", "max_buy", "prio_maxlevel", "random_afford"]
    adv_policies = ["1x", "1.5x", "2x", "2.5x", "3x", "4x"]

    if args.shop:
        shop_strats = [args.shop]
    if args.adv:
        adv_policies = [args.adv]

    combos = list(iter_product(shop_strats, adv_policies))

    runs_each = args.runs // len(combos)

    print(f"Wheely Lucky - Playtime Simulator")
    print(f"  Config source:     GD files (parsed live)")
    print(f"  Total runs:        {args.runs:,} ({runs_each} per combo)")
    print(f"  Shop strategies:   {', '.join(shop_strats)}")
    print(f"  Advance policies:  {', '.join(adv_policies)}")
    print(f"  Combos:            {len(combos)}")
    print(f"  Spin Duration:     {CFG['base_spin_dur']}s base")
    print(f"  Wheel Costs:       {', '.join(f'W{k}={v}' for k, v in sorted(CFG['wheel_costs'].items()))}")
    print()

    all_results = {}
    total_done = 0

    for shop_s, adv_p in combos:
        name = f"shop={shop_s:>12} | adv={adv_p}"

        results = []
        # Run enough to hit target total, last combo gets remainder
        count = runs_each if total_done + runs_each <= args.runs else (args.runs - total_done)
        if count < 10:
            count = 10

        for _ in range(count):
            game = SimGame(shop_strategy=shop_s, advance_policy=adv_p)
            results.append(game.run())
        total_done += count

        all_results[name] = results
        print(f"[{total_done}/{args.runs}] {name} -> median={fmt_time(pct(sorted(r.total_time_sec for r in results), 50))}")

    # ── Full breakdown ──────────────────────────────────────────
    print()
    print("=" * 60)
    print("FULL RESULTS")
    print("=" * 60)

    for name, results in all_results.items():
        print_strategy_results(name, results, MAX_WHEEL)

    # ── Quick comparison table (text) ───────────────────────────
    print()
    print("=" * 60)
    print("COMPARISON (Median Playtime)")
    print("=" * 60)

    rows = []
    for name, results in all_results.items():
        times = sorted(r.total_time_sec for r in results)
        med = pct(times, 50)
        jp_count = sum(1 for r in results if r.won)
        jp_pct = f"{jp_count/len(results)*100:.0f}%"
        rows.append((name, med, jp_pct))

    # Sort by median time
    rows.sort(key=lambda x: x[1])
    for rank, (name, med, jp_rate) in enumerate(rows, 1):
        marker = " <-- fastest" if rank == 1 else ""
        print(f"  #{rank}  {fmt_time(med)}  | {jp_rate} jackpot  | {name}{marker}")

    print()
    print("Done.")


if __name__ == "__main__":
    main()
