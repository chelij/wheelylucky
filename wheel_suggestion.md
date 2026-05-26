# Wheel Balance Suggestion

Designed from scratch using the anchor rule: **W1 plus = +25, W2 cost = 25** (1 green hit on free wheel = 1 next-wheel spin).

## Design Principles

1. **Five greens + a couple losses funds one next-wheel spin.** If you land 5 green hits on any wheel, even with ~2 losses mixed in between, you can afford exactly 1 spin at the next wheel.
2. **Green > cost on every wheel.** Net per green hit is always positive and grows across tiers.
3. **Smooth cost curve.** Roughly ×1.4–1.6 per wheel. No cliffs (unlike wheel_balance.md's W7→W8 which jumps 7.8×).
4. **Multiplier pays from spin cost, not current coins.** A x9 hit on W2 (cost 25) gives +360 coins regardless of balance. This guarantees 1 next-wheel spin on every multiplier hit.
5. **Losses are proportional.** Loss ≈ 20–25% of net-per-green × 2 (need ~2 greens to offset 1 loss).
6. **Players spend more time at higher wheels.** EV per spin doesn't scale fast enough to outpace cost growth.

## Costs

| Wheel | Cost | Growth |
| --- | ---: | ---: |
| W1 | 0 | — |
| W2 | 25 | — |
| W3 | 40 | ×1.6 |
| W4 | 52 | ×1.3 |
| W5 | 72 | ×1.38 |
| W6 | 100 | ×1.39 |
| W7 | 140 | ×1.4 |
| W8 | 195 | ×1.39 |
| W9 | 260 | ×1.33 |

## Outcomes

Loss on every paid wheel: **-8**. Consistent and easy to reason about.

Multiplier values chosen so that **multiplier × cost ≥ next_wheel_cost** (guarantees at least 1 next-wheel spin per multiplier hit):

| Wheel | Spin Cost | Outcomes | Multiplier check |
| --- | ---: | --- | --- |
| W1 | 0 | `+25` x60, `0` x60 | — |
| W2 | 25 | `+73` x50, `-8` x30, `x9` x10, `0` x30 | 9×25=**225** ≥ 40 ✅ |
| W3 | 40 | `+95` x51, `-8` x35, `x8` x9, `0` x25 | 8×40=**320** ≥ 52 ✅ |
| W4 | 52 | `+120` x52, `-8` x40, `x7` x8, `0` x20 | 7×52=**364** ≥ 72 ✅ |
| W5 | 72 | `+150` x53, `-8` x45, `x7` x7, `0` x15 | 7×72=**504** ≥ 100 ✅ |
| W6 | 100 | `+200` x54, `-8` x50, `x6` x6, `0` x10 | 6×100=**600** ≥ 140 ✅ |
| W7 | 140 | `+260` x55, `-8` x50, `x5` x5, `0` x10 | 5×140=**700** ≥ 195 ✅ |
| W8 | 195 | `+340` x56, `-8` x55, `x5` x4, `0` x5 | 5×195=**975** ≥ 260 ✅ |
| W9 | 260 | `+450` x58, `-8` x55, `x4` x2, `0` x5 | 4×260=**1040** (final wheel) |

Note: multiplier values decrease (x9→x4) while costs increase, but the product always exceeds the next cost — so every multiplier hit guarantees progress.

## Derivation — Five Greens + Losses → Next Wheel

Each green value solved from: **5 × (g - cost) - 2×8 ≥ next_cost**

- W1→W2: free, +25 → 5 greens = **+125**, covers W2=25 easily
- W2→W3: g=73, net +48 → 5×(+48)=+240, -16 losses = **+224** ≥ 40 ✅
- W3→W4: g=95, net +55 → 5×(+55)=+275, -16 = **+259** ≥ 52 ✅
- W4→W5: g=120, net +68 → 5×(+68)=+340, -16 = **+324** ≥ 72 ✅
- W5→W6: g=150, net +78 → 5×(+78)=+390, -16 = **+374** ≥ 100 ✅
- W6→W7: g=200, net +100 → 5×(+100)=+500, -16 = **+484** ≥ 140 ✅
- W7→W8: g=260, net +120 → 5×(+120)=+600, -16 = **+584** ≥ 195 ✅
- W8→W9: g=340, net +145 → 5×(+145)=+725, -16 = **+709** ≥ 260 ✅

## EV Estimates (per spin, rough)

EV = (green_contribution - loss_contribution) / 120 - cost

| Wheel | Rough EV/spin | Spins to advance (cost/EV) |
| --- | ---: | ---: |
| W2 | +~8 | ~3-4 |
| W3 | +~10 | ~4-5 |
| W4 | +~11 | ~5-6 |
| W5 | +~12 | ~6-7 |
| W6 | +~13 | ~8-9 |
| W7 | +~14 | ~10-12 |
| W8 | +~16 | ~12-14 |
| W9 | +~18 | ~14-17 |

Players spend progressively more time at higher wheels, as desired. EV stays positive throughout so coins grow on average every spin.

## Green vs Cost — Always Positive

| Wheel | Green | Cost | Net/green | Multiplier hit = coins |
| --- | ---: | ---: | ---: | ---: |
| W2 | +73 | 25 | **+48** | +360 |
| W3 | +95 | 40 | **+55** | +320 |
| W4 | +120 | 52 | **+68** | +364 |
| W5 | +150 | 72 | **+78** | +504 |
| W6 | +200 | 100 | **+100** | +600 |
| W7 | +260 | 140 | **+120** | +700 |
| W8 | +340 | 195 | **+145** | +975 |
| W9 | +450 | 260 | **+190** | — |

Every green hit nets positive coins. Every multiplier hit funds multiple next-wheel spins.

## Loss Survivability

Need ~2 greens to offset 1 loss (net/green ÷ |loss| ≈ 6–8):

| Wheel | Greens to cover 1 loss | Greens to recover from 3 losses |
| --- | ---: | ---: |
| W2 | ~0.2 | 0.6 |
| W5 | ~0.1 | 0.3 |
| W9 | ~0.04 | 0.12 |

A single loss is easily absorbed — even 3 consecutive losses only costs what ~1 green hit would give you back. This means players can survive streaks of bad luck without being sent back to earlier wheels.

## W10 Design

Fix the duplicate red entries from wheel_balance.md:

| Wheel | Cost | Outcomes |
| --- | ---: | --- |
| W10 | 360 | `JACKPOT` x1, `-8` x20, `0` x99 |

Cost = 360 (continuing the ~×1.4 curve). One loss type + mostly safe slots. JACKPOT multiplies spin cost by 10 → +3600 coins on a 1/120 chance.

## Comparison with wheel_balance.md

| Aspect | wheel_balance.md | This suggestion |
| --- | --- | --- |
| W1 plus / W2 cost | +25 / 25 ✅ | +25 / 25 ✅ |
| Multiplier = next spin? | Yes (pays from cost) ✅ | Yes (pays from cost) ✅ |
| Cost curve smooth? | **No** — W7→W8 jumps 7.8× | **Yes** — ~1.4× throughout |
| Green > cost always? | **No** — mid-late rely on multiplier only | **Yes** — net positive every tier |
| Loss survivability? | **Low** — -5962 on W7 wipes 22% of green | **High** — -8 is tiny vs +450 |
| EV positive everywhere? | Yes (barely, multiplier-dependent) | **Yes** (strongly, green-driven) |
| Late wheels time curve? | Yes (extreme) | Yes (gradual increase) |
