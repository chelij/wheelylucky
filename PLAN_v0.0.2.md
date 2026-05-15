# Wheely Lucky — v0.0.2 Plan

> **Target:** Slot-based wheel system, generous number growth, mobile-first layout.
> **15-min best case:** Pure luck scenario, average runs can be much longer.

---

## Core Mechanic Changes (v0.0.1 → v0.0.2)

| v0.0.1 | v0.0.2 |
|--------|--------|
| Weighted segments (float weights summing to 100) | **120 fixed slots × 3° each** |
| Lucky Charm: +0.2 weight shift per level | **+1 slot to positive outcomes per level** |
| Pointer angle math for outcome read | **Slot index lookup: `floor(angle / 3°)`** |
| Probability chart: percentages | **Slot counts (X/120)** |
| Wheel 10: 1%/99% float weights | **2 slots JACKPOT / 118 slots LOSS** |

---

## Wheel 10 — Pure Luck

- **JACKPOT:** 2 slots (1.67%) → **GAME ENDS** — final score = current coins (no multiplier)
- **LOSS:** 118 slots (98.33%) → loss amount TBD → return to wheel 1
- With maxed Lucky Charm (Lv.10): +10 slots to JACKPOT = 12 slots (10%), 108 loss
- No scaling — same odds every cycle

## Balance (TBD — will tune after slot system works)

- Wheel 10 loss amount: TBD
- Multiplier values per wheel: TBD (x2/x3/x4 for now)
- Wheel costs: TBD — costs should increase meaningfully for sense of progression
- Neutral spins cost 0 — to compensate, negative spin effects are reduced
- Goal: numbers get BIG, costs grow slower than coin accumulation

## Slot Distribution (Draft — will tune)

| Wheel | Gain (+N) | Multiplier | Neutral (0) | Loss (-N) | Jackpot | Total |
|-------|-----------|------------|-------------|-----------|---------|-------|
| 1 | 80 slots (+3) | 0 | 40 (0) | 0 | — | 120 |
| 2 | 50 (+8) | 5 (x2) | 35 (0) | 30 (-3) | — | 120 |
| 3 | 40 (+12) | 15 (x2) | 30 (0) | 35 (-5) | — | 120 |
| 4 | 35 (+15) | 20 (x2) | 20 (0) | 45 (-8) | — | 120 |
| 5 | 30 (+20) | 25 (x2) | 15 (0) | 50 (-10) | — | 120 |
| 6 | 25 (+25) | 30 (x2-3) | 10 (0) | 55 (-12) | — | 120 |
| 7 | 20 (+30) | 35 (x3) | 10 (0) | 55 (-15) | — | 120 |
| 8 | 15 (+35) | 40 (x3) | 5 (0) | 60 (-20) | — | 120 |
| 9 | 10 (+40) | 50 (x3-4) | 5 (0) | 55 (-25) | — | 120 |
| 10 | 0 | 0 | 0 | 118 (TBD) | 2 | 120 |

> Lucky Charm modifies these: each level moves 1 slot from neutral/loss to gain. Max Lv.10 = +10 gain slots.

---

## Implementation Tasks

### Phase 1: Slot System Foundation (AI-heavy)

#### Task 1: Rewrite wheel config to slot-based
**Files:** `scripts/wheel_config.gd`
- Replace weighted arrays with slot-count arrays: `[label, op, value, slots, color]`
- Total slots must equal 120 per wheel
- `get_slots(wheel_num)` returns flat array of 120 individual slot entries
- `apply_skill_modifiers()` manipulates slot counts directly

#### Task 2: Rewrite wheel drawing for 3° segments
**Files:** `scripts/wheel.gd`
- `_draw()`: each slot = 3° wedge, draw as triangle from center
- 120 segments × 64-point arcs = smooth but consistent
- Labels: combine adjacent slots of same outcome for readability
- Gold separators at slot boundaries (every 3°)

#### Task 3: Simplified pointer read
**Files:** `scripts/wheel.gd`
- `get_pointer_outcome()`: `slot_index = floor(pointer_angle / 3.0) % 120`
- Look up outcome from slot array — no cumulative weight math
- Much faster, no floating point drift

#### Task 4: Rewrite Lucky Charm skill
**Files:** `scripts/wheel_config.gd`, `scripts/skill_manager.gd`
- Per level: +1 slot to positive outcomes, -1 from neutral/negative
- Visual: player sees green slots grow on the wheel
- Display modifier update: slot counts change in probability chart

#### Task 4b: Meaningful wheel unlock visuals
**Files:** `scripts/main.gd`, `scenes/main.tscn`
- Unlocked wheels: bright, clickable, shows wheel number
- Locked wheels: greyed out with "?" icon, visually distinct
- Just-unlocked wheel: brief glow/pulse animation to draw attention
- Wheel selector buttons: distinct states (locked / unlocked-not-selected / selected / can't-afford)

### Phase 2: UI Polish (AI-heavy)

#### Task 5: Mobile-first layout
**Files:** `scenes/main.tscn`, `scripts/main.gd`
- Wheel takes 60% of viewport height
- Wheel selector: horizontal scroll or compact 2-row grid
- Probability chart: collapsible toggle, slot-based display
- Upgrades panel: swipeable or condensed
- Touch targets: min 48×48dp for all buttons
- Test at 360×640 portrait orientation

#### Task 6: End screen
**Files:** `scenes/end_screen.tscn`, `scripts/end_screen.gd`
- Final stats: coins won, total spins, cycles completed, time elapsed
- Best score comparison
- Replay button
- Clean, celebratory design

#### Task 7: Save manager
**Files:** `scripts/save_manager.gd`
- Persist to `user://save.cfg`:
  - Best score
  - Total games played
  - Total spins across all games
  - Time played

### Phase 3: Polish (Joint)

#### Task 8: Sound pass
**AI:** Enhance `scripts/sound_factory.gd`
- Result sounds: distinct tones per outcome type
- Jackpot: fanfare chord sequence
- Wheel 10 loss: descending tone
- Shop open/close
- Spin tick during rotation (optional)

#### Task 9: Visual effects
**AI generate, you approve:**
- Jackpot celebration: particle burst or screen flash
- Result popup: bigger text, glow effect on multipliers
- Wheel 10 approach: subtle screen pulse or color shift

#### Task 10: Export presets
**AI:** `export_presets.cfg`
- Web (HTML5) — primary for mobile play
- Windows/Linux desktop — optional

### Phase 4: Balance (You-driven)

#### Task 11: Playtest & tune
**You:** Play the game, report what feels off
**AI:** Adjust slot counts, costs, values based on feedback
**Repeat:** Until "this feels right"

---

## Questions for You

1. **Jackpot multiplier** — x5 on current coins, or something else?
2. **Wheel 10 loss amount** — flat 30 coins for now, or should I leave it as TBD?
3. **Number of multipliers per wheel** — current draft has only x2/x3/x4. Want x5/x10 rare outcomes?
4. **Neutral slots (0)** — keep them or remove entirely? They act as "safe" outcomes but slow number growth.
5. **Shop frequency** — still every 5 spins, or adjust for slot system?

---

## File Changes Summary

| File | Change |
|------|--------|
| `scripts/wheel_config.gd` | Complete rewrite: slots instead of weights |
| `scripts/wheel.gd` | Redraw for 3° segments, simplified pointer read |
| `scripts/skill_manager.gd` | Lucky Charm: slot-based, update skill descriptions |
| `scripts/game.gd` | Minor: skill signals, shop logic |
| `scripts/main.gd` | Mobile layout, probability chart update |
| `scenes/main.tscn` | Mobile-first layout |
| `scenes/end_screen.tscn` | New: stats + replay |
| `scripts/end_screen.gd` | New |
| `scripts/save_manager.gd` | Persistent save to disk |
| `scripts/sound_factory.gd` | Enhanced sound effects |
| `export_presets.cfg` | Web + desktop exports |
| `PLAN.md` | Updated with slot system |

---

## Timeline Estimate

- **Phase 1 (slot system):** 1 session
- **Phase 2 (UI polish):** 1 session
- **Phase 3 (polish):** 1 session
- **Phase 4 (balance):** 1-2 sessions of playtest feedback
- **Total:** ~3-4 sessions to v0.0.2 complete
