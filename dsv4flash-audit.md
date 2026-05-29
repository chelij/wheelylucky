# Wheely Lucky — Code Audit & Fixes

Audit date: 2026-05-29
Files examined: all 14 GDScript files (~4667 lines total)

Legend:
- 🔴 **Critical** — bug, crash, or major architectural concern
- 🟡 **Important** — correctness risk, performance impact, or DRY violation
- 🟢 **Minor** — readability, consistency, or best-practice suggestion

---

## 🔴 Performance Bottlenecks

### P1. `wheel.gd` — Jackpot proximity scan every `_process` frame

**Lines:** `wheel.gd:203-208` (`_process` → `is_pointer_near_jackpot(8)`)

`_process()` calls `get_pointer_outcome()` (O(1)) then `is_pointer_near_jackpot(8)`. The latter **re-scans the entire `cached_slots` array** looking for the JACKPOT index every frame. Since the jackpot slot doesn't move during a single spin, the jackpot index should be cached when `_refresh_outcomes()` runs instead of O(n) iteration every ~16ms.

**✅ Fix applied:** Added `cached_jackpot_index` variable, set during `_refresh_outcomes()`, used by `is_pointer_near_jackpot()` for O(1) lookup.

---

### P2. `main.gd` — `_get_all_buttons` recursive tree walk on every background click

**Lines:** `main.gd:992-998`

`_is_mouse_over_enabled_button` calls `_get_all_buttons(self)` which does a full recursive `get_children()` traversal of `main` and every descendant. This runs on **every background click** to spin the wheel. With dynamic UI (shop, end screen, upgrades grid, particles), the tree can be large.

**Fix:** Use a Button group (`add_to_group("click_buttons")`) and retrieve via `get_tree().get_nodes_in_group("click_buttons")`. Or cache the button list and rebuild only on scene changes. *(Not applied — moderate effort, medium impact.)*

---

### P3. `main.gd` — `_on_node_added` type-checks every node in the scene tree

**Lines:** `main.gd:159-162`

```gdscript
get_tree().node_added.connect(_on_node_added)
func _on_node_added(node: Node) -> void:
    if node is Button:
        call_deferred("_wire_button_sounds", node)
```

The `node_added` signal fires for **every single node** entering the tree (particles, labels, containers, etc.), causing thousands of `is Button` type-checks. Same pattern for `_apply_large_ui_text_to_control_deferred` below.

**Fix:** Instead of a global signal, wire button sounds at creation sites (shop card creation, menu button creation, etc.) or use a `Button`-specific group with `tree_entered` on the button itself. *(Not applied — architectural refactor.)*

---

### P4. `wheel.gd` — Heavy `queue_redraw()` every frame during spin

**Lines:** `wheel.gd:227-228` (in `_process`), `wheel.gd:550-610` (`_draw()`)

`_draw()` iterates `cached_section_tris` (up to ~1920 triangles for 120 slots × 8 quads × 2 tris) every frame. Also draws separator lines, labels with font rendering, and progress arc. This is called ~150 times over a 2.5s spin.

**Fix:** Consider using `draw_multimesh` for the section tris, reduce label font rendering overhead by caching font glyphs, or lower draw frequency for far-from-pointer sections. *(Not applied — moderate refactor.)*

---

### P5. `game.gd` — Dictionary allocations per spin in `_build_ordered_skill_coin_events`

**Lines:** `game.gd:271-300`

Creates `pending_by_id` dict with `duplicate(true)` on each base event, then iterates `bought_skill_order` allocating 2–8 small Dictionaries per spin. Short-lived but spiky GC pressure.

**Fix:** Pre-allocate or reuse a prototype Dictionary. Not critical unless profiling shows GC spikes. *(Not applied — low priority.)*

---

## 🔴 Code Architecture / DRY Violations

### A1. `_format_elapsed` duplicated in 2 files

**Files:** `main.gd:327-333`, `end_screen.gd:116-121`

Identical function (hours/minutes/seconds formatting). Belongs in `ui_format.gd`.

**✅ Fix applied:** Moved to `ui_format.gd` as `static func format_elapsed()`, both callers now delegate to it.

---

### A2. Skill-summary logic duplicated between `game.gd` and `end_screen.gd`

**Files:** `game.gd:411-420` (`_get_owned_skill_summaries`), `game.gd:422-427` (`_get_skill_purchase_count`), `end_screen.gd:95-108` (`_get_bought_skills`), `end_screen.gd:111-117` (`_get_skill_purchase_count`)

Same iteration over `bought_skill_order` with the same branching on `skill_id in unique_skills`.

**✅ Fix applied:** Removed `_get_bought_skills` from `end_screen.gd`, uses `Game._get_owned_skill_summaries()` and `Game._get_skill_purchase_count()` instead.

---

### A3. `_get_discounted_cost` duplicated

**Files:** `game.gd:302-304`, `shop.gd:138-141`

Identical function computing Shop Savvy discount.

**✅ Fix applied:** `shop.gd` now delegates to `Game._get_discounted_shop_cost()`.

---

### A4. `IDX_LABEL` / `IDX_OP` etc. redefined in 3 files

**Files:** `wheel_config.gd:71-75`, `game.gd:16-20`, `wheel.gd:46-50`

All three compile to the same const values, but it's a maintenance hazard if the index scheme ever changes.

**✅ Fix applied:** Removed duplicate const blocks from `game.gd` and `wheel.gd`, all references now use `WheelConfig.IDX_*`.

---

### A5. 4 classes `extends RefCounted` but used as pure static modules

**Files:** `wheel_config.gd`, `skill_effects.gd`, `skill_manager.gd`, `ui_format.gd`, `ui_sprites.gd`

All methods are `static func`, never instantiated. `extends RefCounted` implies they can be constructed.

**✅ Fix applied:** Added `## Static utility — do not instantiate.` doc comment to each file.

---

## 🟡 Important: Memory / Node Management

### M1. `main.gd` — `_spawn_particle_burst` creates orphan-friendly ColorRects

**Lines:** `main.gd:1073-1093`

Each particle (`ColorRect`) is parented to `main`. Tweens use `queue_free` via `tween_callback`. If the tween chain is **killed** mid-flight (scene transition, game-over, shop open during animation), particles survive as orphans. Jackpot bursts spawn 88 particles at once.

**Fix:** Parent particles to a dedicated `Node` that gets freed on scene transitions, or use `GPUParticles2D` / `CPUParticles2D` which self-terminate. *(Not applied — requires particle system migration.)*

---

### M2. `main.gd` — `_play_w10_loss_focus` mutates `canvas_transform` without restore guarantee

**Lines:** `main.gd:1111-1117`

If the scene is exited or a modal opens during the shake animation, `canvas_transform` stays zoomed/shifted.

**✅ Fix applied:** Added `_exit_tree()` override that resets `get_viewport().canvas_transform = Transform2D()`.

---

### M3. `main.gd` — `_skill_info_popup` overlay can leak

**Lines:** `main.gd:1330-1390`+

The overlay (`SkillPopupOverlay`) is created with `set_anchors_preset(Control.PRESET_FULL_RECT)` and `MOUSE_FILTER_STOP`. If a modal or end-screen opens while it's active, the overlay blocks input.

**Fix:** Connect `tree_exiting` on the overlay to auto-remove, or add overlay to a group and clean up in `_exit_tree()`. *(Not applied — low frequency, manual workaround exists via clicking the overlay to dismiss.)*

---

### M4. `save_manager.gd` — Synchronous disk writes on every game action

**Lines:** `save_manager.gd:78-82` (`add_spin`), `save_manager.gd:86-89` (`add_skill_level`)

Every spin calls `add_spin()` which calls `_save()` → `config.save(SAVE_PATH)` → synchronous file I/O. On 120-slot wheels, that's 120 disk writes per spin cycle.

**Fix:** Add a "dirty" flag and throttle writes (e.g., every 500ms or on `tree_exiting`). *(Not applied — moderate refactor.)*

---

## 🟡 Important: Numeric Precision

### N1. `wheel_config.gd` — Float conversion of large coin values

**Lines:** `wheel_config.gd:254-260`

Coins are `int`. Casting to `float` and back is safe up to ~9 quadrillion (2^53). Past that, float precision loses integer accuracy. Unlikely to be hit in normal play.

**Fix:** (Low priority) Use `int` arithmetic throughout or add a comment documenting the limit. *(Not applied.)*

---

### N2. `wheel_config.gd` — Risk Taker slot redistribution may be uneven

**Lines:** `wheel_config.gd:215-225`

After removing zero-outcomes, remaining slots are distributed one-by-one using modulo arithmetic, which favors early entries.

**Fix:** Redistribute proportionally to remaining slot ratios instead of round-robin modulo. *(Not applied — niche edge case with Risk Taker.)*

---

## 🔴 Potential Bugs

### B1. `wheel_config.gd` — `weighted_random` crashes on empty outcomes

**Line:** `wheel_config.gd:244-249`

If `apply_skill_modifiers` ever zeros out all slot counts, `outcomes[0]` on an empty array raises index-out-of-bounds.

**✅ Fix applied:** Added `if outcomes.is_empty(): return null` at the top of the function.

---

### B2. `game.gd` — `_finish_spin` accesses `outcome[IDX_LABEL]` without null check

**Line:** `game.gd:232`

If outcome is null (edge case from `spin_wheel`), indexed access crashes.

**✅ Fix applied:** Added `if outcome == null: return {"success": false, "reason": "null_outcome"}` guard at the top of `_finish_spin`.

---

### B3. `game.gd` — Race between `begin_spin` and `_finish_spin` on `selected_wheel`

**Lines:** `game.gd:139-158`, `game.gd:225-226`

`begin_spin()` deducts cost for `selected_wheel`. If a signal handler calls `select_wheel()` between `begin_spin()` and `_finish_spin()`, the outcome is processed for the wrong wheel.

**✅ Fix applied:** Added `_current_spin_wheel` member, set in `begin_spin()`, used in `_finish_spin()` and `spin_wheel()` instead of re-reading `selected_wheel`.

---

### B4. `save_manager.gd` — `increment_games_won` corrupts `games_played`

**Lines:** `save_manager.gd:67-68`

```gdscript
config.set_value("game", "games_played", get_games_won())  # reads old value!
```

**✅ Fix applied:** Stored `new_won = get_games_won() + 1` in a local and used it for both writes.

---

### B5. `wheel.gd` — `_get_pointer_slot_index()` uses stale base angle after resize

**Lines:** `wheel.gd:53-57` (`_ready`), `wheel.gd:389-395` (`_get_pointer_slot_index`)

`pointer_base_angle_degrees` computed once in `_ready()`. After viewport resize, the angle is wrong.

**✅ Fix applied:** Added `NOTIFICATION_RESIZED` handler that calls `_recompute_pointer_base_angle()`.

---

### B6. `wheel.gd` — `get_pointer_outcome()` calls `_refresh_outcomes()` with mutation side effects

**Lines:** `wheel.gd:479-482`

`_refresh_outcomes()` calls `WheelConfig.apply_skill_modifiers()` which mutates outcome arrays in-place. If called at an unexpected time, it invalidates caches mid-draw.

**✅ Fix applied:** Removed lazy `_refresh_outcomes()` call from `get_pointer_outcome()` and `is_pointer_near_jackpot()`. Cache must be populated at controlled entry points only.

---

### B7. `main.gd` — `await` in resolution events can resume after node death

**Lines:** `main.gd:1120-1135`, `main.gd:1315-1390`

`_play_resolution_events` uses `await get_tree().create_timer(n).timeout` between events. If the scene transitions during this coroutine, execution resumes in a stale context.

**✅ Fix applied:** Added `if not is_instance_valid(self): return` guards after every `await` in `_on_spin_finished`, `_play_resolution_events`, and `_show_skill_coin_delta`.

---

### B8. `wheel.gd` — `instant_spin()` doesn't play the spin sound

`instant_spin()` is a dev-tools-only path. The lack of sound is acceptable.

*(Not applied — intentional for dev tool.)*

---

## 🟢 Readability & Best-Practice Wins

### R1. `game.gd:287` — Redundant `as Dictionary` cast

`pending_by_id[skill_id]` already returns a Dictionary.

**✅ Fix applied:** Removed `as Dictionary` cast.

---

### R2. `wheel.gd:122-130` — Three sequential reassignments

```gdscript
cached_outcomes = WheelConfig.get_outcomes(...)
cached_outcomes = WheelConfig.apply_skill_modifiers(...)
cached_outcomes = WheelConfig.apply_display_modifiers(...)
```

*(Not applied — readability preference, no functional change.)*

---

### R3. `wheel_config.gd:78-162` — Ten `_get_wheel_N()` functions are repetitive data tables

*(Not applied — data-as-code is intentional for readability of individual wheel configs.)*

---

### R4. `main.gd:715-750` — Deeply nested closures in `_show_run_history_window`

*(Not applied — moderate refactor of single-use window.)*

---

### R6. `skill_manager.gd:62-93` — Hardcoded skill ID strings in `get_effect_text`

If a skill ID changes, `get_effect_text` silently returns the default `desc`.

*(Not applied — low risk, skill IDs are stable.)*

---

### R7. `wheel.gd:543-545` — Font lookup every draw call

`ThemeDB.fallback_font` called in `_draw()` every frame.

*(Not applied — minor overhead, theme may change at runtime.)*

---

### R8. `game.gd` — `suppress_coin_changed` pattern is fragile

Any early return between `suppress_coin_changed = true` and `flush_coin_changed()` leaves signals permanently suppressed.

*(Not applied — current usage is safe, all paths call `flush_coin_changed()`.)*

---

## Summary of Applied Fixes

| # | File | Fix |
|---|---|---|
| P1 | `wheel.gd` | Cached jackpot slot index, O(1) proximity check |
| B1 | `wheel_config.gd` | Empty-outcomes guard in `weighted_random` |
| B2 | `game.gd` | Null-outcome guard in `_finish_spin` |
| B3 | `game.gd` | Snapshot `_current_spin_wheel` in `begin_spin`, use throughout |
| B4 | `save_manager.gd` | Fixed `games_played` corruption in `increment_games_won` |
| B5 | `wheel.gd` | Recompute pointer base angle on `NOTIFICATION_RESIZED` |
| B6 | `wheel.gd` | Removed lazy `_refresh_outcomes()` from getter functions |
| B7 | `main.gd` | `is_instance_valid(self)` guards after every `await` |
| M2 | `main.gd` | Reset `canvas_transform` in `_exit_tree()` |
| A1 | `ui_format.gd`, `main.gd`, `end_screen.gd` | Centralized `format_elapsed` |
| A2 | `end_screen.gd` | Removed duplicated skill-summary, reuses `Game` methods |
| A3 | `shop.gd` | Removed duplicated discount calc, delegates to `Game` |
| A4 | `game.gd`, `wheel.gd` | Removed duplicate `IDX_*` consts, uses `WheelConfig` |
| A5 | 5 files | Added `## Static utility` doc comments |
| R1 | `game.gd` | Removed redundant `as Dictionary` cast |
