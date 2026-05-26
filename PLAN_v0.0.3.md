# Wheely Lucky — v0.0.3 Plan

> **Target:** Fix logic bugs, clean up unused code, add elapsed time tracking, and prepare asset/sound polish pass.
> **Current implementation status:** v0.0.2 complete — core gameplay, shop, skills, and wheel balance are functional.

---

## Phase 1 — Bugs & Logic Fixes

### 1. Fortune's Favor — one-time per run

**Current:** `_apply_fortunes_favor_spin_push()` in `wheel.gd` runs every spin as long as the skill is owned. `fortune_used` flag exists in `game.gd` but is never checked.

**Fix:**
- `wheel.gd` `_apply_fortunes_favor_spin_push()`: check `Game.fortune_used` before pushing, set `Game.fortune_used = true` after pushing.

### 2. Second Wind — one-time per run

**Current:** `_finish_spin` in `game.gd` checks `"second_wind" in unique_skills` every time coins hit 0. `second_wind_used` flag exists but is never checked.

**Fix:**
- `game.gd` line 151: change condition to `"second_wind" in unique_skills and not second_wind_used`
- Set `second_wind_used = true` after triggering.

### 3. Floating Result Feedback — keep inline

**Current:** `main.gd` creates floating result labels inline. The old `result_popup.tscn` and `result_popup.gd` files have been removed.

**Fix:**
- Keep the inline floating label path because it is lighter and now matches the current scene tree.
- Format result deltas compactly for large rewards and show full values in tooltips where available.
- Do not reintroduce the removed result popup scene.

### 4. Auto-wheel-selection bug

**Current:** `game.gd` lines 175-179 auto-select the highest affordable wheel after **every** spin.

**Fix:**
- Only auto-select after:
  - Neutral (`OP_NONE` / `0` label, non-jackpot) or negative (`OP_SUBTRACT` / `OP_DIVIDE`) outcome
  - OR after spending coins in the shop
- Do **not** auto-advance on positive spins (`OP_ADD`, `OP_MULTIPLY`, `JACKPOT`).
- Implementation: pass outcome op_type into the auto-select check, skip if positive.
- Shop: after `buy_skill` deducts coins, trigger auto-select check.

---

## Phase 2 — Save Manager Cleanup

### Current State

`save_manager.gd` implements:
- `best_score` — persisted
- `games_played` — persisted

### Changes

- Keep best_score and games_played — these are sufficient.
- Remove any plan references to `total_spins` or `total_time_played` in save manager — not needed.
- No leaderboard functionality.

---

## Phase 3 — End Screen: Add Elapsed Time

### Current State

`end_screen.gd` shows: final coins, spins, cycles, skills, star rating.

### Add

- **Elapsed time** display (formatted as `MM:SS` or `HH:MM:SS`).
- Track start time in `game.gd` `reset_run()` — add `run_start_time: float = Time.get_ticks_msec()`.
- On game over, calculate elapsed and pass to end screen.
- Display on end screen alongside existing stats.

### Remove

- Remove `best_score` comparison from end screen (not needed per user feedback).

---

## Phase 4 — Asset Generation

All assets target a cohesive casino/cartoon mobile-friendly style at 1280×720 landscape.

### Priority 1 — Core UI (blocks playability/readability)

1. **Arrow selector buttons** — `assets/ui/prev-wheel.png`, `next-wheel.png`
   - Casino/gold-style left/right arrows
   - Normal/pressed/disabled states (or single art with code color modulation)
   - Replaces text `‹` / `›` in `wheel.gd`

2. **Shop card backgrounds** — `assets/ui/shop-card.png`
   - Themed card art replacing default `PanelContainer` style
   - Space for icon (top), name, cost, buy button
   - 9-slice stretchable

3. **Bought overlay art** — `assets/ui/bought-overlay.png`
   - Stamp/ribbon reading `BOUGHT`
   - Semi-transparent, doesn't obscure card content

### Priority 2 — Visual Polish

4. **Shop button art** — `assets/ui/shop-button.png`
   - Replace `button-plate.png` usage for shop
   - Clearly reads as tappable shop button
   - Consider bell/market icon integration

5. **Floating result feedback treatment**
   - Small burst/background behind result text
   - Positive (green glow), negative (red glow), neutral (gray) variants or single with color modulation

6. **Probability panel background** — `assets/ui/probability-panel.png`
   - Dedicated background instead of reusing `upgrades-panel.png`
   - Match casino theme

### Priority 3 — Nice to Have

7. **Upgrade/skill badge refresh** — `assets/ui/upgrade-badge.png`
   - Improve current badge for variable-length names
   - Consider icon + short text layout

8. **Coin count badge** — `assets/ui/coin-badge.png`
   - Current version works but may need wider variant for large numbers
   - Verify no clipping at high coin counts

9. **Wheel frame/pointer art** — `assets/wheel/wheel-frame.png`, `assets/wheel/pointer.png`
   - Optional overlay art for the code-drawn wheel
   - Gold rim, decorative pointer

---

## Phase 5 — Sound Pass

### Current State

All sounds are procedural sine tones via `SoundFactory.make_tone()`. `assets/sounds/` is empty.

### To Implement

| Sound | Current | Target |
|-------|---------|--------|
| Positive result | 880Hz tone | Distinct pleasant chime |
| Negative result | 220Hz tone | Descending thud |
| Multiplier | None | Distinct high-pitched ring |
| Jackpot | 1200Hz single tone | Multi-note fanfare |
| W10 loss | None | Descending tone sequence |
| Shop open | 660Hz tone | Bell/chime |
| Shop close | None | Soft click |
| Spin | 520Hz tone | Keep or replace with tick |

### Approach

- Generate with `SoundFactory` using layered tones, or
- Import short `.ogg` files into `assets/sounds/`
- Wire to existing `AudioStreamPlayer` nodes

---

## Phase 6 — Visual Effects

### To Implement

1. **Jackpot celebration** — particle burst, screen flash, or confetti on W10 win
2. **Stronger floating result feedback** — coin shower or number counter animation for big wins
3. **Wheel 10 tension** — screen shake, red vignette, or pulsing border on W10 spins

---

## Phase 7 — Balance Simulation

### To Do

1. **Simulate average run length** with current W9 farming + W10 attempts
   - Headless simulation: 1000+ runs, measure median/mean duration
   - Target: ~30 minute ceiling for "perfect run"

2. **Tune W9 if needed** — if W10 attempts are too rare or too frequent

3. **Decide: Lucky Charm jackpot growth on W10**
   - Current: Lucky Charm freely moves slots into JACKPOT on W10
   - Question: should jackpot slot growth be capped?

4. **Check W10 cost (1100)** — is it punishing enough without stalling?

5. **Risk Taker + W10 interaction** — should Risk Taker redistribute W10 neutral slots into jackpot/negative?

---

## File Reference

### Scripts

| File | Purpose | Status |
|------|---------|--------|
| `scripts/game.gd` | Core game state, spin logic | Fix bugs #1, #2, #4 |
| `scripts/main.gd` | UI glue, result display | Floating result feedback |
| `scripts/wheel.gd` | Wheel drawing, spin animation | Fix bug #1 |
| `scripts/wheel_config.gd` | Wheel data, outcome math | No changes |
| `scripts/skill_manager.gd` | Skill definitions | No changes |
| `scripts/shop.gd` | Shop UI, skill roll | Fix bug #4 (shop spend) |
| `scripts/save_manager.gd` | Save/load | Cleanup |
| `scripts/end_screen.gd` | Game over screen | Add elapsed time |
| `scripts/sound_factory.gd` | Procedural sound gen | Sound pass |

### Scenes

| Scene | Purpose | Status |
|-------|---------|--------|
| `scenes/main.tscn` | Main game | Asset swaps |
| `scenes/shop.tscn` | Shop overlay | Asset swaps |
| `scenes/end_screen.tscn` | Game over | Add time label |

### Assets — Existing

| Asset | Path | Status |
|-------|------|--------|
| Background | `assets/backgrounds/casino-stage.png` | OK |
| Pointer | `assets/pointer/pointer.png` | OK |
| Coin badge | `assets/ui/coin-badge.png` | OK (verify) |
| Button plate | `assets/ui/button-plate.png` | Replace (shop button) |
| Upgrades panel | `assets/ui/upgrades-panel.png` | OK |
| Upgrade badge | `assets/ui/upgrade-badge.png` | Refresh (P3) |
| Skill icons | `assets/ui/skill-icons.png` | OK |

### Assets — Empty Directories

| Directory | Purpose | Status |
|-----------|---------|--------|
| `assets/icons/` | App icons | Empty |
| `assets/sounds/` | Sound files | Empty (procedural for now) |
| `assets/wheel/` | Wheel art | Empty (code-drawn) |

---

## Execution Order

1. **Phase 1** — Bug fixes (code only, no assets needed)
2. **Phase 2** — Save manager cleanup
3. **Phase 3** — End screen elapsed time
4. **Phase 4** — Asset generation (can be done in parallel with 5-7)
5. **Phase 5** — Sound pass
6. **Phase 6** — Visual effects
7. **Phase 7** — Balance simulation (headless, data-driven)
