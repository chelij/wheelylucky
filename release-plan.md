# Wheely Lucky Release Plan

## Task List

- [x] Review current Godot gameplay, save, audio, shop, wheel, and end-screen code.
- [x] Review comparable roguelike casino games for release-facing expectations.
- [x] Add a release main menu with New Game, Continue, Stats, Options, and Exit.
- [x] Add persistent stats for games started, wins, total spins, spins by outcome, and skill levels bought.
- [x] Add persistent options for window mode, resolution, music volume, and sound effects volume.
- [x] Add an in-game Options button with Save & Exit.
- [x] Replace debug hotkeys with a `~` dev tools menu using numbered functions.
- [x] Add dev tools for spin speed and coins gained.
- [x] Create and wire a new end-game background image using the `imagegen` skill.
- [x] Add end-game run stats for total spins, outcome hits, skill purchases, coins earned, and coins spent.
- [x] Add CC0 background music and record its source.
- [x] Add a proper game logo asset and replace main-menu title text with it.
- [x] Rename player-facing outcome labels to Plus, Minus, Multiply, None, and Jackpot.
- [x] Add How to Play help buttons on the main menu and in-game screen.
- [x] Add gameplay instructions, wheel-cost notes, goal text, outcome glossary, and full skill/unique glossary to How to Play.
- [x] Replace the How to Play scrollbar with multi-page navigation using the wheel arrow buttons.
- [x] Run Godot import/validation after asset and script changes.
- [x] Fix release-blocking issues found by validation.

## Active Polish Task List

This replaces `polish.md`. Use this section as the single source of truth for the next polish pass.

- [x] Fix sequential skill coin modifiers so each owned-skill payout reads as a distinct staged event instead of all modifiers feeling simultaneous.
- [x] Replace the current background music with an actual song-like CC0 casino/lounge track. The current asset reads like SFX, not BGM.
- [x] Keep current button hover/press SFX behavior. User approved it.
- [x] Keep current resolution options behavior. User confirmed it works.
- [x] Default BGM and SFX volumes to 50% on first launch (instead of 100%).
- [x] Re-test aspect-ratio support after the UI pass. Narrow and ultrawide layout checks now pass in runtime verification.
- [x] Replace or redesign the logo. Current logo is not acceptable.
- [x] Rework Wheel 10 near-jackpot tension:
  - [x] Only trigger the dramatic effect when the wheel is stopping near the jackpot region.
  - [x] Slow the wheel as it approaches the stop.
  - [x] Zoom in and shake during the near-jackpot settle.
  - [x] Delay the jackpot end-screen handoff so the player can actually see the effect.
- [x] Make jackpot bursts much fancier and more celebratory.
- [x] Replace the first-run tutorial text callout with a graphic treatment.
- [x] Redesign Run History:
  - [x] Paginate it.
  - [x] Make it visually match the end-game screen language.
  - [x] Remove the current rough card-list presentation.
- [x] Keep the current end/history breakdown calculations. User confirmed the numbers are OK.
- [x] Keep the current accessibility options behavior. User approved it.
- [x] Re-check the resolution warning after the UI pass. Runtime verification now confirms the warning appears below 1280x720 and hides at 1280x720+.
- [x] Replace the separate probability table with text displayed directly on the wheel segments for outcome labels and values.
- [x] Fix UI spacing — review padding, margins, and alignment across main menu, game screen, shop, end screen, and How to Play panels.
- [x] Rework the higher-wheel indicator sparkle/pulse so it is actually visible in normal play.

## Current Polish Review

- Skill coin modifier effect: updated to hold internal coin accounting while the HUD reveals each skill payout in sequence.
- BGM: replaced with proper song-like CC0 casino/lounge track. ✓
- Button hover and press SFX: accepted.
- Resolution options: accepted.
- Default volumes: updated to 50% on first launch.
- Aspect ratio: re-checked at narrow and ultrawide sizes in runtime verification. ✓
- Logo: switched to the alpha-safe `game-logo.png` asset and wired into the main menu.
- Wheel 10 focus: updated to only fire in the near-jackpot zone and to give jackpot outcomes time to breathe before the end screen.
- Jackpot bursts: upgraded into a larger multi-layer celebration pass.
- First-run tutorial: updated from text to a graphic arrow treatment.
- Run history: updated into a paginated summary layout styled closer to the end screen.
- End/history breakdown: accepted.
- Accessibility options: accepted.
- Resolution warning: re-checked in runtime verification and now treated as complete. ✓
- Probability display: moved off the separate panel and onto wheel segments directly with per-segment labels and values.
- UI spacing: tightened around the single right-side upgrades panel and centered wheel layout.
- Indicator sparkle/pulse: upgraded with a larger pulse, flash ring, and stronger sparkle burst.

## Comparable Game References

- [Balatro](https://store.steampowered.com/app/2379780/Balatro/) is the clearest reference for casino roguelike presentation: readable stakes, strong run summary, and clear build identity matter more than explaining every internal calculation.
- [Luck be a Landlord](https://store.steampowered.com/app/1404850/Luck_be_a_Landlord/) is the closest slot-machine roguelike reference: the game succeeds when the player can quickly understand symbol odds, income, and next-purchase decisions.
- [Dungeons & Degenerate Gamblers](https://store.steampowered.com/app/2400510/Dungeons__Degenerate_Gamblers/) reinforces that casino-themed roguelikes need clean card/item effect text, strong run history, and fast restart flow.
- Follow-up UI reference pass:
  - Balatro screenshots show that casino roguelikes benefit from a strong title treatment, a focused menu composition, and a game-over/run state that is screenshot-readable.
  - Luck be a Landlord's menu/UI reference reinforces simple large buttons and immediately readable slot-machine identity.
  - Dungeons & Degenerate Gamblers' menu assets use themed card/button art instead of generic UI panels; Wheely Lucky now follows that direction with textured button art and casino stage composition.

## Changes Made

- Added a script-built main menu in `scripts/main.gd`:
  - New Game starts a fresh recorded run.
  - Continue is disabled when no saved run exists.
  - Stats opens persistent lifetime stats.
  - Options opens release settings.
  - Exit closes the game.
- Reworked the main menu into a release-style title screen:
  - Full casino stage background.
  - Large `assets/ui/game-logo.png` logo placed center-left.
  - Right-side menu button panel.
  - Textured casino button art using existing UI assets.
  - Dimmed Continue state remains visually disabled.
- Added square `?` How to Play buttons:
  - Main menu top-right.
  - Game screen top-right beside Options.
- Added How to Play content:
  - Goal.
  - Spinning rules.
  - Wheel selection and spin costs.
  - Shop explanation.
  - Outcome glossary.
  - Upgradeable skill glossary.
  - Unique skill glossary.
- Reworked How to Play into paged content:
  - Removed the long scrollbar layout.
  - Added fixed pages for Basics, Wheels & Shops, Outcomes, Upgradeable Skills, and Unique Skills.
  - Reused the existing wheel left/right arrow art for page navigation.
- Expanded `scripts/save_manager.gd`:
  - Persistent settings.
  - Lifetime stats.
  - Saved active run data for Continue.
- Expanded `scripts/game.gd`:
  - Run outcome counts.
  - Coins earned and coins spent.
  - Saved/resumable run state.
  - Games-started and games-won tracking.
  - Dev coin gain multiplier.
  - Pending shop offers now persist through Save/Continue.
- Added in-game Options button at the top-right of the play screen.
- Added Save & Exit from in-game Options back to the main menu.
- Added an in-game Save action separate from Save & Exit.
- Added confirmation before replacing a saved run with New Game.
- Added confirmation before Save & Exit returns to the main menu.
- Added a Credits screen from the main menu with shipped asset/source notes.
- Added a clearer pulsing shop-available affordance on the shop button.
- Added explicit keyboard/controller focus routing for the main menu, options modal, shop skill row, and end-screen action/build controls.
- Added a `~` dev tools overlay and removed direct Q/W/E/A/S debug hotkey behavior.
- Added dev tool functions:
  - Instant spin.
  - Add coins.
  - Toggle skill picker.
  - Open shop.
  - Show end screen.
  - Change spin speed.
  - Change coins gained.
- Remade the end-game screen in `scripts/end_screen.gd`:
  - Replaced the old cluttered detail panel layout.
  - One large final score.
  - Five quick metric cards.
  - Outcome-hit panel.
  - Compact run-build icon grid with tooltips instead of permanent detail text.
  - Play Again and Main Menu actions.
- Renamed visible outcome wording:
  - Green is now Plus.
  - Red is now Minus.
  - Gold is now Multiply.
  - Grey is now None.
  - Shop skill descriptions and help text now use the new outcome names.
  - Probability rows now show names, for example `Plus +25` and `None 0`.
- Added generated end-game background:
  - `assets/backgrounds/end-game-jackpot-stage.png`
- Added deterministic game logo:
  - Source: `assets/ui/game-logo.svg`
  - Runtime asset: `assets/ui/game-logo.png`
- Added CC0 music:
  - `assets/sounds/background-music.wav`
  - Source recorded in `assets/sounds/SOURCES.md`.

## Missing Or Release-Blocking Items Found

- `export_presets.cfg` is now present for desktop release targets (`Windows Desktop` and `Linux/X11`), but this machine does not currently have Godot export templates installed, so full package export is not locally verified yet.
- Godot editor import exits successfully, but still prints `split.size()` scan warnings from existing editor filesystem metadata. Runtime validation is clean.

## Audio / Visual Passthrough

- BGM: replaced with a proper song-like CC0 casino/lounge track. ✓
- The menu and exported app icon now use the alpha-safe `game-logo.png` logo pass.
- The new end-game background fits the theme and leaves center space for stats, but the text panel should be checked at 1280x720, 1600x900, and fullscreen.
- Outcome labels and values now live directly on the wheel segments, which removes the separate probability side panel and frees more space for the main play layout.
- Wheel 10 now uses the near-jackpot theatrical stopping sequence and delayed handoff.
- Jackpot celebration effects are on the upgraded multi-layer burst pass.
- The higher-wheel/shop affordances now use clearer pulsing feedback.

## UX Passthrough

- Keyboard/controller navigation now has explicit focus routing for menu, options, shop, and end-screen grids.

## Asset Notes

- End-game background prompt used built-in `image_gen`:
  - Stylized 16:9 jackpot casino stage, roulette-wheel silhouette, coins, velvet curtains, warm marquee lighting, no text/logos, clean center negative space.
- Music source:
  - [Jazz n' brass loop](https://opengameart.org/content/jazz-n-brass-loop) by Emma_MA, CC0.

## Validation

- `godot --headless --editor --path . --quit` completed successfully and imported `end-game-jackpot-stage.png` plus `background-music.wav`.
- `godot --headless --path . --quit` completed successfully with no runtime script errors after skipping music playback in headless mode.
- `env HOME=/tmp godot --headless --editor --path . --quit` completed successfully with `export_presets.cfg` present.
- `env HOME=/tmp godot --headless --path . --export-release "Linux/X11" /tmp/wheely-lucky.x86_64` and `env HOME=/tmp godot --headless --path . --export-release "Windows Desktop" /tmp/wheely-lucky.exe` both reached preset validation and failed only because export templates are not installed in this environment.
- `xvfb-run -a godot --path . --script /tmp/wheely_ui_screenshots.gd` rendered visual verification screenshots:
  - `/tmp/wheely-main-menu.png`
  - `/tmp/wheely-how-to-play.png`
  - `/tmp/wheely-game-screen.png`
  - `/tmp/wheely-end-screen.png`
- `xvfb-run -a godot --path . --script /tmp/wheely_help_pages_screenshots.gd` rendered all How to Play pages:
  - `/tmp/wheely-how-to-play-page-1.png`
  - `/tmp/wheely-how-to-play-page-2.png`
  - `/tmp/wheely-how-to-play-page-3.png`
  - `/tmp/wheely-how-to-play-page-4.png`
  - `/tmp/wheely-how-to-play-page-5.png`
- `python3 scripts/sim_playtime.py 1 --gd-only` completed successfully; balance parsing still matches the Godot data.
- `git diff --check` completed successfully.
