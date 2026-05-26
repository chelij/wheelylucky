# Wheel Balance Snapshot

This is the restored large-number wheel balance recovered from local unreachable Git blob:

`92c0b5c8f72af71efa018a5d8864c0612ed98241`

Use this file as the source reference if the balance is accidentally overwritten.

## Wheel Constants

- Total slots per wheel: `120`
- Slot degrees: `3.0`
- Outcome format: `[label, op_type, value, slots, color]`
- Multipliers pay from the spin cost, not from the current coin total.

## Costs

| Wheel | Cost |
| --- | ---: |
| W1 | 0 |
| W2 | 25 |
| W3 | 75 |
| W4 | 300 |
| W5 | 1200 |
| W6 | 5000 |
| W7 | 18000 |
| W8 | 140000 |
| W9 | 1200000 |
| W10 | 12000000 |

## Outcomes

| Wheel | Spin Cost | Outcomes |
| --- | ---: | --- |
| W1 | 0 | `+25` x60, `0` x60 |
| W2 | 25 | `+60` x50, `-1` x30, `x9` x10, `0` x30 |
| W3 | 75 | `+160` x51, `-8` x35, `x12` x9, `0` x25 |
| W4 | 300 | `+450` x52, `-49` x40, `x12` x8, `0` x20 |
| W5 | 1200 | `+1800` x53, `-262` x45, `x14` x7, `0` x15 |
| W6 | 5000 | `+7500` x54, `-1375` x50, `x16` x6, `0` x10 |
| W7 | 18000 | `+27000` x55, `-5962` x50, `x18` x5, `0` x10 |
| W8 | 140000 | `+190000` x56, `-54250` x55, `x18` x4, `0` x5 |
| W9 | 1200000 | `+1700000` x58, `-532500` x55, `x20` x2, `0` x5 |
| W10 | 12000000 | `-6000000` x20, `JACKPOT` x1, `-6000000` x20, `0` x79 |

## Verification Notes

- `scripts/verify_polish.gd` should check that each paid wheel has at least one positive outcome path that can cover the spin cost.
- Do not require every flat Plus outcome to exceed the spin cost; W5, W6, W7, W8, and W9 intentionally rely on multiplier outcomes for cost-covering wins.
- `python3 scripts/sim_playtime.py 1 --gd-only` should parse the same values from `scripts/wheel_config.gd`.
