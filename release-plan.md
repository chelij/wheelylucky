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
- [x] Rename player-facing outcome labels to Plus, Minus, Multiply, Divide, None, and Jackpot.
- [x] Add How to Play help buttons on the main menu and in-game screen.
- [x] Add gameplay instructions, wheel-cost notes, goal text, outcome glossary, and full skill/unique glossary to How to Play.
- [x] Replace the How to Play scrollbar with multi-page navigation using the wheel arrow buttons.
- [x] Run Godot import/validation after asset and script changes.
- [x] Fix release-blocking issues found by validation.

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
- Added in-game Options button at the top-right of the play screen.
- Added Save & Exit from in-game Options back to the main menu.
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
  - Purple is now Divide.
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

- No export presets are configured yet for a release build. Add `export_presets.cfg` when target platforms are decided.
- Godot editor import exits successfully, but still prints `split.size()` scan warnings from existing editor filesystem metadata. Runtime validation is clean.
- There is no pause/resume confirmation before Save & Exit. This is acceptable for now because it explicitly saves, but a confirmation would avoid accidental menu returns.
- Continue currently resumes the run state but intentionally does not restore an unopened shop offer. This avoids serializing temporary shop choices, but it means Save & Exit should be used between spins, not during a pending shop decision.
- There is no credits screen yet. Add one before public release because the game now ships CC0 assets with source links.
- The How to Play panel now covers the rules and skill glossary across pages, but a short first-run callout could still help brand-new players.

## Audio / Visual Passthrough

- The game now has casino-appropriate background music, but it needs an in-game listen pass for loudness against spin/shop/jackpot sounds.
- The wheel and shop visuals have a strong identity; the main menu is functional but should eventually get bespoke button art matching the shop buttons.
- The new end-game background fits the theme and leaves center space for stats, but the text panel should be checked at 1280x720, 1600x900, and fullscreen.
- The probability panel is useful, but it is visually dense. Consider adding subtle outcome labels or icons so Minus/Plus/Multiply meaning is faster to scan.
- The wheel itself intentionally has no labels for readability; keep the probability panel visible and accurate.

## UX Passthrough

- Add a short first-run tooltip explaining that clicking the background spins and higher wheels unlock when affordable.
- Add a run-history screen showing recent wins/losses, final coins, key skills, and highest wheel reached.
- Add confirmation on New Game when a saved run exists.
- Add keyboard/controller navigation for menu, options, shop, and end-screen grids.
- Add an explicit "Save" action separate from Save & Exit if longer runs are expected.
- Add a credits screen from the main menu.
- Add display of current spin cost changes from skills so players understand why costs shift.
- Add a clearer "shop available" pulse because the shop button can be missed during fast play.

## Asset Notes

- End-game background prompt used built-in `image_gen`:
  - Stylized 16:9 jackpot casino stage, roulette-wheel silhouette, coins, velvet curtains, warm marquee lighting, no text/logos, clean center negative space.
- Music source:
  - [Jazz n' brass loop](https://opengameart.org/content/jazz-n-brass-loop) by Emma_MA, CC0.

## Validation

- `godot --headless --editor --path . --quit` completed successfully and imported `end-game-jackpot-stage.png` plus `background-music.wav`.
- `godot --headless --path . --quit` completed successfully with no runtime script errors after skipping music playback in headless mode.
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
