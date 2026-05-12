# Wheely Lucky — Game Design & Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Build a 10-wheel spinning coin game with escalating costs, increasing multiplier odds, upgradeable/unique skills, and a dramatic jackpot finale. Game loops through wheels 1-10 repeatedly until the player hits the 1% jackpot on wheel 10.

**Architecture:** Godot 4.x, GDScript. `Game` autoload for global state, `WheelConfig` singleton for wheel data, `WheelScene` for spin visuals, `ShopScene` overlay for upgrades, `ResultPopup` for feedback.

**Tech Stack:** Godot 4.4+ (MIT), GDScript, Git

---

## Confirmed Mechanics

| # | Mechanic | Detail |
|---|----------|--------|
| 1 | Starting coins | **0** — earn first from free Wheel 1 |
| 2 | Wheel costs | **Escalating** — each wheel costs more than the last (exact values TBD) |
| 3 | Multiplier odds | **Increase with wheel number** — multipliers appear mid-game, get more common |
| 4 | Weight system | **Weighted segments summing to 100** — chance = segment_weight / 100 |
| 5 | Wheel 10 | **1% jackpot (game ends) / 99% loss (continue from wheel 1)** |
| 6 | Shop | **Every 5 spins** — spins 5, 10, 15, 20... across all cycles |
| 7 | Upgrade cost | **base × (2n - 1)** where n = level being purchased (Lv1: ×1, Lv2: ×3, Lv3: ×5...) |
| 8 | Runs | **Fresh start** — no meta-progression, each run is independent |
| 9 | Game loop | **Wheels 1→10→1→10... repeats until jackpot on wheel 10** |

---

## Core Game Loop

```
[Start: coins=0, wheel=1]
       ↓
[Spin wheel N] → [Pay cost] → [Land on outcome] → [Apply modifier to coins]
       ↓                                              ↓
  [total_spins += 1]                         [Check: coins == 0?]
       ↓                                              ↓
[total_spins % 5 == 0?] ←── Yes → [Second Wind skill?] ←── [Floor: coins >= 0]
       ↓                                              ↓
   Yes → [SHOP opens]                    [No: stay at 0, game continues]
       ↓                                              ↓
[Close shop] → [Continue spinning]
       ↓
[Wheel 10 landed?] → Yes → [Outcome?]
                           ├── 1% Jackpot → GAME ENDS → End screen
                           └── 99% Loss → Apply loss → [Wheel = 1, continue]
       ↓
[Wheel N + 1] → [Back to spin]
```

**Key insight:** You cycle through wheels 1-10 repeatedly. Each cycle costs you (wheel costs + potential losses). You need enough coins to afford the escalating costs while surviving wheel 10's 99% loss. The game only ends when you get lucky on wheel 10's 1% jackpot.

---

## Wheel Progression (Structure Only — Balances TBD)

Exact weights, costs, and values will be determined during a **balance pass** after the core systems are functional.

| Wheel | Cost | Choices | Multiplier Odds | Notes |
|-------|------|---------|-----------------|-------|
| 1 | Free | 2 | 0% | Tutorial, risk-free |
| 2-3 | Low | 3 | 0% | Build coins, first risk |
| 4-5 | Medium | 4 | Low | First multipliers, **shop after spin 5** |
| 6-7 | Higher | 5 | Moderate | More outcome variety |
| 8-9 | High | 6 | High | Two multipliers, high stakes |
| 10 | Highest | 2 | 1% jackpot | **Game ends on jackpot, loops on loss** |

### Wheel 10 — The Jackpot

- **Jackpot (weight 1 = 1%)**: Big positive outcome → **GAME ENDS**
- **Loss (weight 99 = 99%)**: Large negative outcome → **Continue from wheel 1**
- End screen only shows when jackpot is hit

### Balance Pass (TBD — Task 16)

Once all systems work, playtest and tune:
- Wheel costs (escalating curve)
- Outcome weights per wheel (summing to 100)
- Outcome values (+/-/×// amounts)
- Skill effect magnitudes
- Skill purchase costs
- Shop timing feels right
- Overall expected number of spins to jackpot
- Risk/reward curve across cycles

---

## Coin System

Operations applied to coin balance:

| Type | Symbol | Example | Formula | Notes |
|------|--------|---------|---------|-------|
| Add | + | +15 | `coins += value` | Straightforward |
| Subtract | - | -10 | `coins -= value`, min 0 | Never go negative |
| Multiply | × | ×3 | `coins *= value` | Big wins! |
| Divide | / | /2 | `coins = floor(coins / 2)` | Painful |
| None | 0 | — | no change | Safe option |

**Floor:** Coins never go below 0.

---

## Skills System

### Upgradeable Skills

Cost formula: `purchase_cost = base_cost × (2n - 1)` where n = level being purchased.

| Skill | Effect | Max |
|-------|--------|-----|
| Lucky Charm | +weight to positive outcomes per level (shifted from 0/-) | 10 |
| Quick Spin | -spin duration per level | 5 |
| Iron Skin | Reduce subtract/divide effect per level | 10 |
| Coin Magnet | +to all add values per level | 10 |
| Sharp Mind | +to multiply values per level | 5 |

### Unique Skills (one-time, non-upgradeable)

| Skill | Effect |
|-------|--------|
| Double Down | 2× all positive outcome values |
| Risk Taker | Remove all "0" outcomes, redistribute weights |
| Fortune's Favor | Once per run: if you land on negative, reroll once |
| Banker | Divide outcomes lose max 1 coin |
| Second Wind | If coins hit 0, restore to 10 once per run |

**Note:** All skill costs TBD — set during balance pass.

---

## Shop Mechanics

- **Appears every 5 spins total** (spins 5, 10, 15, 20...)
- Can appear **multiple times** across wheel cycles (e.g., spin 5 in cycle 1, spin 10 in cycle 1, spin 15 in cycle 2...)
- Shows all available skills player can afford
- Skills apply immediately
- Shop is a `CanvasLayer` overlay — blocks interaction, has close button

---

## Visual Design (MVP)

- **Wheel:** Circular, colored segments drawn via `_draw()`, pointer/arrow at top
- **Spin animation:** Ease-out cubic, 2-3 full rotations before settling
- **Coin counter:** Top-center, large, rolls up on change
- **Wheel progress:** "Wheel 3 / 10" indicator + cycle counter
- **Result popup:** "+15" (green), "-10" (red), "×3" (gold), "0" (gray)
- **Wheel 10 special:** Dramatic visual — screen darkens, wheel glows, jackpot triggers particles
- **Cycle indicator:** "Cycle 2" or similar to show how many times through 1-10 you've gone

---

## Project Structure

```
wheelylucky/
├── PLAN.md
├── project.godot
├── scenes/
│   ├── main.tscn              # Main game scene (wheel + UI)
│   ├── wheel.tscn             # Spinning wheel with draw logic
│   ├── shop.tscn              # Shop overlay (CanvasLayer)
│   ├── result_popup.tscn      # Result display popup
│   └── end_screen.tscn        # Game over screen (jackpot only)
├── scripts/
│   ├── game.gd                # Autoload: coins, wheel progress, spins, skills
│   ├── wheel_config.gd        # Wheel definitions: outcomes, weights, costs
│   ├── wheel.gd               # Spin logic, animation, result calculation
│   ├── skill_manager.gd       # Skill definitions, costs, effects
│   ├── shop.gd                # Shop overlay, purchase logic
│   ├── result_popup.gd        # Result popup animation
│   ├── end_screen.gd          # End game screen
│   └── save_manager.gd        # Save/load (best score)
├── assets/
│   ├── icons/
│   │   ├── coin.svg
│   │   └── wheel_pointer.svg
│   └── sounds/
│       ├── spin.ogg
│       ├── result_positive.ogg
│       ├── result_negative.ogg
│       ├── jackpot.ogg
│       └── shop_open.ogg
└── exports/
```

---

## Implementation Tasks

### Phase 0: Project Setup

#### Task 1: Create Godot project structure

**Files:**
- Create: `project.godot`, directory structure
- Initialize: git repo

**Steps:**
1. Create `project.godot` with Godot 4 format
   - Name: "Wheely Lucky"
   - Config: 2D, 1280×720
2. Create directories: `scenes/`, `scripts/`, `assets/icons/`, `assets/sounds/`
3. `git init`, `.gitignore` (add `*.import`, `.godot/`, `export_presets.cfg`)
4. Initial commit: `feat: initialize Godot 4 project`

**Verify:** Open in Godot — no errors, project loads cleanly

---

#### Task 2: Create Game autoload (global state)

**Files:**
- Create: `scripts/game.gd`
- Modify: `project.godot` — add as autoload (path: `*res://scripts/game.gd`)

**Code:**
```gdscript
# scripts/game.gd
extends Node

signal coins_changed(new_total)
signal wheel_changed(current_wheel)
signal spin_completed
signal shop_requested
signal game_ended(final_coins)

var coins: int = 0:
    set(value):
        coins = max(0, value)
        coins_changed.emit(coins)

var current_wheel: int = 1
var total_spins: int = 0
var cycle_count: int = 1  # How many times through 1-10 we've gone
const MAX_WHEELS: int = 10
const SHOP_INTERVAL: int = 5  # Every 5 spins

# Skill state
var skill_levels: Dictionary = {
    "lucky_charm": 0,
    "quick_spin": 0,
    "iron_skin": 0,
    "coin_magnet": 0,
    "sharp_mind": 0,
}
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
    return coins >= get_wheel_cost(wheel_num)

func spin_wheel() -> Dictionary:
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
        # Check if this was the jackpot outcome
        if outcome.op_type == WheelConfig.OP_MULTIPLY and outcome.value >= 10.0:
            # Jackpot hit!
            game_over = true
            is_jackpot = true
            game_ended.emit(coins)

    # Advance to next wheel
    if not game_over:
        if current_wheel == MAX_WHEELS:
            # Wheel 10 loss — loop back to wheel 1
            current_wheel = 1
            cycle_count += 1
        else:
            current_wheel += 1
        wheel_changed.emit(current_wheel)

    spin_completed.emit()

    return {
        "success": true,
        "delta": delta,
        "outcome_label": outcome.label if outcome else "?",
        "outcome_color": outcome.color if outcome else Color.WHITE,
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
```

**Verify:** Godot loads autoload, signals fire, coin math works, shop timing correct (every 5 spins across cycles), game only ends on wheel 10 jackpot

---

### Phase 1: Wheel Data & Logic

#### Task 3: Create wheel configuration data

**Files:**
- Create: `scripts/wheel_config.gd`

**Design:**
- `WheelOutcome` class: label, op_type, value, weight, color
- `WHEELS` dictionary: wheel_num → Array[WheelOutcome]
- All weights sum to 100 per wheel
- Wheel 10: weight 1 (jackpot) + weight 99 (loss)
- Exact values/weights TBD — use placeholder values for now, balance in Task 16

**Code skeleton:**
```gdscript
# scripts/wheel_config.gd
extends RefCounted

const OP_ADD = 0
const OP_SUBTRACT = 1
const OP_MULTIPLY = 2
const OP_DIVIDE = 3
const OP_NONE = 4

class WheelOutcome:
    var label: String
    var op_type: int
    var value: float
    var weight: float
    var color: Color

# Colors
const POSITIVE = Color(0.2, 0.8, 0.3)
const SAFE = Color(0.5, 0.5, 0.5)
const NEGATIVE = Color(0.8, 0.2, 0.2)
const MULTIPLY = Color(0.8, 0.7, 0.1)
const DIVIDE = Color(0.6, 0.3, 0.8)
const JACKPOT = Color(1.0, 0.85, 0.0)

# Placeholder wheel data — balances will be tuned in Task 16
# Each wheel's outcome weights sum to 100
# Costs escalate per wheel

static func get_cost(wheel_num: int) -> int:
    # Placeholder — exact curve TBD in balance pass
    if wheel_num == 1:
        return 0
    # Quadratic-ish: 5, 8, 12, 17, 23, 30, 38, 47, 60
    return 5 + (wheel_num - 2) * (wheel_num - 1)

static func get_outcomes(wheel_num: int) -> Array:
    # Returns deep copy of wheel outcomes for the given wheel
    # Placeholder data below — will be filled in balance pass
    match wheel_num:
        1:
            return [
                _mo("+1", OP_ADD, 1.0, 60.0, POSITIVE),
                _mo("0", OP_NONE, 0.0, 40.0, SAFE),
            ]
        2:
            return [
                _mo("+10", OP_ADD, 10.0, 45.0, POSITIVE),
                _mo("0", OP_NONE, 0.0, 35.0, SAFE),
                _mo("-5", OP_SUBTRACT, 5.0, 20.0, NEGATIVE),
            ]
        # ... wheels 3-9 TBD in balance pass
        10:
            return [
                _mo("×10", OP_MULTIPLY, 10.0, 1.0, JACKPOT),
                _mo("-50%", OP_DIVIDE, 2.0, 99.0, NEGATIVE),
            ]
        _:
            return get_outcomes(1)

static func _mo(label, op_type, value, weight, color):
    var o = WheelOutcome.new()
    o.label = label
    o.op_type = op_type
    o.value = value
    o.weight = weight
    o.color = color
    return o

static func calculate_outcome(wheel_num: int, game: Node) -> Dictionary:
    var outcomes = get_outcomes(wheel_num)
    outcomes = apply_skill_modifiers(outcomes, game)
    var chosen = weighted_random(outcomes)

    # Fortune's Favor: reroll if negative
    if chosen.op_type in [OP_SUBTRACT, OP_DIVIDE]:
        if game.use_fortunes_favor():
            var safe = [o for o in outcomes if o.op_type not in [OP_SUBTRACT, OP_DIVIDE]]
            if safe.size() > 0:
                chosen = weighted_random(safe)

    var delta = apply_outcome(chosen, game.coins, game)
    return {"delta": delta, "outcome": chosen}

static func apply_skill_modifiers(outcomes: Array, game: Node) -> Array:
    # Lucky Charm: shift weight from 0/- to positive
    # Risk Taker: remove 0 outcomes, redistribute
    pass  # Implemented in Task 7

static func weighted_random(outcomes: Array) -> WheelOutcome:
    var total_weight = 0.0
    for o in outcomes:
        total_weight += o.weight
    if total_weight <= 0:
        return outcomes[0]
    var roll = randf() * total_weight
    var cumulative = 0.0
    for o in outcomes:
        cumulative += o.weight
        if roll <= cumulative:
            return o
    return outcomes[-1]

static func apply_outcome(outcome: WheelOutcome, current_coins: int, game: Node) -> int:
    # Apply operation, then skill modifiers (Coin Magnet, Iron Skin, Sharp Mind, Double Down, Banker)
    pass  # Implemented in Task 7
```

**Verify:**
- Each wheel's weights sum to 100 ✓
- `weighted_random` returns valid outcome
- `calculate_outcome` returns correct delta
- Cost function returns escalating values

---

#### Task 4: Build wheel visual scene

**Files:**
- Create: `scenes/wheel.tscn`

**Scene tree:**
```
Wheel (Control, 400x400, centered)
├── Pointer (Control, top center, triangle pointing down)
├── CenterLabel (Label, "SPIN")
├── WheelNumber (Label, "Wheel 3/10", above wheel)
├── CycleLabel (Label, "Cycle 1", above wheel number)
├── CostDisplay (Label, "Cost: 12", below wheel)
├── CoinsDisplay (Label, "Coins: 45", top center)
└── SpinButton (Button, "SPIN", below wheel)
```

**Steps:**
1. Create Control root (400×400, anchor center)
2. Add pointer at top center
3. Add labels for cycle count, wheel number, cost, coins
4. Add spin button below wheel
5. Attach `scripts/wheel.gd`
6. `queue_redraw()` in `_ready()` draws wheel segments via `_draw()`

**Verify:** Scene loads in editor, wheel renders as colored pie chart with pointer

---

#### Task 5: Implement wheel spin animation & logic

**Files:**
- Create: `scripts/wheel.gd`

**Key behavior:**
- On spin button click: check can afford → start spin animation → calculate result → animate to result segment → show popup
- Animation: ease-out cubic, 3-5 full rotations
- Spin duration affected by Quick Spin skill
- Result popup shows delta with color coding

**Code:**
```gdscript
# scripts/wheel.gd
extends Control

@export var cycle_label: Label
@export var wheel_number_label: Label
@export var cost_label: Label
@export var coins_label: Label
@export var spin_button: Button
@export var pointer: Control

var is_spinning: bool = false
var current_rotation: float = 0.0
var target_rotation: float = 0.0
var spin_start_time: float = 0.0
var base_spin_duration: float = 2.5

func _ready():
    Game.coins_changed.connect(_on_coins_changed)
    Game.wheel_changed.connect(_on_wheel_changed)
    spin_button.pressed.connect(_on_spin_pressed)
    Game.spin_completed.connect(_on_spin_completed)

    _on_wheel_changed(Game.current_wheel)
    _on_coins_changed(Game.coins)
    queue_redraw()

func _process(delta):
    if is_spinning:
        var elapsed = Time.get_ticks_msec() / 1000.0 - spin_start_time
        var duration = get_effective_spin_duration()
        var progress = min(elapsed / duration, 1.0)

        var eased = 1.0 - pow(1.0 - progress, 3)
        current_rotation = target_rotation * eased
        queue_redraw()

        if progress >= 1.0:
            is_spinning = false

func get_effective_spin_duration() -> float:
    var quick_level = Game.skill_levels.get("quick_spin", 0)
    return base_spin_duration * pow(0.88, quick_level)

func _on_spin_pressed():
    if is_spinning:
        return

    if not Game.can_afford_wheel(Game.current_wheel):
        return

    start_spin()

func start_spin():
    is_spinning = true
    spin_button.disabled = true
    spin_start_time = Time.get_ticks_msec() / 1000.0

    # Pre-calculate which segment to land on
    var outcomes = WheelConfig.get_outcomes(Game.current_wheel)
    var result = WheelConfig.calculate_outcome(Game.current_wheel, Game)
    var chosen = result["outcome"]

    # Find segment index
    var chosen_index = -1
    for i in range(outcomes.size()):
        if outcomes[i].label == chosen.label and outcomes[i].op_type == chosen.op_type:
            chosen_index = i
            break

    # Calculate target angle
    if chosen_index >= 0:
        var segment_angle = 360.0 / outcomes.size()
        var segment_center = chosen_index * segment_angle + segment_angle / 2.0
        var jitter = randf_range(-segment_angle * 0.3, segment_angle * 0.3)
        var target_segment = segment_center + jitter
        var full_rotations = randi_range(3, 5) * 360
        target_rotation = full_rotations + (360 - target_segment + 270) % 360
    else:
        target_rotation = randi_range(3, 5) * 360

    current_rotation = 0.0

func _on_spin_completed():
    spin_button.disabled = false
    current_rotation = 0.0
    queue_redraw()

func _on_coins_changed(total: int):
    coins_label.text = str(total)
    spin_button.disabled = not Game.can_afford_wheel(Game.current_wheel) or is_spinning

func _on_wheel_changed(wheel_num: int):
    wheel_number_label.text = "Wheel " + str(wheel_num) + " / 10"
    cycle_label.text = "Cycle " + str(Game.cycle_count)
    var cost = Game.get_wheel_cost(wheel_num)
    cost_label.text = "FREE" if cost == 0 else "Cost: " + str(cost)
    spin_button.disabled = not Game.can_afford_wheel(wheel_num)
    queue_redraw()

func _draw():
    var wheel_outcomes = WheelConfig.get_outcomes(Game.current_wheel)
    var rect = get_rect()
    var center = rect.position + rect.size / 2.0
    var radius = rect.size.x / 2.0 - 4.0

    if wheel_outcomes.size() == 0:
        return

    var segment_angle = TAU / wheel_outcomes.size()
    var rotation_rad = deg_to_rad(current_rotation)

    for i in range(wheel_outcomes.size()):
        var outcome = wheel_outcomes[i]
        var start_angle = i * segment_angle + rotation_rad
        var end_angle = start_angle + segment_angle

        var points = PackedVector2Array()
        points.append(center)

        for j in range(33):
            var angle = start_angle + (end_angle - start_angle) * (float(j) / 32.0)
            points.append(center + Vector2(cos(angle), sin(angle)) * radius)

        draw_colored_polygon(points, outcome.color)

        for j in range(points.size() - 1):
            draw_line(points[j], points[j + 1], Color.BLACK, 1.0)

    # Draw labels
    for i in range(wheel_outcomes.size()):
        var outcome = wheel_outcomes[i]
        var mid_angle = i * segment_angle + segment_angle / 2.0 + rotation_rad
        var label_pos = center + Vector2(cos(mid_angle), sin(mid_angle)) * (radius * 0.65)

        draw_string(
            ThemeDB.fallback_font,
            label_pos,
            outcome.label,
            HORIZONTAL_ALIGNMENT_CENTER,
            -1,
            16,
            Color.WHITE
        )
```

**Verify:**
- Wheel renders as colored pie chart
- Clicking spin triggers 3-5 rotation ease-out animation
- Wheel stops on correct outcome segment
- Coin display updates after spin
- Cycle counter increments after wheel 10 loss

---

#### Task 6: Build result popup

**Files:**
- Create: `scenes/result_popup.tscn`
- Create: `scripts/result_popup.gd`

**Scene tree:**
```
ResultPopup (CanvasLayer)
├── Background (ColorRect, transparent)
└── VBoxContainer
    ├── ResultLabel (Label, large, centered)
    └── TotalLabel (Label, smaller, "Total: XX")
```

**Code:**
```gdscript
# scripts/result_popup.gd
extends CanvasLayer

@export var result_label: Label
@export var total_label: Label

func show_result(delta: int, outcome_color: Color):
    if delta > 0:
        result_label.text = "+" + str(delta)
    elif delta < 0:
        result_label.text = str(delta)
    else:
        result_label.text = "—"

    result_label.add_theme_color_override("font_color", outcome_color)
    total_label.text = "Total: " + str(Game.coins)

    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
    tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
    tween.tween_property(self, "modulate:a", 0.0, 1.5)
    tween.tween_callback(queue_free)

func _ready():
    anchor_left = 0.5
    anchor_top = 0.5
    anchor_right = 0.5
    anchor_bottom = 0.5
    offset_left = -100
    offset_top = -50
    offset_right = 100
    offset_bottom = 50
```

**Verify:** Popup shows result with correct color, scales in, fades out after 1.5s

---

### Phase 2: Skills & Shop

#### Task 7: Implement skill effects

**Files:**
- Modify: `scripts/wheel_config.gd` — implement `apply_skill_modifiers()` and `apply_outcome()` fully

**Implementations:**

**`apply_skill_modifiers(outcomes, game)`:**
1. **Lucky Charm** (level): shift weight from 0/- outcomes to positive outcomes
   - Per level: 2% weight shifted from neutral/negative to positive
2. **Risk Taker** (unique): remove all OP_NONE outcomes, redistribute their weight proportionally to remaining outcomes

**`apply_outcome(outcome, coins, game)`:**
1. **Coin Magnet** (level): `+10% per level` to OP_ADD values
2. **Iron Skin** (level): `-10% per level` to OP_SUBTRACT and OP_DIVIDE values (floor at 10% remaining)
3. **Sharp Mind** (level): `+25% per level` to OP_MULTIPLY multiplier value
4. **Double Down** (unique): 2× the positive delta
5. **Banker** (unique): OP_DIVIDE can only take 1 coin max

```gdscript
static func apply_skill_modifiers(outcomes: Array, game: Node) -> Array:
    # Lucky Charm: shift weight
    var lucky_level = game.skill_levels.get("lucky_charm", 0)
    if lucky_level > 0:
        var shift_total = 2.0 * lucky_level  # 2% per level
        var positives = []
        var negatives = []
        for o in outcomes:
            if o.op_type in [OP_ADD, OP_MULTIPLY]:
                positives.append(o)
            else:
                negatives.append(o)

        if positives.size() > 0:
            var shift_per_positive = shift_total / positives.size()
            var available = 0.0
            for o in negatives:
                var take = min(o.weight, shift_per_positive)
                o.weight -= take
                available += take
            for o in positives:
                o.weight += available / positives.size()

    # Risk Taker: remove 0 outcomes
    if "risk_taker" in game.unique_skills:
        var new_outcomes = []
        var zero_weight = 0.0
        for o in outcomes:
            if o.op_type == OP_NONE:
                zero_weight += o.weight
            else:
                new_outcomes.append(o)
        outcomes = new_outcomes
        if zero_weight > 0:
            var total = 0.0
            for o in outcomes:
                total += o.weight
            if total > 0:
                for o in outcomes:
                    o.weight += zero_weight * (o.weight / total)

    return outcomes

static func apply_outcome(outcome: WheelOutcome, current_coins: int, game: Node) -> int:
    var result: float = float(current_coins)

    match outcome.op_type:
        OP_ADD:
            var magnet = game.skill_levels.get("coin_magnet", 0)
            result = current_coins + outcome.value * (1.0 + 0.10 * magnet)
        OP_SUBTRACT:
            var iron = game.skill_levels.get("iron_skin", 0)
            var iron_mult = max(0.1, 1.0 - 0.10 * iron)
            result = current_coins - outcome.value * iron_mult
        OP_MULTIPLY:
            if current_coins == 0:
                result = outcome.value
            else:
                var sharp = game.skill_levels.get("sharp_mind", 0)
                result = current_coins * outcome.value * (1.0 + 0.25 * sharp)
        OP_DIVIDE:
            if "banker" in game.unique_skills:
                result = current_coins - 1.0
            else:
                var iron = game.skill_levels.get("iron_skin", 0)
                var iron_mult = max(0.1, 1.0 - 0.10 * iron)
                result = current_coins / max(1.0, outcome.value * iron_mult)
        OP_NONE:
            result = float(current_coins)

    # Double Down
    if "double_down" in game.unique_skills:
        if result > current_coins:
            result = current_coins + (result - current_coins) * 2

    return int(result) - current_coins
```

**Verify:** Each skill modifies outcomes correctly in isolation, combined skills stack properly

---

#### Task 8: Create skill manager

**Files:**
- Create: `scripts/skill_manager.gd`

**Code:**
```gdscript
# scripts/skill_manager.gd
extends RefCounted

class SkillDef:
    var id: String
    var name: String
    var description: String
    var base_cost: int
    var max_level: int  # 0 = unique
    var category: String

const UPGRADEABLE_SKILLS: Array = [
    {"id": "lucky_charm", "name": "Lucky Charm", "desc": "+2% positive weight per level", "base": 10, "max": 10},
    {"id": "quick_spin", "name": "Quick Spin", "desc": "-12% spin duration per level", "base": 5, "max": 5},
    {"id": "iron_skin", "name": "Iron Skin", "desc": "-10% negative effect per level", "base": 8, "max": 10},
    {"id": "coin_magnet", "name": "Coin Magnet", "desc": "+10% add values per level", "base": 7, "max": 10},
    {"id": "sharp_mind", "name": "Sharp Mind", "desc": "+25% multiply values per level", "base": 6, "max": 5},
]

const UNIQUE_SKILLS: Array = [
    {"id": "double_down", "name": "Double Down", "desc": "2x all positive outcomes", "base": 100, "max": 0},
    {"id": "risk_taker", "name": "Risk Taker", "desc": "Remove all 0 outcomes", "base": 75, "max": 0},
    {"id": "fortunes_favor", "name": "Fortune's Favor", "desc": "Reroll negatives once per run", "base": 150, "max": 0},
    {"id": "banker", "name": "Banker", "desc": "Divide loses max 1 coin", "base": 50, "max": 0},
    {"id": "second_wind", "name": "Second Wind", "desc": "Restore 10 coins at 0, once", "base": 80, "max": 0},
]

static func get_all_skills() -> Array:
    return UPGRADEABLE_SKILLS + UNIQUE_SKILLS

static func get_skill_by_id(id: String):
    for skill in get_all_skills():
        if skill["id"] == id:
            return skill
    return null

static func get_purchase_cost(skill: Dictionary, current_level: int) -> int:
    if skill["max"] == 0:  # unique
        return skill["base"]
    var next_level = current_level + 1
    return int(skill["base"] * (2.0 * next_level - 1.0))
```

**Verify:**
- `get_purchase_cost(skill, 0)` → `base × 1`
- `get_purchase_cost(skill, 1)` → `base × 3`
- `get_purchase_cost(skill, 2)` → `base × 5`

---

#### Task 9: Build shop scene

**Files:**
- Create: `scenes/shop.tscn`

**Scene tree:**
```
Shop (CanvasLayer, layer=10)
├── Background (ColorRect, rgba(0,0,0,0.85), full screen)
├── VBoxContainer (centered)
│   ├── TitleLabel ("SHOP")
│   ├── CoinsLabel ("Coins: XX")
│   ├── HSeparator
│   ├── ScrollContainer (flex)
│   │   └── SkillsVBox (VBoxContainer)
│   └── ContinueButton ("Continue")
```

**Steps:**
1. CanvasLayer, layer 10
2. Dark overlay background
3. Scrollable skill list container
4. Close/continue button
5. Attach `scripts/shop.gd`

**Verify:** Opens as overlay, blocks wheel interaction

---

#### Task 10: Implement shop logic

**Files:**
- Create: `scripts/shop.gd`

**Code:**
```gdscript
# scripts/shop.gd
extends CanvasLayer

@export var skills_container: VBoxContainer
@export var coins_label: Label
@export var continue_button: Button

func _ready():
    continue_button.pressed.connect(_on_close)
    Game.coins_changed.connect(_on_coins_changed)
    _populate_skills()
    _on_coins_changed(Game.coins)

func _populate_skills():
    for child in skills_container.get_children():
        child.queue_free()

    for skill in SkillManager.get_all_skills():
        var level = Game.skill_levels.get(skill["id"], 0)
        var owned = skill["id"] in Game.unique_skills

        if owned:
            continue
        if skill["max"] > 0 and level >= skill["max"]:
            continue

        var cost = SkillManager.get_purchase_cost(skill, level)
        var can_afford = Game.coins >= cost

        var row = HBoxContainer.new()
        row.custom_minimum_size = Vector2(0, 50)

        var name = Label.new()
        name.text = skill["name"]
        if level > 0:
            name.text += " (Lv." + str(level) + ")"
        name.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        row.add_child(name)

        var desc = Label.new()
        desc.text = skill["desc"]
        desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
        desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(desc)

        var cost_lbl = Label.new()
        cost_lbl.text = str(cost)
        cost_lbl.size_flags_horizontal = Control.SIZE_SHRINK_END
        cost_lbl.alignment = HORIZONTAL_ALIGNMENT_RIGHT
        row.add_child(cost_lbl)

        var buy_btn = Button.new()
        buy_btn.text = "Buy"
        buy_btn.disabled = not can_afford
        buy_btn.custom_minimum_size = Vector2(60, 30)
        buy_btn.pressed.connect(_on_buy.bind(skill))
        row.add_child(buy_btn)

        skills_container.add_child(row)

func _on_buy(skill: Dictionary):
    var level = Game.skill_levels.get(skill["id"], 0)
    var cost = SkillManager.get_purchase_cost(skill, level)
    if Game.buy_skill(skill["id"], cost):
        _populate_skills()

func _on_coins_changed(total: int):
    coins_label.text = "Coins: " + str(total)
    _populate_skills()

func _on_close():
    queue_free()
```

**Verify:** Lists skills, purchases work, costs follow 2n-1 formula, refreshes on purchase

---

#### Task 11: Wire shop to game loop

**Files:**
- Modify: `scenes/main.tscn`
- Modify: `scripts/game.gd`

**Steps:**
1. Main scene listens for shop trigger after spin completes
2. When `spin_wheel()` returns `show_shop=true`, instantiate shop scene
3. Block spin button while shop is open
4. On shop close (queue_free), re-enable spin button
5. Shop timing: every 5 spins (spins 5, 10, 15, 20...) — can fire multiple times across cycles

**Verify:** Shop opens every 5 spins, blocks wheel, closes normally, spin continues

---

### Phase 3: End Game & Polish

#### Task 12: Build end screen

**Files:**
- Create: `scenes/end_screen.tscn`
- Create: `scripts/end_screen.gd`

**Scene tree:**
```
EndScreen (CanvasLayer, layer=20)
├── Background (ColorRect, dark)
├── VBoxContainer (centered)
│   ├── TitleLabel ("JACKPOT! 🎰")
│   ├── FinalCoinsLabel ("Final Score: XXX")
│   ├── StatsLabel ("Spins: X | Cycles: X | Skills: X")
│   ├── RatingLabel (stars)
│   └── RestartButton ("Play Again")
```

**Code:**
```gdscript
# scripts/end_screen.gd
extends CanvasLayer

@export var title_label: Label
@export var final_coins_label: Label
@export var stats_label: Label
@export var rating_label: Label
@export var restart_button: Button

func _ready():
    final_coins_label.text = "Final Score: " + str(Game.coins) + " coins"
    stats_label.text = "Spins: " + str(Game.total_spins) + \
        " | Cycles: " + str(Game.cycle_count) + \
        " | Skills: " + str(Game.unique_skills.size()) + " unique"

    var rating = calculate_rating(Game.coins)
    rating_label.text = "⭐" * rating

    restart_button.pressed.connect(_on_restart)

func calculate_rating(coins: int) -> int:
    # Thresholds TBD in balance pass
    if coins >= 500: return 5
    if coins >= 200: return 4
    if coins >= 100: return 3
    if coins >= 50: return 2
    return 1

func _on_restart():
    Game.reset_run()
    queue_free()
```

**Verify:** Shows only on wheel 10 jackpot, displays score + cycles, restart resets everything

---

#### Task 13: Build main scene with complete UI

**Files:**
- Create: `scenes/main.tscn`
- Modify: `project.godot` — set main scene

**Scene tree:**
```
Main (Control, 1280x720)
├── Background (ColorRect, dark)
├── TopBar (HBoxContainer)
│   ├── TitleLabel ("Wheely Lucky")
│   └── CoinsDisplay (Label, large, "0")
├── WheelContainer (CenterContainer)
│   └── Wheel (instance of wheel.tscn)
├── BottomBar (below wheel)
│   ├── WheelInfo ("Wheel 1/10 — Cycle 1 — Cost: Free")
│   └── SpinButton ("SPIN")
└── StatsPanel (right side)
    ├── "Total Spins: 0"
    ├── "Cycles: 1"
    ├── "Skills: 0"
    └── "Best Score: 0"
```

**Steps:**
1. Control root (1280×720)
2. Dark background
3. Coin display top-center
4. Instance wheel scene, centered
5. Spin button below wheel
6. Stats panel right side (total spins, cycles, skills, best score)
7. Set as main scene in `project.godot`
8. Wire signals:
   - `Game.spin_completed` → show result popup
   - `Game.shop_requested` (via `show_shop` flag) → instantiate shop
   - `Game.game_ended` → instantiate end screen (only on jackpot)
   - End screen close → `Game.reset_run()`

**Verify:** Complete UI, all elements positioned, full game loop works (cycles through 1-10 repeatedly, ends only on jackpot)

---

#### Task 14: Add sounds

**Files:**
- Create: `assets/sounds/spin.ogg`
- Create: `assets/sounds/result_positive.ogg`
- Create: `assets/sounds/result_negative.ogg`
- Create: `assets/sounds/jackpot.ogg`
- Create: `assets/sounds/shop_open.ogg`

**Steps:**
1. Generate simple placeholder sounds (Python or Godot AudioStreamGenerator)
2. Add `AudioStreamPlayer` nodes:
   - `spin_sound` — on spin start
   - `result_sound_positive` — on positive result
   - `result_sound_negative` — on negative result
   - `jackpot_sound` — on wheel 10 jackpot
3. Trigger in `wheel.gd` and `end_screen.gd`

**Verify:** Sounds play on spin, result, jackpot, shop open

---

#### Task 15: Add save/load (best score)

**Files:**
- Create: `scripts/save_manager.gd`

**Code:**
```gdscript
# scripts/save_manager.gd
extends Node

const SAVE_PATH = "user://savegame.cfg"
var config: ConfigFile

func _ready():
    config = ConfigFile.new()
    load()

func save():
    config.save(SAVE_PATH)

func load():
    config.load(SAVE_PATH)

func get_best_score() -> int:
    return config.get_value("game", "best_score", 0, int)

func set_best_score(score: int):
    var current = get_best_score()
    if score > current:
        config.set_value("game", "best_score", score)
        save()

func get_games_played() -> int:
    return config.get_value("game", "games_played", 0, int)

func increment_games_played():
    config.set_value("game", "games_played", get_games_played() + 1)
    save()
```

**Verify:** Close/reopen game — best score preserved

---

#### Task 16: Balance pass

**Steps:**
1. Play through 10+ full runs (including multiple cycles)
2. Tune wheel costs (escalating curve)
3. Tune outcome weights per wheel (all sum to 100)
4. Tune outcome values (+/-/×// amounts)
5. Tune skill effect magnitudes
6. Tune skill base costs
7. Verify:
   - Can survive multiple cycles without skills (barely)
   - Skills make multi-cycle runs viable
   - Jackpot feels earned after several cycles
   - Shop timing feels right (every 5 spins)
   - Overall expected spins to jackpot
   - Risk/reward curve across cycles

**Deliverable:** Updated `wheel_config.gd` with tuned values, updated `skill_manager.gd` with tuned costs

---

#### Task 17: Polish & export

**Steps:**
1. **Polish:**
   - Coin counter animation (tween numbers)
   - Wheel tick sound during spin
   - Particle effects (gold on jackpot, green on positive, red on negative)
   - Wheel 10 dramatic visuals (screen shake, slow-mo)
2. **Mobile:**
   - All buttons ≥ 48×48px
   - Tap-to-spin on wheel area
   - Landscape orientation
3. **Export:**
   - Windows 64-bit
   - Linux
   - Android (min API 24)
4. **Final commit**

**Verify:** All export targets work, game is shippable

---

## Milestones

| Milestone | Tasks | Deliverable |
|-----------|-------|-------------|
| MVP | 1-6 | Playable: 10 wheels, coins, spin animation, loop 1-10, end on jackpot |
| Shop + Skills | 7-11 | Full skills system, shop every 5 spins |
| End Game | 12-13 | End screen (jackpot only), restart, complete main UI |
| Polish | 14-17 | Sounds, saves, balance, mobile, export |

---

## Design Decisions (Locked)

1. **Engine:** Godot 4.x (MIT, exports to PC + mobile)
2. **Runs:** Fresh start each time, no meta-progression
3. **Game loop:** Wheels 1→10→1→10... repeats indefinitely
4. **End condition:** Only when wheel 10 lands on jackpot (1%)
5. **Shop:** Every 5 spins total (spins 5, 10, 15, 20...) across all cycles
6. **Cost formula:** base × (2n - 1) per level
7. **Wheel 10:** 1% jackpot (game ends) / 99% loss (continue from wheel 1)
8. **Weight system:** Segments sum to 100
9. **Multiplier odds:** Increase with wheel number (0% early → high late → 1% jackpot)
10. **Wheel costs:** Escalating per wheel

## Open Questions

1. **Exact balances** — All weights, costs, values TBD for Task 16 balance pass
2. **Jackpot type** — ×10 coins or fixed prize? Current plan: ×10
3. **End screen rating thresholds** — TBD with balances
