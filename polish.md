# Polish Task List

Status policy: implementation tasks can be checked during development, but every user-facing polish item remains **Incomplete / needs user testing** until user testing explicitly confirms it is done.

## Requested Polish

- [ ] **Incomplete / needs user testing - Sequential skill coin-add animation**
  - [x] Identified post-spin coin sources: Coin Magnet, Sharp Mind, Free Gift, Banker, and Second Wind.
  - [x] Queue coin additions one-by-one after the base spin result.
  - [x] Show a floating coin delta from the matching owned skill icon when the icon is visible.
  - [x] Add a short glow/ping on the skill icon during that payout.
  - [x] Change Coin Magnet from modifying flat Plus value to adding a percent of the visible positive Plus value after Plus spins.
  - [x] Ensure Sharp Mind multiplier payout also uses the sequential skill ping.
  - [ ] Playtest timing and readability during normal spins.
- [ ] **Incomplete / needs user testing - CC0 casino ambient BGM**
  - [x] Verify BGM license/source is CC0 in `assets/sounds/SOURCES.md`.
  - [x] Wire the BGM as looping background music.
  - [x] Confirm music volume is controlled by the music slider in code.
  - [x] Strengthen playback after reported inaudible BGM: start music immediately after setup and resume when the music slider is above zero.
  - [x] Add an Options warning when the music slider is at zero so saved muted settings are visible.
  - [x] Boost the shipped BGM asset after a second inaudible-BGM report while keeping the CC0 source and loop length.
  - [ ] Playtest loop point and mix level.
- [ ] **Incomplete / needs user testing - CC0 button hover and press SFX**
  - [x] Add short CC0/public-domain hover SFX.
  - [x] Add short CC0/public-domain press SFX.
  - [x] Import both WAV files into Godot.
  - [x] Wire SFX to menu, options, shop, in-game, and dynamic buttons through central button discovery.
  - [x] Confirm SFX volume is controlled by the SFX slider in code.
  - [ ] Playtest loudness and repetition fatigue.
- [ ] **Incomplete / needs user testing - Resolution options**
  - [x] Add common 16:9, 16:10, 4:3/5:4, ultrawide, and 4K-style options.
  - [x] Keep default mode Windowed at 1280x720.
  - [ ] Playtest settings behavior on target displays.
- [ ] **Incomplete / needs user testing - Aspect-ratio support**
  - [x] Configure Godot stretch settings for multiple aspect ratios with `canvas_items` + `expand`.
  - [x] Make main game panels, wheel, and controls reposition responsively.
  - [x] Make main menu layout responsive across narrow, wide, and ultrawide windows.
  - [ ] Playtest several physical/windowed aspect ratios for overlap and readability.
- [ ] **Incomplete / needs user testing - Logo improvement**
  - [x] Use the best available local logo asset: `assets/ui/game-logo.png`.
  - [x] Wire selected logo into the main menu scene.
  - [x] Avoid new logo generation or large montage review per current instruction.
  - [ ] User review: decide whether the current local logo is final.

## Additional Polish Suggestions

- [ ] **Incomplete / needs user testing - Wheel 10 non-jackpot shake/focus**
  - [x] Shake the wheel on Wheel 10 non-jackpot outcomes.
  - [x] Add a small viewport/camera zoom toward the pointer area.
  - [ ] Playtest intensity and timing.
- [ ] **Incomplete / needs user testing - Jackpot and multiply particle bursts**
  - [x] Add a jackpot burst around the pointer result area.
  - [x] Add a smaller multiply burst around the pointer result area.
  - [ ] Playtest readability and whether bursts distract from coin feedback.
- [ ] **Incomplete / needs user testing - First-run tutorial sign**
  - [x] Add a first-run bobbing tutorial sign pointing to the tutorial button.
  - [x] Keep the sign click-through so it cannot block tutorial button use.
  - [x] Respect reduced-motion settings for the bobbing.
  - [x] Use a dedicated tutorial-sign-seen flag instead of old run counters, so existing local saves can still see it once.
  - [x] Dismiss and save the tutorial sign after opening the tutorial.
  - [ ] Playtest whether the sign appears only when useful.
- [ ] **Incomplete / needs user testing - Recent-run history**
  - [x] Store completed run history with final coins, highest wheel reached, key skills, and breakdown values.
  - [x] Add a Run History button on the main menu.
  - [x] Render recent runs from saved history.
  - [x] Track highest wheel reached when a higher wheel is selected, not only after it is spun.
  - [ ] Playtest history persistence after a completed run.
- [ ] **Incomplete / needs user testing - End/history cost and payout breakdown**
  - [x] Track base payouts, skill payouts, spin costs, and shop spend separately.
  - [x] Show breakdown on the end screen.
  - [x] Guard the end-screen breakdown against duplicate row insertion.
  - [x] Show breakdown in run history.
  - [ ] Playtest numbers against a real run.
- [ ] **Incomplete / needs user testing - Accessibility options**
  - [x] Add options for reduced motion, muted flashes, and larger UI text.
  - [x] Wire reduced motion into tutorial sign, bursts, Wheel 10 focus, indicator pulse, and end-screen intro.
  - [x] Wire muted flashes into particle alpha.
  - [x] Apply larger text scaling to current UI controls.
  - [x] Apply larger text scaling to dynamic UI controls when they are created.
  - [x] Apply larger text scaling after instancing main menu, options, tutorial, and end-screen scenes.
  - [x] Refresh the open main menu tutorial sign immediately when reduced motion changes.
  - [ ] Playtest every option in menu and in-game flows.
- [ ] **Skipped by request - Hover tooltips**
  - [x] Do not add hover behavior for probability rows.
  - [x] Remove probability-row tooltip text from the chart rows.
  - [x] Remove remaining informational hover tooltips from main, menu, tutorial, shop, wheel, and end-screen UI.
  - [x] Keep requested button hover SFX separate from tooltip/hover-content behavior.
- [ ] **Incomplete / needs user testing - Resolution warning**
  - [x] Add a settings preview warning for cramped resolutions.
  - [ ] Playtest warning copy and when it appears.
- [ ] **Incomplete / needs user testing - Wheel indicator sparkle/pulse**
  - [x] Add sparkle/pulse only on the pointer wheel indicator when a higher wheel becomes affordable.
  - [x] Avoid changing wheel selector buttons.
  - [ ] Playtest trigger timing and visibility.

## Manual Playtest Checklist

Use this section for hands-on review. Keep these unchecked until the behavior is manually tested in a playable window.

- [ ] Skill coin rewards: confirm base coin result appears first, then skill coin events appear one-by-one from owned skill icons, with readable timing and glow.
- [ ] BGM: confirm background music is audible when the music slider is above zero, muted when the slider is zero, loops acceptably, and sits below game SFX at the default slider values.
- [ ] Button SFX: confirm hover and press sounds are audible but not tiring across menu, options, shop, tutorial, and in-game buttons.
- [ ] Resolutions: confirm Windowed 1280x720 is the default, fullscreen/windowed changes work, and common aspect ratios do not trap the window off-screen.
- [ ] Aspect ratios: test at least 1024x768, 1280x720, 1920x1080, 2560x1080, and 3440x1440 for overlap/readability.
- [ ] Logo: decide whether `assets/ui/game-logo.png` is the final logo.
- [ ] Wheel 10 non-jackpot: confirm wheel shake and camera focus feel tense but not excessive.
- [ ] Jackpot/multiply bursts: confirm particle bursts are readable and do not hide coin feedback.
- [ ] Tutorial sign: confirm the first-run sign points to the tutorial button, bobs only when reduced motion is off, and disappears after opening tutorial.
- [ ] Run history: complete a run and confirm it appears from the main-menu Run History button after returning/relaunching.
- [ ] End/history breakdown: compare base payouts, skill payouts, spin costs, and shop spend against a real run.
- [ ] Accessibility: test reduced motion, muted flashes, and larger UI text in menu, options, tutorial, game, shop, history, and end-screen flows.
- [ ] Resolution warning: confirm cramped-resolution warning appears below 1280x720 and the copy is acceptable.
- [ ] Indicator sparkle/pulse: confirm sparkle/pulse appears only on the pointer wheel indicator when a higher wheel becomes affordable.

## Implementation Audit

| Additional suggestion | Local implementation evidence | Remaining gate |
| --- | --- | --- |
| Wheel 10 shake/focus | `scripts/main.gd` runs `_play_w10_loss_focus()` only for non-jackpot Wheel 10 results, shakes `wheel_node`, and zooms `canvas_transform` toward `PointerArrow/PointerIndicator`. | Manual intensity/timing playtest. |
| Jackpot/multiply bursts | `scripts/main.gd` spawns a larger gold burst for `JACKPOT` and a smaller outcome-colored burst for labels beginning with `x`. | Manual readability/distraction playtest. |
| First-run tutorial sign | `scripts/main_menu.gd` creates click-through `Tutorial ->`, loops bobbing unless reduced motion is enabled, saves `tutorial_sign_seen`, and removes the sign after tutorial opens. | Manual first-run usefulness playtest. |
| Recent-run history | `scripts/save_manager.gd` stores capped newest-first history; `scripts/main_menu.gd` exposes `history_requested`; `scripts/main.gd` renders Run History cards from saved data. | Manual completed-run persistence playtest. |
| End/history breakdown only | `scripts/end_screen.gd` renders `Coin Breakdown`; `scripts/main.gd` history cards show payout/spend breakdown; verifier asserts main HUD, main menu, options, tutorial, shop, and wheel surfaces do not render `Coin Breakdown`. | Manual number comparison against a real run. |
| Accessibility options | `scripts/options_modal.gd` emits reduced motion, muted flashes, and large UI text; `scripts/main.gd` applies them live and to dynamic/modal/end-screen UI. | Manual menu/in-game accessibility playtest. |
| No hover tooltips | `tooltip_text` has been removed from polished UI files; button hover SFX/styles remain because they are separate requested SFX feedback. | No manual completion needed unless user wants stricter no-hover styling. |
| Resolution warning | `scripts/options_modal.gd` shows `ResolutionWarningLabel` below 1280x720. | Manual copy/threshold review. |
| Indicator sparkle/pulse | `scripts/main.gd` pulses/sparkles `PointerArrow/PointerIndicator` only when `highest > last_highest_affordable_wheel`; verifier checks selector buttons are not targeted. | Manual trigger visibility playtest. |

## Additional Suggestions Current State

| Item | Implementation | Automated evidence | Manual gate |
| --- | --- | --- | --- |
| 1. Wheel 10 shake/focus | Implemented | Source + runtime result-dispatch/tween restore checks | Feel/intensity |
| 2. Jackpot/multiply bursts | Implemented | Source + runtime burst count/result-dispatch checks | Readability/distraction |
| 3. First-run tutorial sign | Implemented | Source + runtime first-run, dismissal, reduced-motion, and persisted suppression checks | Usefulness |
| 4. Recent-run history | Implemented | Source + runtime button signal, empty state, saved modal, cap, newest-first checks | Real completed-run persistence |
| 5. End/history breakdown only | Implemented | Source + runtime end-screen rows and history modal breakdown checks | Number comparison against a real run |
| 6. Accessibility options | Implemented | Source + runtime checkbox signal and main-scene application checks | Whole-flow playtest |
| 7. No hovers | Implemented for informational tooltips | Source + runtime empty tooltip checks | None unless stricter no-hover styling is requested |
| 8. Resolution warning | Implemented | Source + runtime warning visibility checks | Copy/threshold approval |
| 9. Indicator sparkle/pulse | Implemented | Source + runtime sparkle count and selector-unchanged checks | Trigger timing/visibility |

## Verification

- [x] Godot asset import run completed for new button SFX.
- [x] `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] After additional polish pass, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After additional polish pass, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After additional polish pass, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] After audit refinement, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After audit refinement, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After audit refinement, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] After tutorial/breakdown hardening, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After tutorial/breakdown hardening, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After tutorial/breakdown hardening, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] After accessibility propagation hardening, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After accessibility propagation hardening, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After accessibility propagation hardening, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] After live reduced-motion refresh hardening, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After live reduced-motion refresh hardening, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After live reduced-motion refresh hardening, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] After tutorial sign seen-flag update, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After tutorial sign seen-flag update, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After tutorial sign seen-flag update, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] After highest-wheel history refinement, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After highest-wheel history refinement, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After highest-wheel history refinement, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Added source-only polish smoke verification script at `scripts/verify_polish.gd`.
- [x] `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified the requested polish source paths.
- [x] After adding polish smoke verification, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After adding polish smoke verification, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After adding polish smoke verification, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Fixed `scripts/verify_polish.gd` to inspect scene files without instantiating scenes, avoiding standalone-script autoload errors.
- [x] After smoke verifier fix, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After smoke verifier fix, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After smoke verifier fix, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After smoke verifier fix, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Confirmed `assets/sounds/background-music.wav` is a valid 27.44s stereo WAV; after the inaudible-BGM follow-up it measures `mean_volume: -12.8 dB` and `max_volume: -1.0 dB`.
- [x] After BGM playback robustness update, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After BGM playback robustness update, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After BGM playback robustness update, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After BGM playback robustness update, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish.gd` to check the BGM slider pause/resume and non-headless resume guard.
- [x] After extending BGM smoke coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After extending BGM smoke coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] Removed remaining `tooltip_text` hover content from game/menu/tutorial/shop/wheel/end-screen UI; `rg -n "tooltip_text" scripts scenes -g '!scripts/verify_polish.gd'` returns no matches.
- [x] Extended `scripts/verify_polish.gd` to guard against tooltip regressions in the polished UI files.
- [x] After no-hover cleanup, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After no-hover cleanup, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After no-hover cleanup, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After no-hover cleanup, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Removed dead end-screen skill tooltip helper functions left over after no-hover cleanup.
- [x] Extended `scripts/verify_polish.gd` to assert coin breakdown stays out of the main HUD, shop, and wheel scripts.
- [x] Extended `scripts/verify_polish.gd` to assert the indicator sparkle/pulse path does not target wheel selector buttons.
- [x] After polish scope audit cleanup, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After polish scope audit cleanup, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After polish scope audit cleanup, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After polish scope audit cleanup, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish.gd` to assert tutorial sign bobbing, reduced-motion response, saved dismissal, and queue-free removal.
- [x] Extended `scripts/verify_polish.gd` to assert the resolution warning threshold and visible warning copy.
- [x] After tutorial/accessibility smoke coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After tutorial/accessibility smoke coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After tutorial/accessibility smoke coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After tutorial/accessibility smoke coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish.gd` to assert run history main-menu wiring, empty state, saved-card rendering, capped newest-first persistence, and history breakdown fields.
- [x] After run-history smoke coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After run-history smoke coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After run-history smoke coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After run-history smoke coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish.gd` to assert Coin Magnet, Sharp Mind, Free Gift, Banker, and Second Wind all create visible skill coin events.
- [x] Extended `scripts/verify_polish.gd` to assert Coin Magnet uses percentage-based Plus value payout, Free Gift adds coins, skill events play sequentially, and skill icon glow/ping is present.
- [x] After sequential skill coin smoke coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After sequential skill coin smoke coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After sequential skill coin smoke coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After sequential skill coin smoke coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish.gd` to assert Wheel 10 focus only runs on non-jackpot Wheel 10 results, targets the pointer, shakes the wheel, zooms/restores the viewport, and respects reduced motion.
- [x] Extended `scripts/verify_polish.gd` to assert jackpot bursts are larger/gold, multiply bursts are smaller/outcome-colored, and particle bursts respect muted flashes.
- [x] After Wheel 10/particle smoke coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After Wheel 10/particle smoke coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After Wheel 10/particle smoke coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After Wheel 10/particle smoke coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish.gd` to assert indicator sparkle/pulse triggers only when a higher wheel becomes affordable and uses the pointer indicator sparkle path.
- [x] Extended `scripts/verify_polish.gd` to assert options changes persist/apply live, accessibility state updates main UI, dynamic labels/buttons receive large-text scaling, modals/end screen receive scaling, and end-screen intro respects reduced motion.
- [x] After accessibility/indicator coverage audit, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After accessibility/indicator coverage audit, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After accessibility/indicator coverage audit, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After accessibility/indicator coverage audit, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish.gd` to guard all polished scene files against `tooltip_text` regressions, including options, shop, and end screen scenes.
- [x] Confirmed `rg -n "tooltip_text" scripts scenes -g '!scripts/verify_polish.gd'` returns no matches.
- [x] After full scene no-tooltip coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After full scene no-tooltip coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After full scene no-tooltip coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After full scene no-tooltip coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish.gd` to guard the status policy and keep all manual playtest checklist gates unchecked until user testing.
- [x] After manual-gate status coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After manual-gate status coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After manual-gate status coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After manual-gate status coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish.gd` to guard top-level user-facing parent items as unchecked until manual user testing.
- [x] After parent-gate status coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After parent-gate status coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After parent-gate status coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After parent-gate status coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish.gd` to assert BGM/button SFX source ledger entries, CC0 licensing text, WAV files, Godot import sidecars, main-scene audio resources, volume sliders, and hover/press SFX wiring.
- [x] After audio asset/wiring coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After audio asset/wiring coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After audio asset/wiring coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After audio asset/wiring coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish.gd` to assert default 1280x720 windowed settings, `canvas_items` + `expand` stretch, common resolution options, fullscreen/windowed application, and responsive game/menu layout breakpoints.
- [x] After resolution/aspect coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After resolution/aspect coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After resolution/aspect coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After resolution/aspect coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish.gd` to assert the first-run tutorial sign is positioned next to the top-right tutorial button, has a stable readable size, and right-aligns the arrow toward the button.
- [x] After tutorial-sign layout coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After tutorial-sign layout coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After tutorial-sign layout coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After tutorial-sign layout coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Added an Options warning for the saved-muted BGM case so players can see when the music slider is preventing background music playback.
- [x] Extended `scripts/verify_polish.gd` to assert the muted-music warning node, copy, and zero-slider visibility logic.
- [x] After muted-BGM warning update, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After muted-BGM warning update, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After muted-BGM warning update, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After muted-BGM warning update, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Added `scripts/verify_polish_runtime.gd` for headless runtime checks of Options warning visibility and live setting signals.
- [x] Extended `scripts/verify_polish.gd` to require the runtime polish verifier and its warning/signal coverage.
- [x] `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified runtime Options warning behavior.
- [x] After runtime verifier addition, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After runtime verifier addition, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After runtime verifier addition, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After runtime verifier addition, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish_runtime.gd` to isolate save settings and verify main-menu tutorial sign creation, click-through behavior, reduced-motion bobbing disablement, tutorial dismissal, and Run History button signaling.
- [x] Extended `scripts/verify_polish.gd` to require the runtime verifier's main-menu tutorial/history coverage.
- [x] Fixed `scripts/verify_polish_runtime.gd` to look up the SaveManager autoload dynamically so the standalone verifier can compile while still isolating save settings.
- [x] After main-menu runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified Options plus main-menu polish behavior.
- [x] After main-menu runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After main-menu runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After main-menu runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After main-menu runtime coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish_runtime.gd` to verify saved run history is capped at 12 entries, newest-first, and preserves final coin, highest-wheel, skill-count, payout, and spend fields.
- [x] Extended `scripts/verify_polish_runtime.gd` to instantiate the end screen with temporary Game values and verify the runtime Coin Breakdown rows for base payouts, skill payouts, spin costs, and shop spend.
- [x] Extended `scripts/verify_polish.gd` to require the runtime verifier's saved-history and end-screen breakdown coverage.
- [x] Guarded end-screen jackpot audio in headless mode so runtime polish verification exits cleanly without audio resource leaks.
- [x] After history/breakdown runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified Options, main-menu, history, and end-screen polish behavior.
- [x] After history/breakdown runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After history/breakdown runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After history/breakdown runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After history/breakdown runtime coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish_runtime.gd` to toggle the reduced motion, muted flashes, and larger UI text checkboxes and verify each emits its live setting change.
- [x] Extended `scripts/verify_polish.gd` to require the runtime verifier's accessibility checkbox signal coverage.
- [x] After accessibility checkbox runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified Options, main-menu, history, and end-screen polish behavior.
- [x] After accessibility checkbox runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After accessibility checkbox runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After accessibility checkbox runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After accessibility checkbox runtime coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish_runtime.gd` to instantiate the main scene and verify particle burst counts, muted-flash alpha, reduced-motion burst suppression, indicator sparkle count, and unchanged wheel selector button scale.
- [x] Extended `scripts/verify_polish.gd` to require the runtime verifier's visual-effect and indicator-selector coverage.
- [x] After visual-effect runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified Options, main-menu, history, end-screen, particle, and indicator polish behavior.
- [x] After visual-effect runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After visual-effect runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After visual-effect runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After visual-effect runtime coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish_runtime.gd` to verify Wheel 10 focus moves/zooms during the tween, restores wheel/camera state afterward, and is suppressed by reduced motion.
- [x] Extended `scripts/verify_polish.gd` to require the runtime verifier's Wheel 10 focus movement, restoration, and reduced-motion suppression coverage.
- [x] After Wheel 10 focus runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified Options, main-menu, history, end-screen, particle, indicator, and Wheel 10 focus polish behavior.
- [x] After Wheel 10 focus runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After Wheel 10 focus runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After Wheel 10 focus runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After Wheel 10 focus runtime coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish_runtime.gd` to verify `_play_result_polish()` dispatches jackpot, multiplier, and Wheel 10 non-jackpot result dictionaries into the expected particle/focus effects.
- [x] Extended `scripts/verify_polish.gd` to require runtime result-dispatch coverage for jackpot bursts, multiplier bursts, and Wheel 10 focus.
- [x] After result-polish dispatch coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified Options, main-menu, history, end-screen, particle, indicator, Wheel 10 focus, and result-dispatch polish behavior.
- [x] After result-polish dispatch coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After result-polish dispatch coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After result-polish dispatch coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After result-polish dispatch coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish_runtime.gd` to verify main-scene application of music volume pause/unpause, SFX volume, reduced motion, muted flashes, and larger UI text scaling.
- [x] Extended `scripts/verify_polish.gd` to require runtime coverage for main-scene audio/accessibility setting application.
- [x] Hardened zero-volume BGM handling so applying music volume zero stops playback and keeps the stream muted, while nonzero volume resumes outside headless verification.
- [x] After main-scene audio/accessibility runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified Options, main-menu, history, end-screen, audio/accessibility, particle, indicator, Wheel 10 focus, and result-dispatch polish behavior.
- [x] After main-scene audio/accessibility runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After main-scene audio/accessibility runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After main-scene audio/accessibility runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After main-scene audio/accessibility runtime coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish_runtime.gd` to open the main-scene Run History modal from isolated saved history and verify title, highest-wheel detail, payout/spend breakdown, and skill summary rendering.
- [x] Extended `scripts/verify_polish.gd` to require runtime Run History modal rendering coverage.
- [x] After Run History modal runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified Options, main-menu, Run History modal, history storage, end-screen, audio/accessibility, particle, indicator, Wheel 10 focus, and result-dispatch polish behavior.
- [x] After Run History modal runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After Run History modal runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After Run History modal runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After Run History modal runtime coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish_runtime.gd` to assert instantiated main menu, options, end screen, main scene, and Run History modal controls have empty runtime tooltip text.
- [x] Extended `scripts/verify_polish.gd` to require runtime no-tooltip coverage in addition to source no-tooltip checks.
- [x] After runtime no-tooltip coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified no runtime tooltip text across instantiated polished UI.
- [x] After runtime no-tooltip coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After runtime no-tooltip coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After runtime no-tooltip coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After runtime no-tooltip coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish_runtime.gd` to resize the headless viewport and verify menu/game controls stay inside 1024x768 and 3440x1440 layouts, including compact hidden side panels and wide visible side panels.
- [x] Extended `scripts/verify_polish.gd` to require runtime responsive-layout coverage for narrow and ultrawide resolutions.
- [x] Updated main-menu and game layout methods to accept an optional explicit viewport size so runtime verification can exercise narrow and ultrawide layout math even under Godot's fixed headless stretch viewport.
- [x] After responsive-layout runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified narrow/ultrawide menu and game layout behavior.
- [x] After responsive-layout runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After responsive-layout runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After responsive-layout runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After responsive-layout runtime coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish_runtime.gd` to open the main-scene Run History modal with no saved runs and verify the empty-state message renders.
- [x] Extended `scripts/verify_polish.gd` to require runtime Run History empty-state coverage.
- [x] After Run History empty-state runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified empty and populated Run History modal behavior.
- [x] After Run History empty-state runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After Run History empty-state runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After Run History empty-state runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After Run History empty-state runtime coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish_runtime.gd` to instantiate a fresh main menu after tutorial dismissal and verify the tutorial sign stays hidden once `tutorial_sign_seen` is saved.
- [x] Extended `scripts/verify_polish.gd` to require runtime coverage for first-run tutorial sign suppression after dismissal.
- [x] After tutorial sign first-run suppression coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified tutorial sign dismissal persists across a fresh menu instance.
- [x] After tutorial sign first-run suppression coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After tutorial sign first-run suppression coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After tutorial sign first-run suppression coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After tutorial sign first-run suppression coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Added `Additional Suggestions Current State` summary table mapping all nine requested suggestions to implementation status, automated evidence, and remaining manual gates.
- [x] Extended `scripts/verify_polish.gd` to require the current-state summary while still guarding unchecked manual/user-facing gates.
- [x] After current-state summary update, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified runtime polish behavior.
- [x] After current-state summary update, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After current-state summary update, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After current-state summary update, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After current-state summary update, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish_runtime.gd` to assert instantiated main and shop scenes do not show `Coin Breakdown`, while end screen and Run History remain the allowed breakdown surfaces.
- [x] Extended `scripts/verify_polish.gd` to require runtime no-breakdown coverage for main and shop scenes.
- [x] After runtime no-breakdown scope coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified main/shop omit `Coin Breakdown`.
- [x] After runtime no-breakdown scope coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After runtime no-breakdown scope coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After runtime no-breakdown scope coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After runtime no-breakdown scope coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish_runtime.gd` to call the end-screen breakdown population path twice and verify `Coin Breakdown` is not duplicated.
- [x] Extended `scripts/verify_polish.gd` to require runtime coverage for the end-screen breakdown duplicate guard.
- [x] After end-screen breakdown duplicate-guard coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified duplicate breakdown rows are not inserted.
- [x] After end-screen breakdown duplicate-guard coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After end-screen breakdown duplicate-guard coverage, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After end-screen breakdown duplicate-guard coverage, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After end-screen breakdown duplicate-guard coverage, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Extended `scripts/verify_polish_runtime.gd` to simulate spin results and verify pointer indicator sparkle triggers only when a higher wheel becomes affordable.
- [x] Extended `scripts/verify_polish.gd` to require runtime coverage for indicator sparkle trigger and non-trigger paths.
- [x] Hardened dynamic large-text deferred hooks to use instance IDs so quickly freed runtime nodes do not produce deferred-call errors during verification.
- [x] Boosted `assets/sounds/background-music.wav` after an inaudible-BGM follow-up; verified the adjusted WAV remains a valid 27.44s stereo loop with `mean_volume: -12.8 dB` and `max_volume: -1.0 dB`.
- [x] Documented the BGM gain adjustment in `assets/sounds/SOURCES.md` and extended `scripts/verify_polish.gd` to guard that source-ledger note.
- [x] After BGM gain and verifier updates, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified runtime polish behavior without resource-leak log errors.
- [x] After BGM gain and verifier updates, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After BGM gain and verifier updates, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After BGM gain and verifier updates, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] After BGM gain and verifier updates, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] Restored the recovered uncommitted large-number wheel balance from local Git object `92c0b5c8f72af71efa018a5d8864c0612ed98241`: W9 reaches `+1000000`, W10 costs `12000000`, and W10 non-jackpot losses are `-6000000`.
- [x] Updated `scripts/verify_polish.gd` so paid wheels must retain at least one positive outcome path that can cover the spin cost, which matches the restored balance where later wheels use multiplier outcomes for cost-covering wins.
- [x] Added `wheel_balance.md` as a local source-of-truth snapshot for the recovered large-number balance, including spin costs and slot outcomes.
- [x] Tuned later-wheel flat Plus outcomes to keep late wheels worth spinning without making W10 too easy: W5 `+1800`, W6 `+7500`, W7 `+27000`, W8 `+190000`, W9 `+1700000`.
- [x] Extended `scripts/verify_polish.gd` to guard `wheel_balance.md` and the matching `scripts/wheel_config.gd` W5-W9 Plus values against accidental drift.
- [x] After balance snapshot/verifier updates, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] After balance snapshot/verifier updates, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified runtime polish behavior.
- [x] After balance snapshot/verifier updates, `python3 scripts/sim_playtime.py 1 --gd-only` completed and parsed the current Godot balance config.
- [x] After balance snapshot/verifier updates, `godot --headless --path . --log-file /tmp/wheelylucky-godot.log --quit` completed without project errors.
- [x] After balance snapshot/verifier updates, `godot --headless --path . --log-file /tmp/wheelylucky-run.log --quit-after 3` completed without project errors.
- [x] Confirmed manual playtest checklist items remain unchecked pending user testing.
- [x] Extended `scripts/verify_polish_runtime.gd` so the end/history-only breakdown rule also verifies the main menu, options modal, and tutorial modal do not show `Coin Breakdown`.
- [x] After broader no-breakdown runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified runtime polish behavior.
- [x] After broader no-breakdown runtime coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] Extended `scripts/verify_polish_runtime.gd` to verify jackpot and non-Wheel-10 multiplier result polish do not dispatch Wheel 10 shake/zoom focus, while Wheel 10 non-jackpot still does.
- [x] After Wheel 10 negative-focus coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified runtime polish behavior.
- [x] After Wheel 10 negative-focus coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
- [x] Extended `scripts/verify_polish_runtime.gd` to press the actual main-menu Run History button from an instantiated main scene and verify it opens the Run History modal empty state.
- [x] After main-menu Run History button coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-runtime.log --script res://scripts/verify_polish_runtime.gd` completed and verified runtime polish behavior.
- [x] After main-menu Run History button coverage, `godot --headless --path . --log-file /tmp/wheelylucky-polish-smoke.log --script res://scripts/verify_polish.gd` completed and verified requested polish source paths.
