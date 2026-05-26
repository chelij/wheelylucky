# Wheely Lucky — v0.0.2 Plan

> **Target:** Slot-based wheel system, coin-gated progression, smooth pacing ramp, W9 farming into risky W10 attempts.
> **Current implementation status:** Updated to match current gameplay/balance as of latest pass.

---

## Current Gameplay Logic

### Core Rules

- Game has **10 wheels**: Wheel 1 through Wheel 10.
- **Wheel 1 acts as the bankruptcy shelter**.
  - There is no separate W0 scene/wheel.
  - Wheel 1 is always free.
- Player starts with **0 coins** on Wheel 1.
- Every spin deducts that wheel's spin cost immediately.
- Outcome is decided after the wheel stops, using the slot under the right-side pointer.
- Coins never go below 0.
- Wheel 10 jackpot ends the game.
- Wheel 10 non-jackpot result applies normally; after any non-jackpot W10 spin, selection returns to Wheel 1 and cycle count increases.

### Wheel Access / Progression

- Progression is **coin-gated only**.
- There is no permanent unlock/progression mechanism.
- A wheel is selectable if:
  - it is Wheel 1, or
  - the player currently has enough coins to pay for **one spin** on that wheel.
- Coins are only spent when spinning.
- Balance goal: smooth progression where expected green-spin requirement rises over the run:

```text
W1 → W2: 3 green net wins
W2 → W3: 3 green net wins
W3 → W4: 4 green net wins
W4 → W5: 5 green net wins
W5 → W6: 6 green net wins
W6 → W7: 7 green net wins
W7 → W8: 8 green net wins
W8 → W9: 9 green net wins
W9 → W10: 10 green net wins
```

### Shop

- After each completed spin, shop appearance is rolled randomly.
- Base shop chance starts at **10%**.
- Each spin where no shop appears adds another **+10%** chance.
- If the shop appears and the player spins without opening it, the shop disappears and the chance ramp resets.
- Market Bell increases both base chance and miss bonus by **+1% per level**.
- Each shop appearance offers **3 random skills**, or **4** with Golden Ticket.
- Upgradeable skill appearance is weighted toward lower-level skills using remaining-level weighting.
- Unique appearance chance starts at **50%**, then halves for each unique already owned.
- Collector increases the pre-decay unique chance by **+5% per level**.
- At most **one unique skill** can appear in a shop.
- Player can buy out all offered skills in a shop.
- Purchased cards remain visible and show `BOUGHT`.

---

## Slot System

- Each wheel has **120 fixed slots**.
- Each slot is **3°**.
- Outcome lookup uses the fixed slot list under the right-side pointer.
- Probability display shows slot counts like `35/120`.
- Wheel drawing renders slot wedges without yellow segment border lines.
- Labels are drawn once per contiguous outcome block for readability.

### Outcome Format

```gdscript
[label, op_type, value, slots, color]
```

Indices:

```gdscript
IDX_LABEL = 0
IDX_OP = 1
IDX_VALUE = 2
IDX_SLOTS = 3
IDX_COLOR = 4
```

---

## Current Wheel Balance

| Wheel | Cost | Gain | Multiplier | Neutral | Loss | Jackpot | Total |
|-------|------|------|------------|---------|------|---------|-------|
| 1 | 0 | 60 slots `+9` | — | 60 slots `0` | — | — | 120 |
| 2 | 25 | 50 slots `+42` | 10 slots `x3` | 30 slots `0` | 30 slots `-5` | — | 120 |
| 3 | 50 | 51 slots `+75` | 9 slots `x4` | 25 slots `0` | 35 slots `-10` | — | 120 |
| 4 | 100 | 52 slots `+135` | 8 slots `x5` | 20 slots `0` | 40 slots `-18` | — | 120 |
| 5 | 175 | 53 slots `+221` | 7 slots `x6` | 15 slots `0` | 45 slots `-28` | — | 120 |
| 6 | 275 | 54 slots `+333` | 6 slots `x7` | 10 slots `0` | 50 slots `-40` | — | 120 |
| 7 | 400 | 55 slots `+472` | 5 slots `x8` | 10 slots `0` | 50 slots `-58` | — | 120 |
| 8 | 575 | 56 slots `+664` | 4 slots `x9` | 5 slots `0` | 55 slots `-80` | — | 120 |
| 9 | 800 | 58 slots `+910` | 2 slots `x10` | 5 slots `0` | 55 slots `-110` | — | 120 |
| 10 | 1100 | — | — | 109 slots `0` | 10 slots `-30` | 1 slot `JACKPOT` | 120 |

Notes:

- Green gain values include the cost already paid. Net green gain is `gain - cost`.
- The green values are tuned so the listed number of net green wins reaches the next wheel's cost.
- W10 is intentionally prohibitive; players are expected to farm W9 bankroll before taking W10 attempts.
- W10 jackpot is **1 slot out of 120** by default.
- W10 neutral is still costly in practice because the spin cost has already been paid.

---

## Multiplier Behavior

- Multipliers no longer multiply current coin balance.
- Multipliers pay based on the wheel cost:

```text
multiplier payout = current wheel cost × multiplier value
```

- Since spin cost is paid before outcome resolution, net multiplier profit is roughly:

```text
cost × (multiplier - 1)
```

- Current multiplier ramp:

```text
W2 x3, 10 slots
W3 x4, 9 slots
W4 x5, 8 slots
W5 x6, 7 slots
W6 x7, 6 slots
W7 x8, 5 slots
W8 x9, 4 slots
W9 x10, 2 slots
```

---

## Skills — Current Behavior

### Lucky Charm

- Max level: 10.
- Each level moves **1 slot** from neutral/negative outcomes to positive outcomes.
- Positive outcomes include:
  - `OP_ADD`
  - `OP_MULTIPLY`
  - `JACKPOT`
- Sources are neutral/loss outcomes.
- The source chosen is currently the largest available neutral/negative slot group.
- This skill was **not multiplied by 10** during the skill effect buff pass.

### Upgradeable Skills

- Lucky Charm: **+1 good slot per level**.
- Quick Spin: spin duration scales by **0.75^level**.
- Discount Card: **-0.1% spin cost per level**.
- Coin Magnet: **+10% add value per level**.
- Sharp Mind: **+25% multiplier payout per level**.
- Free Gift: neutral/red outcomes refund **1% spin cost per level**.
- Shop Savvy: shop prices are **1% cheaper per level**.
- Market Bell: shop chance and miss bonus are **+1% per level**.
- Collector: uniques are **+5% more likely** to appear per level before owned-unique decay.

Normal skill cost:

```text
5 × next_level
```

### Unique Skills

- Double Down: doubles positive and negative coin modifiers, and doubles non-W10 spin costs.
- Risk Taker: removes non-jackpot `0` outcomes and redistributes neutral slots across remaining outcomes.
- Fortune's Favor: if a spin would stop on red, pushes the wheel 2 slots farther before resolving.
- Banker: earns **10% interest** after each spin.
- Second Wind: if a spin brings coins to 0, refunds **90% of spin cost**.
- Randomizer: randomizes outcome positions without changing slot counts/odds.
- Momentum: green streaks add good slots, red resets the streak, capped at 10.
- Golden Ticket: shops offer **1 extra skill**.
- Double Spin: pointer spins opposite the wheel during spins.

Unique skill cost:

```text
500 × nth_unique_purchased_this_run
```

---

## Implemented v0.0.2 Tasks

### Done

- `scripts/wheel_config.gd`
  - Uses 120-slot outcome definitions.
  - Current smooth pacing balance implemented.
  - W10 set to 1 jackpot slot, 10 negative slots, 109 neutral slots.
  - Multipliers use cost-based payout.

- `scripts/wheel.gd`
  - Draws fixed slot wedges.
  - Reads outcome by pointer slot.
  - Removed yellow separator/border lines from wheel segments.
  - Draws labels per contiguous outcome block.

- `scripts/main.gd`
  - Probability chart displays current slot counts.

- `scripts/game.gd`
  - Wheel access is coin-gated only.
  - Tracks last spin cost for multiplier payout, Free Gift, and Second Wind.
  - Rolls shop appearance with increasing missed-shop chance.
  - Tracks Momentum stacks.
  - Wheel 10 jackpot detection uses `JACKPOT` label.

- `scripts/shop.gd` / `scenes/shop.tscn`
  - Shop offers 3 centered skills, or 4 with Golden Ticket.
  - Skill cards show name, description, and buy button.
  - Bought cards stay visible and show `BOUGHT`.
  - Shop can be bought out.
  - Unique appearance rules and Collector modifier implemented.

- `scripts/skill_manager.gd`
  - Skill descriptions updated to current values.

### Verified

- Project starts headless with:

```bash
godot --headless --path . --quit
```

---

## Remaining Balance Follow-up

1. Simulate/measure average run length with current W9 farming + W10 attempts.
2. Tune W9 if W10 attempts are too rare or too frequent.
3. Decide whether Lucky Charm should affect W10 jackpot freely or be capped for jackpot slots.
4. Check whether W10 cost `1100` is punishing enough without making runs feel stalled.
5. Check if current fastest lucky win can land near the desired ~30 minute ceiling.

---

## Future UI / UX / Asset Polish

> Next pass should be done with screenshot/vision feedback. Current UI is functional but visually rough.

### Target Layout

- Landscape-only layout (`1280×720` reference).
- Wheel centered horizontally.
- Probability panel on the left.
- Upgrades/owned skills panel on the right.
- Coin count below the wheel with a dedicated coin badge/background.
- Cost above the wheel.
- Wheel selection via left/right arrow buttons beside the wheel.
- No top bar / no top wheel selector.

### Known UI Issues To Fix

- Overall game visual style looks inconsistent/rough. First screenshot pass added darker panel backdrops and tighter layout, but final art replacement is still open.
- Probability panel header/row alignment had a first screenshot tuning pass; verify again after the next rendered screenshot.
- Probability row label and slot count spacing has been tightened; verify on phone landscape after another screenshot.
- Upgrades panel text now has a larger/right-side framed area and smaller badge width, but long names still need screenshot verification after several purchases.
- Upgrade badges/background have a first fit pass; final badge art can still improve hierarchy.
- Coin badge, shop button, and wheel bottom area had spacing adjusted; verify after shop button appears.
- Shop cards now use shorter card layout with descriptions moved to hover tooltip to reduce overflow.
- Bought shop overlay exists but needs visual styling polish.
- Arrow buttons are code-styled placeholders; need final art/buttons.
- Wheel section labels are removed for readability; confirm this is visually acceptable.
- Floating result feedback now animates near coin count; needs visual polish and positioning check.
- Touch/click targets should remain large enough for mobile landscape.

### Missing / Needed Assets

Generate or replace with cohesive casino/cartoon mobile-friendly art:

1. **Wheel arrow selector buttons**
   - Left/right arrow buttons matching the casino/gold style.
   - Need normal/pressed/disabled readability.

2. **Shop button art**
   - Current button plate exists but needs better final art.
   - Should clearly read as a tappable shop button.

3. **Coin count badge/background**
   - Needs a landscape-friendly coin counter plate under the wheel.
   - Should fit large coin numbers without clipping.

4. **Panel backgrounds**
   - Probability panel background.
   - Upgrades panel background.
   - Current reused panel art does not fit all text well.

5. **Upgrade/skill badge backgrounds**
   - Needed for owned skills/uniques list.
   - Should support variable-length names or have icon+short text layout.

6. **Shop card backgrounds**
   - Current cards are default `PanelContainer` style.
   - Need themed card art with space for icon, name, desc, cost, bought overlay.

7. **Skill icon atlas refresh**
   - Refreshed to a 6×3 atlas at `assets/ui/skill-icons.png` covering all current 9 upgradeable skills and 9 unique skills:
     - Lucky Charm
     - Quick Spin
     - Discount Card
     - Coin Magnet
     - Sharp Mind
     - Free Gift
     - Shop Savvy
     - Market Bell
     - Collector
     - Double Down
     - Risk Taker
     - Fortune's Favor
     - Banker
     - Second Wind
     - Randomizer
     - Momentum
     - Golden Ticket
     - Double Spin

8. **Bought overlay art**
   - Stamp/ribbon overlay reading `BOUGHT`.
   - Should not obscure the card too badly.

9. **Floating result feedback treatment**
   - Positive/negative/neutral result text style or small burst background.

10. **Wheel frame/pointer polish**
   - Existing wheel is code-drawn and functional.
   - Pointer/frame could use cohesive final art if desired.

### Suggested Codex/Vision Task

Use a screenshot of the current game and ask Codex/vision to:

1. Identify overlap/clipping issues.
2. Tune exact node offsets/sizes in `scenes/main.tscn` and `scenes/shop.tscn`.
3. Keep landscape-only constraints.
4. Preserve gameplay scripts unless layout code needs minimal changes.
5. Prioritize readability at phone landscape size.

---

## Future End Screen / Save / Polish

- Expand end screen stats:
  - coins won
  - total spins
  - cycles completed
  - elapsed time
  - best score comparison
- Expand save manager:
  - best score
  - total games played
  - total spins across all games
  - total time played
- Sound pass:
  - distinct positive/negative/multiplier tones
  - jackpot fanfare
  - W10 loss descending tone
  - shop open/close
- Visual effects:
  - jackpot celebration
  - stronger floating result feedback
  - wheel 10 tension effects

---

## Open Balance Questions

1. Is W9 farming too punishing because neutral/loss still burn the `800` spin cost?
2. Should Lucky Charm jackpot growth be capped on W10?
3. Should Risk Taker be allowed to redistribute neutral W10 slots into jackpot/negative outcomes?
4. Should W10 remain pure jackpot/neutral/loss, or eventually gain special consolation outcomes?
