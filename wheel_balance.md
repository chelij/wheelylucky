# Wheel Balance Snapshot

Smoothed cost curve — replaced exponential cliffs (7.8× at W7→W8, 8.6× at W8→W9) with consistent ~3× growth throughout. All constraints preserved: green > cost on every wheel, multiplier guarantees 1 next-wheel spin, losses are survivable.

## Wheel Constants

- Total slots per wheel: `120`
- Slot degrees: `3.0`
- Outcome format: `[label, op_type, value, slots, color]`
- Multipliers pay from the spin cost, not from the current coin total.

## Costs

| Wheel | Cost | Growth |
| --- | ---: | ---: |
| W1 | 0 | — |
| W2 | 25 | ×inf |
| W3 | 75 | ×3.00 |
| W4 | 250 | ×3.33 |
| W5 | 800 | ×3.20 |
| W6 | 2,500 | ×3.12 |
| W7 | 7,500 | ×3.00 |
| W8 | 22,000 | ×2.93 |
| W9 | 65,000 | ×2.95 |
| W10 | 200,000 | ×3.08 |

## Outcomes

| Wheel | Spin Cost | Outcomes | Multiplier check |
| --- | ---: | --- | --- |
| W1 | 0 | `+25` x60, `0` x60 | — |
| W2 | 25 | `+91` x50, `-2` x30, `x3` x10, `0` x30 | 3×25=75 >= 75 |
| W3 | 75 | `+225` x51, `-5` x35, `x4` x9, `0` x25 | 4×75=300 >= 250 |
| W4 | 250 | `+668` x52, `-18` x40, `x4` x8, `0` x20 | 4×250=1,000 >= 800 |
| W5 | 800 | `+2,006` x53, `-60` x45, `x4` x7, `0` x15 | 4×800=3,200 >= 2,500 |
| W6 | 2,500 | `+6,019` x54, `-200` x50, `x3` x6, `0` x10 | 3×2,500=7,500 >= 7,500 |
| W7 | 7,500 | `+17,298` x55, `-638` x50, `x3` x5, `0` x10 | 3×7,500=22,500 >= 22,000 |
| W8 | 22,000 | `+49,016` x56, `-1,980` x55, `x3` x4, `0` x5 | 3×22,000=66,000 >= 65,000 |
| W9 | 65,000 | `+140,568` x58, `-6,175` x55, `x4` x2, `0` x5 | 4×65,000=260,000 >= 200,000 |
| W10 | 200,000 | `-100,000` x20, `JACKPOT` x1, `-100,000` x20, `0` x79 | 10×200,000=2,000,000 |

## Verification Notes

- Every wheel has exactly 120 slots.
- Green outcome always exceeds spin cost: net per green hit is always positive and grows across tiers (W2 +66 → W9 +75,568).
- Losses scale gradually (3%-8% of green net), never exceeding one green hit. No wipeout risk.
- Multiplier always pays from spin cost, guaranteeing at least 1 next-wheel spin on every multiplier hit.
- Five greens minus two losses funds at least one next-wheel spin on every tier.
- EV per spin stays positive throughout; ~4 spins to advance early wheels, ramping to ~45 at W9.

## Cost Curve Comparison (Old → New)

| Wheel | Old Cost | New Cost | Old Growth | New Growth |
| --- | ---: | ---: | ---: | ---: |
| W1 | 0 | 0 | — | — |
| W2 | 25 | 25 | — | — |
| W3 | 75 | 75 | ×3.0 | ×3.00 |
| W4 | 300 | 250 | ×4.0 | ×3.33 |
| W5 | 1,200 | 800 | ×4.0 | ×3.20 |
| W6 | 5,000 | 2,500 | ×4.2 | ×3.12 |
| W7 | 18,000 | 7,500 | ×3.6 | ×3.00 |
| W8 | 140,000 | 22,000 | ×7.8 | ×2.93 |
| W9 | 1,200,000 | 65,000 | ×8.6 | ×2.95 |
| W10 | 12,000,000 | 200,000 | ×10.0 | ×3.08 |

## EV Summary (per spin)

| Wheel | EV/Spin | Spins to Advance | Green Net | Loss (% of net) |
| --- | ---: | ---: | ---: | ---: |
| W2 | +19 | ~4 to W3 | +66 | -2 (3%) |
| W3 | +42 | ~6 to W4 | +150 | -5 (3%) |
| W4 | +100 | ~8 to W5 | +418 | -18 (4%) |
| W5 | +250 | ~10 to W6 | +1,206 | -60 (5%) |
| W6 | +500 | ~15 to W7 | +3,519 | -200 (6%) |
| W7 | +1,100 | ~20 to W8 | +9,798 | -638 (7%) |
| W8 | +2,167 | ~30 to W9 | +27,016 | -1,980 (7%) |
| W9 | +4,444 | ~45 to W10 | +75,568 | -6,175 (8%) |
