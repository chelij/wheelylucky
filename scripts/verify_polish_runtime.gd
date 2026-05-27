extends SceneTree

var failures: Array[String] = []
var music_signal_seen := false
var resolution_signal_seen := false
var reduced_motion_signal_seen := false
var muted_flashes_signal_seen := false
var large_ui_text_signal_seen := false
var history_signal_seen := false
var credits_signal_seen := false
var tutorial_signal_seen := false
var save_signal_seen := false
var original_save_config: ConfigFile = null
var save_manager: Node = null
var game: Node = null

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	save_manager = root.get_node_or_null("SaveManager")
	game = root.get_node_or_null("Game")
	if save_manager == null:
		_fail("SaveManager autoload missing")
		_finish()
		return
	if game == null:
		_fail("Game autoload missing")
		_finish()
		return
	_prepare_isolated_save_settings()
	await _verify_main_menu_runtime()
	await _verify_options_runtime()
	await _verify_run_history_runtime()
	await _verify_end_screen_breakdown_runtime()
	await _verify_visual_effect_runtime()
	_restore_save_settings()
	_finish()

func _prepare_isolated_save_settings() -> void:
	original_save_config = save_manager.get("config")
	var isolated_config := ConfigFile.new()
	isolated_config.set_value("settings", "tutorial_sign_seen", false)
	isolated_config.set_value("settings", "reduced_motion", false)
	save_manager.set("config", isolated_config)

func _restore_save_settings() -> void:
	if original_save_config != null:
		save_manager.set("config", original_save_config)
	original_save_config = null

func _verify_main_menu_runtime() -> void:
	var menu_scene := load("res://scenes/main_menu.tscn") as PackedScene
	if menu_scene == null:
		_fail("Main menu scene could not be loaded")
		return

	var menu := menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame
	_assert_no_runtime_tooltips(menu, "main menu")
	_assert_no_descendant_label(menu, "Coin Breakdown", "Main menu should not show coin breakdown")

	var sign := menu.get_node_or_null("TutorialSign") as Control
	if sign == null:
		_fail("Tutorial sign should appear when tutorial_sign_seen is false")
	else:
		if sign.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			_fail("Tutorial sign should be click-through")
		if sign.position.x < 18.0:
			_fail("Tutorial sign should stay within the viewport")
		if sign.get_node_or_null("ArrowHead") == null:
			_fail("Tutorial sign should use the graphic arrow treatment")

	if not bool(menu.get("tutorial_sign_tween") != null):
		_fail("Tutorial sign should bob when reduced motion is off")

	await _verify_menu_layout(menu, Vector2i(1024, 768), "narrow menu")
	await _verify_menu_layout(menu, Vector2i(3440, 1440), "ultrawide menu")

	menu.call("apply_accessibility_settings", {"reduced_motion": true})
	await process_frame
	if menu.get("tutorial_sign_tween") != null:
		_fail("Tutorial sign tween should stop when reduced motion is enabled")

	menu.connect("history_requested", func(): history_signal_seen = true)
	menu.connect("credits_requested", func(): credits_signal_seen = true)
	menu.connect("tutorial_requested", func(): tutorial_signal_seen = true)

	var history_button := menu.get_node_or_null("MenuPanel/MenuVBox/HistoryButton") as Button
	if history_button == null:
		_fail("Run History button missing from main menu")
	else:
		history_button.pressed.emit()

	var tutorial_button := menu.get_node_or_null("TutorialButton") as Button
	var credits_button := menu.get_node_or_null("MenuPanel/MenuVBox/CreditsButton") as Button
	if credits_button == null:
		_fail("Credits button missing from main menu")
	else:
		credits_button.pressed.emit()
	if tutorial_button == null:
		_fail("Tutorial button missing from main menu")
	else:
		tutorial_button.pressed.emit()
		await process_frame
		if not bool(save_manager.call("get_setting", "tutorial_sign_seen")):
			_fail("Tutorial sign seen flag should be saved after opening tutorial")
		if menu.get_node_or_null("TutorialSign") != null:
			_fail("Tutorial sign should be removed after opening tutorial")

	if not history_signal_seen:
		_fail("Run History button did not emit history_requested")
	if not credits_signal_seen:
		_fail("Credits button did not emit credits_requested")
	if not tutorial_signal_seen:
		_fail("Tutorial button did not emit tutorial_requested")
	if root.gui_get_focus_owner() != null:
		_fail("Main menu should not show focus borders before keyboard/controller navigation starts")
	menu.call("focus_default_control")
	await process_frame
	_expect_focus_owner(menu, "MenuPanel/MenuVBox/NewGameButton", "Main menu should focus New Game after keyboard/controller navigation starts")
	_expect_focus_neighbor(menu, "MenuPanel/MenuVBox/NewGameButton", "right", "TutorialButton", "Main menu should let controller focus reach the tutorial button")
	_expect_focus_neighbor(menu, "TutorialButton", "left", "MenuPanel/MenuVBox/NewGameButton", "Tutorial button should return focus to the menu buttons")

	_free_node(menu)
	await process_frame

	var second_menu := menu_scene.instantiate()
	root.add_child(second_menu)
	await process_frame
	await process_frame
	if second_menu.get_node_or_null("TutorialSign") != null:
		_fail("Tutorial sign should stay hidden after tutorial_sign_seen is saved")
	_free_node(second_menu)
	await process_frame

func _verify_options_runtime() -> void:
	var options_scene := load("res://scenes/options_modal.tscn") as PackedScene
	if options_scene == null:
		_fail("Options scene could not be loaded")
		return

	var options := options_scene.instantiate()
	root.add_child(options)
	await process_frame
	_assert_no_runtime_tooltips(options, "options modal")
	_assert_no_descendant_label(options, "Coin Breakdown", "Options modal should not show coin breakdown")

	var cramped_muted_settings := {
		"window_mode": "windowed",
		"resolution": "1024x768",
		"music_volume": 0.0,
		"sfx_volume": 0.5,
		"reduced_motion": false,
		"muted_flashes": false,
		"large_ui_text": false,
	}
	options.call("configure", cramped_muted_settings, ["1024x768", "1280x720"], false)
	await process_frame

	_expect_visible(options, "CenterContainer/Panel/VBox/ResolutionWarningLabel", true, "Cramped resolution warning is visible at 1024x768")
	_expect_visible(options, "CenterContainer/Panel/VBox/MusicMutedLabel", true, "Muted music warning is visible at zero music volume")

	var panel := options.get_node_or_null("CenterContainer/Panel") as PanelContainer
	if panel == null:
		_fail("Options panel missing")
	elif panel.custom_minimum_size.y < 660.0:
		_fail("Options panel should have enough height for accessibility and audio warnings")
	if root.gui_get_focus_owner() != null:
		_fail("Options should not show focus borders before keyboard/controller navigation starts")
	options.call("focus_default_control")
	await process_frame
	_expect_focus_owner(options, "CenterContainer/Panel/VBox/WindowModeSelector", "Options should focus Window Mode after keyboard/controller navigation starts")
	_expect_focus_neighbor(options, "CenterContainer/Panel/VBox/WindowModeSelector", "bottom", "CenterContainer/Panel/VBox/ResolutionSelector", "Options should move down from Window Mode to Resolution")
	_expect_focus_neighbor(options, "CenterContainer/Panel/VBox/LargeUiTextCheck", "bottom", "CenterContainer/Panel/VBox/BackButton", "Options should move from accessibility toggles to Back")

	options.connect("setting_changed", func(key: String, value):
		if key == "music_volume" and abs(float(value) - 0.5) < 0.001:
			music_signal_seen = true
		if key == "resolution" and str(value) == "1280x720":
			resolution_signal_seen = true
		if key == "reduced_motion" and bool(value):
			reduced_motion_signal_seen = true
		if key == "muted_flashes" and bool(value):
			muted_flashes_signal_seen = true
		if key == "large_ui_text" and bool(value):
			large_ui_text_signal_seen = true
	)

	var music_slider := options.get_node_or_null("CenterContainer/Panel/VBox/MusicVolumeSlider") as HSlider
	if music_slider == null:
		_fail("Music volume slider missing")
	else:
		music_slider.value = 0.5
		await process_frame
		_expect_visible(options, "CenterContainer/Panel/VBox/MusicMutedLabel", false, "Muted music warning hides after raising music volume")

	var resolution_selector := options.get_node_or_null("CenterContainer/Panel/VBox/ResolutionSelector") as OptionButton
	if resolution_selector == null:
		_fail("Resolution selector missing")
	else:
		resolution_selector.select(1)
		resolution_selector.item_selected.emit(1)
		await process_frame
		_expect_visible(options, "CenterContainer/Panel/VBox/ResolutionWarningLabel", false, "Cramped resolution warning hides at 1280x720")

	_toggle_checkbox(options, "CenterContainer/Panel/VBox/ReducedMotionCheck", "Reduced motion checkbox missing")
	_toggle_checkbox(options, "CenterContainer/Panel/VBox/MutedFlashesCheck", "Muted flashes checkbox missing")
	_toggle_checkbox(options, "CenterContainer/Panel/VBox/LargeUiTextCheck", "Large UI text checkbox missing")
	await process_frame

	if not music_signal_seen:
		_fail("Music slider did not emit a music_volume setting change")
	if not resolution_signal_seen:
		_fail("Resolution selector did not emit a resolution setting change")
	if not reduced_motion_signal_seen:
		_fail("Reduced motion checkbox did not emit a reduced_motion setting change")
	if not muted_flashes_signal_seen:
		_fail("Muted flashes checkbox did not emit a muted_flashes setting change")
	if not large_ui_text_signal_seen:
		_fail("Large UI text checkbox did not emit a large_ui_text setting change")

	_free_node(options)
	await process_frame

	var in_game_options := options_scene.instantiate()
	root.add_child(in_game_options)
	await process_frame
	in_game_options.call("configure", cramped_muted_settings, ["1024x768", "1280x720"], true)
	await process_frame
	in_game_options.connect("save_requested", func(): save_signal_seen = true)
	var save_button := in_game_options.get_node_or_null("CenterContainer/Panel/VBox/SaveButton") as Button
	if save_button == null:
		_fail("In-game Save button missing")
	elif not save_button.visible:
		_fail("In-game Save button should be visible")
	else:
		save_button.pressed.emit()
	in_game_options.call("focus_default_control")
	await process_frame
	_expect_focus_neighbor(in_game_options, "CenterContainer/Panel/VBox/LargeUiTextCheck", "bottom", "CenterContainer/Panel/VBox/SaveButton", "In-game options should move from accessibility toggles to Save")
	_expect_focus_neighbor(in_game_options, "CenterContainer/Panel/VBox/SaveButton", "bottom", "CenterContainer/Panel/VBox/SaveExitButton", "In-game options should move from Save to Save & Exit")
	if not save_signal_seen:
		_fail("Save button did not emit save_requested")
	_free_node(in_game_options)
	await process_frame

	var tutorial_scene := load("res://scenes/tutorial_modal.tscn") as PackedScene
	if tutorial_scene == null:
		_fail("Tutorial scene could not be loaded")
		return
	var tutorial := tutorial_scene.instantiate()
	root.add_child(tutorial)
	await process_frame
	_assert_no_runtime_tooltips(tutorial, "tutorial modal")
	_assert_no_descendant_label(tutorial, "Coin Breakdown", "Tutorial modal should not show coin breakdown")
	_free_node(tutorial)
	await process_frame

func _verify_run_history_runtime() -> void:
	game.set("coins", 777)
	game.set("selected_wheel", 4)
	game.set("shop_available", true)
	game.call("set_pending_shop_skill_ids", ["coin_magnet"])
	game.call("save_current_run")
	game.call("reset_run", false)
	if not game.call("load_saved_run"):
		_fail("Saved run should reload successfully during runtime verification")
	elif not bool(game.get("shop_available")):
		_fail("Saved run should restore pending shop availability")
	elif (game.call("get_pending_shop_skills") as Array).is_empty():
		_fail("Saved run should restore pending shop skill offers")

	for index in range(14):
		save_manager.call("add_run_history", {
			"run_id": index,
			"timestamp": "Test " + str(index),
			"final_coins": index * 100,
			"spins": index,
			"elapsed_seconds": index * 3,
			"highest_wheel": min(10, index + 1),
			"skills_bought": index % 5,
			"base_payout": index * 10,
			"skill_payout": index * 2,
			"spin_costs": index * 3,
			"shop_spent": index * 4,
			"skills": [],
		})

	var history := save_manager.call("get_run_history") as Array
	if history.size() != 12:
		_fail("Run history should keep exactly 12 newest entries after overflow")
		return
	if int(history[0].get("run_id", -1)) != 13:
		_fail("Newest run history entry should appear first")
	if int(history[history.size() - 1].get("run_id", -1)) != 2:
		_fail("Oldest retained history entry should be the overflow-trimmed boundary")

	var newest := history[0] as Dictionary
	for key in ["base_payout", "skill_payout", "spin_costs", "shop_spent", "final_coins", "highest_wheel", "skills_bought"]:
		if not newest.has(key):
			_fail("Run history entry missing breakdown field: " + key)

func _verify_end_screen_breakdown_runtime() -> void:
	game.set("coins", 12345)
	game.set("total_spins", 7)
	game.set("run_coins_earned", 15000)
	game.set("run_coins_spent", 2655)
	game.set("run_base_payout", 12000)
	game.set("run_skill_payout", 3000)
	game.set("run_spin_costs", 555)
	game.set("run_shop_spent", 2100)
	game.set("run_color_counts", {"green": 2, "red": 1, "gold": 1, "grey": 3, "jackpot": 1})
	game.set("bought_skill_order", [])
	game.set("skill_levels", {})
	game.set("unique_skills", [])

	var end_scene := load("res://scenes/end_screen.tscn") as PackedScene
	if end_scene == null:
		_fail("End screen scene could not be loaded")
		return
	var end_screen := end_scene.instantiate()
	root.add_child(end_screen)
	await process_frame
	_assert_no_runtime_tooltips(end_screen, "end screen")

	if end_screen.get_node_or_null("EndLayout/Panel/Content/BodyRow/OutcomePanel/VBox/CoinBreakdownTitle") == null:
		_fail("End screen should render Coin Breakdown title")
	_expect_descendant_label(end_screen, "Base payouts", "End screen should show base payout breakdown")
	_expect_descendant_label(end_screen, "Skill payouts", "End screen should show skill payout breakdown")
	_expect_descendant_label(end_screen, "Spin costs", "End screen should show spin cost breakdown")
	_expect_descendant_label(end_screen, "Shop spend", "End screen should show shop spend breakdown")
	end_screen.call("_populate_breakdown_rows")
	await process_frame
	if _count_descendant_labels(end_screen, "Coin Breakdown") != 1:
		_fail("End screen should not duplicate Coin Breakdown when populated twice")
	if root.gui_get_focus_owner() != null:
		_fail("End screen should not show focus borders before keyboard/controller navigation starts")
	end_screen.call("focus_default_control")
	await process_frame
	_expect_focus_owner(end_screen, "EndLayout/Panel/Content/ActionRow/PlayAgainButton", "End screen should focus Play Again after keyboard/controller navigation starts")
	_expect_focus_neighbor(end_screen, "EndLayout/Panel/Content/ActionRow/PlayAgainButton", "right", "EndLayout/Panel/Content/ActionRow/MainMenuButton", "End screen action buttons should support controller left/right movement")

	var jackpot_sound := end_screen.get_node_or_null("JackpotSound") as AudioStreamPlayer
	if jackpot_sound != null:
		jackpot_sound.stop()
		jackpot_sound.stream = null
	_free_node(end_screen)
	await process_frame

func _verify_visual_effect_runtime() -> void:
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	if main_scene == null:
		_fail("Main scene could not be loaded")
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	_assert_no_runtime_tooltips(main, "main scene")
	_assert_no_descendant_label(main, "Coin Breakdown", "Main scene should not show coin breakdown outside end/history surfaces")

	await _verify_main_layout(main, Vector2i(1024, 768), false, "narrow game")
	await _verify_main_layout(main, Vector2i(3440, 1440), false, "ultrawide game")
	main.call("_layout_game_ui", Vector2(1280, 720))
	await process_frame

	main.call("_apply_audio_settings", 0.0, 0.25)
	await process_frame
	var music_player := main.get_node_or_null("BackgroundMusic") as AudioStreamPlayer
	if music_player == null:
		_fail("Main scene background music player missing")
	else:
		if music_player.playing:
			_fail("Music volume zero should stop background music playback")
		if music_player.volume_db > -79.0:
			_fail("Music volume zero should lower music volume to silence")
	var result_sound := main.get_node_or_null("ResultPositiveSound") as AudioStreamPlayer
	if result_sound == null:
		_fail("Main scene result sound player missing")
	else:
		if abs(result_sound.volume_db - linear_to_db(0.25)) > 0.01:
			_fail("SFX volume should apply to result sound players")

	main.call("_apply_audio_settings", 0.6, 0.5)
	await process_frame
	if music_player != null:
		if music_player.stream_paused:
			_fail("Music volume above zero should unpause background music")
		if abs(music_player.volume_db - linear_to_db(0.6)) > 0.01:
			_fail("Music volume should apply to background music player")
	_free_audio_streams(main)

	main.call("_apply_accessibility_settings", {"reduced_motion": true, "muted_flashes": true, "large_ui_text": true})
	await process_frame
	if not bool(main.get("reduced_motion_enabled")):
		_fail("Main accessibility settings should enable reduced motion")
	if not bool(main.get("muted_flashes_enabled")):
		_fail("Main accessibility settings should enable muted flashes")
	if not bool(main.get("large_ui_text_enabled")):
		_fail("Main accessibility settings should enable large UI text")
	var coins_display := main.get_node_or_null("Wheel/CoinsDisplay") as Label
	if coins_display == null:
		_fail("Main scene coins display missing for large text check")
	else:
		if coins_display.get_theme_font_size("font_size") <= 30:
			_fail("Large UI text should increase existing main-scene label font size")
	main.call("_apply_accessibility_settings", {"reduced_motion": false, "muted_flashes": false, "large_ui_text": false})
	await process_frame

	save_manager.set("config", ConfigFile.new())
	var main_menu := main.get("main_menu_layer") as Node
	if main_menu == null:
		_fail("Main scene should instantiate the main menu layer")
	else:
		if root.gui_get_focus_owner() != null:
			_fail("Main scene should not show menu focus borders before keyboard/controller navigation starts")
		main.call("_set_navigation_focus_enabled", true)
		await process_frame
		_expect_focus_owner(main_menu, "MenuPanel/MenuVBox/NewGameButton", "Main scene should focus New Game once keyboard/controller navigation starts")
		main.call("_set_navigation_focus_enabled", false)
		await process_frame
		if root.gui_get_focus_owner() != null:
			_fail("Main scene should clear menu focus borders after mouse input mode resumes")
		var menu_history_button := main_menu.get_node_or_null("MenuPanel/MenuVBox/HistoryButton") as Button
		var menu_credits_button := main_menu.get_node_or_null("MenuPanel/MenuVBox/CreditsButton") as Button
		if menu_history_button == null:
			_fail("Main scene main-menu Run History button missing")
		else:
			menu_history_button.pressed.emit()
			await process_frame
			var menu_history_modal := main.get_node_or_null("Modal")
			if menu_history_modal == null:
				_fail("Main-menu Run History button should open the Run History modal")
			else:
				_assert_no_runtime_tooltips(menu_history_modal, "main-menu opened run history modal")
				_expect_descendant_label(menu_history_modal, "Run History", "Main-menu opened Run History modal should show title")
				_expect_descendant_label(menu_history_modal, "No completed runs yet", "Main-menu opened Run History modal should show empty state")
			main.call("_close_modal")
			await process_frame
		if menu_credits_button == null:
			_fail("Main scene main-menu Credits button missing")
		else:
			menu_credits_button.pressed.emit()
			await process_frame
			var credits_modal := main.get_node_or_null("Modal")
			if credits_modal == null:
				_fail("Main-menu Credits button should open the Credits modal")
			else:
				_expect_descendant_label(credits_modal, "Credits", "Credits modal should show title")
				_expect_descendant_label_contains(credits_modal, "Wheely Lucky ships CC0 assets", "Credits modal should list shipped asset notes")
			main.call("_close_modal")
			await process_frame

	main.call("_show_run_history_window")
	await process_frame
	var empty_history_modal := main.get_node_or_null("Modal")
	if empty_history_modal == null:
		_fail("Empty Run History modal should open from main scene")
	else:
		_assert_no_runtime_tooltips(empty_history_modal, "empty run history modal")
		_expect_descendant_label(empty_history_modal, "Run History", "Empty Run History modal should show title")
		_expect_descendant_label(empty_history_modal, "No completed runs yet", "Empty Run History modal should show empty state")
	main.call("_close_modal")
	await process_frame

	save_manager.call("add_run_history", {
		"timestamp": "Runtime History",
		"final_coins": 98765,
		"spins": 17,
		"elapsed_seconds": 125,
		"highest_wheel": 9,
		"skills_bought": 4,
		"base_payout": 12345,
		"skill_payout": 6789,
		"spin_costs": 321,
		"shop_spent": 654,
		"skills": [{"id": "coin_magnet", "name": "Coin Magnet", "level": 2, "unique": false}],
	})
	main.call("_show_run_history_window")
	await process_frame
	var history_modal := main.get_node_or_null("Modal")
	if history_modal == null:
		_fail("Run History modal should open from main scene")
	else:
		_assert_no_runtime_tooltips(history_modal, "run history modal")
		_expect_descendant_label(history_modal, "Run History", "Run History modal should show title")
		_expect_descendant_label_contains(history_modal, "Runtime History", "Run History modal should show saved run timestamp")
		_expect_descendant_label_contains(history_modal, "Wheel 9 reached", "Run History modal should show highest wheel detail")
		_expect_descendant_label_contains(history_modal, "Payouts: base", "Run History modal should show payout breakdown")
		_expect_descendant_label_contains(history_modal, "Spent: spins", "Run History modal should show spend breakdown")
		_expect_descendant_label_contains(history_modal, "Coin Magnet Lv.2", "Run History modal should show saved skill summary")
	main.call("_close_modal")
	await process_frame

	main.set("reduced_motion_enabled", false)
	main.set("muted_flashes_enabled", false)
	var initial_particles := _count_direct_effect_particles(main)
	main.call("_spawn_particle_burst", Vector2(320, 240), Color(1.0, 0.8, 0.2, 1.0), 5)
	await process_frame
	if _count_direct_effect_particles(main) - initial_particles != 5:
		_fail("Particle burst should add the requested number of particles")
	_clear_direct_effect_particles(main)

	main.set("muted_flashes_enabled", true)
	main.call("_spawn_particle_burst", Vector2(320, 240), Color(1.0, 0.8, 0.2, 1.0), 1)
	await process_frame
	var muted_particle := _first_direct_effect_particle(main)
	if muted_particle == null:
		_fail("Muted particle burst should still create particles")
	elif abs(muted_particle.color.a - 0.42) > 0.01:
		_fail("Muted flashes should lower particle alpha to 0.42")
	_clear_direct_effect_particles(main)

	main.set("reduced_motion_enabled", true)
	var reduced_start := _count_direct_effect_particles(main)
	main.call("_spawn_particle_burst", Vector2(320, 240), Color(1.0, 0.8, 0.2, 1.0), 4)
	await process_frame
	if _count_direct_effect_particles(main) != reduced_start:
		_fail("Reduced motion should suppress particle bursts")

	main.set("reduced_motion_enabled", false)
	main.set("muted_flashes_enabled", false)
	var jackpot_start := _count_direct_effect_particles(main)
	main.call("_play_result_polish", {"outcome_label": "JACKPOT", "spun_wheel": 10, "outcome_color": Color(1.0, 0.82, 0.24, 1.0)})
	await process_frame
	if _count_direct_effect_particles(main) - jackpot_start != 88:
		_fail("Jackpot result polish should dispatch the upgraded celebration burst")
	_clear_direct_effect_particles(main)

	var multiplier_start := _count_direct_effect_particles(main)
	main.call("_play_result_polish", {"outcome_label": "x12", "spun_wheel": 4, "outcome_color": Color(0.65, 0.35, 1.0, 1.0)})
	await process_frame
	if _count_direct_effect_particles(main) - multiplier_start != 24:
		_fail("Multiplier result polish should dispatch the upgraded burst")
	_clear_direct_effect_particles(main)

	var wheel := main.get_node_or_null("Wheel") as Control
	if wheel == null:
		_fail("Main scene wheel missing for indicator pulse check")
	else:
		var original_wheel_position := wheel.position
		var original_wheel_scale := wheel.scale
		var original_canvas_transform := root.canvas_transform
		main.call("_play_result_polish", {"outcome_label": "JACKPOT", "spun_wheel": 10, "outcome_color": Color(1.0, 0.82, 0.24, 1.0)})
		await create_timer(0.12).timeout
		_assert_wheel_focus_unchanged(wheel, original_wheel_position, original_wheel_scale, original_canvas_transform, "Standalone jackpot result polish should not assume a near-jackpot wheel state")
		_clear_direct_effect_particles(main)

		main.call("_play_result_polish", {"outcome_label": "x12", "spun_wheel": 4, "outcome_color": Color(0.65, 0.35, 1.0, 1.0)})
		await create_timer(0.08).timeout
		_assert_wheel_focus_unchanged(wheel, original_wheel_position, original_wheel_scale, original_canvas_transform, "Non-Wheel-10 multiplier result polish should not dispatch Wheel 10 focus movement")
		_clear_direct_effect_particles(main)

		main.call("_play_result_polish", {"outcome_label": "-6000000", "spun_wheel": 10, "outcome_color": Color(1.0, 0.2, 0.2, 1.0)})
		await create_timer(0.12).timeout
		_assert_wheel_focus_unchanged(wheel, original_wheel_position, original_wheel_scale, original_canvas_transform, "Standalone Wheel 10 result polish should not assume a near-jackpot wheel state")

		main.call("_play_w10_loss_focus")
		await create_timer(0.12).timeout
		var focus_moved := wheel.position != original_wheel_position or wheel.scale != original_wheel_scale or root.canvas_transform != original_canvas_transform
		if not focus_moved:
			_fail("Wheel 10 focus should move the wheel or zoom the viewport during the tween")
		await create_timer(1.0).timeout
		if wheel.position != original_wheel_position:
			_fail("Wheel 10 focus should restore wheel position")
		if wheel.scale.distance_to(original_wheel_scale) > 0.001:
			_fail("Wheel 10 focus should restore wheel scale")
		if root.canvas_transform != original_canvas_transform:
			_fail("Wheel 10 focus should restore viewport transform")

		main.set("reduced_motion_enabled", true)
		main.call("_play_w10_loss_focus")
		await process_frame
		if wheel.position != original_wheel_position or wheel.scale.distance_to(original_wheel_scale) > 0.001 or root.canvas_transform != original_canvas_transform:
			_fail("Reduced motion should suppress Wheel 10 focus movement")

		main.set("reduced_motion_enabled", false)
		var prev_button := wheel.get_node_or_null("PrevWheelButton") as Button
		var next_button := wheel.get_node_or_null("NextWheelButton") as Button
		var indicator := wheel.get_node_or_null("PointerArrow/PointerIndicator") as Control
		if prev_button == null or next_button == null or indicator == null:
			_fail("Wheel indicator or selector buttons missing for pulse check")
		else:
			var prev_scale := prev_button.scale
			var next_scale := next_button.scale
			var sparkles_before := _count_direct_effect_particles(main)
			main.call("_pulse_wheel_indicator")
			await process_frame
			if _count_direct_effect_particles(main) - sparkles_before != 16:
				_fail("Indicator pulse should create exactly 16 sparkle particles")
			if prev_button.scale != prev_scale:
				_fail("Indicator pulse should not scale the previous wheel selector")
			if next_button.scale != next_scale:
				_fail("Indicator pulse should not scale the next wheel selector")
	_clear_direct_effect_particles(main)

	game.call("reset_run", true)
	game.set("coins", 0)
	game.set("selected_wheel", 1)
	main.set("last_highest_affordable_wheel", 1)
	main.set("reduced_motion_enabled", false)
	main.set("muted_flashes_enabled", false)
	var triggered_sparkles_before := _count_direct_effect_particles(main)
	main.call("_on_spin_finished", ["+25", 0, 25.0, 60, Color(0.2, 0.8, 0.3, 1.0)])
	await create_timer(0.08).timeout
	if wheel != null and wheel.call("can_start_spin"):
		_fail("Wheel should not allow another spin while coin resolution animations are still counting")
	await create_timer(0.82).timeout
	if _count_direct_effect_particles(main) - triggered_sparkles_before != 16:
		_fail("Successful spin should sparkle the next-wheel arc when a higher wheel becomes affordable")
	if int(main.get("last_highest_affordable_wheel")) < 2:
		_fail("Successful spin should update last highest affordable wheel after indicator sparkle")
	if wheel != null and not wheel.call("can_start_spin"):
		_fail("Wheel should allow spinning again after coin resolution animations finish")
	_clear_direct_effect_particles(main)

	var no_new_sparkles_before := _count_direct_effect_particles(main)
	main.call("_on_spin_finished", ["0", 4, 0.0, 60, Color(0.5, 0.5, 0.5, 1.0)])
	await create_timer(0.82).timeout
	if _count_direct_effect_particles(main) != no_new_sparkles_before:
		_fail("Spin should not sparkle the next-wheel arc when highest affordable wheel does not increase")
	_clear_direct_effect_particles(main)

	_free_audio_streams(main)
	_free_node(main)
	await process_frame

	var shop_scene := load("res://scenes/shop.tscn") as PackedScene
	if shop_scene == null:
		_fail("Shop scene could not be loaded")
		return
	var shop := shop_scene.instantiate()
	game.set("coins", 500)
	game.call("set_pending_shop_skill_ids", ["coin_magnet", "discount_card", "momentum"])
	root.add_child(shop)
	await process_frame
	_assert_no_runtime_tooltips(shop, "shop scene")
	_assert_no_descendant_label(shop, "Coin Breakdown", "Shop scene should not show coin breakdown")
	if root.gui_get_focus_owner() != null:
		_fail("Shop should not show focus borders before keyboard/controller navigation starts")
	shop.call("focus_default_control")
	await process_frame
	_expect_focus_owner(shop, "CenterContainer/ShopPanel/ShopVBox/ScrollContainer/SkillsVBox/SkillCard1/Content/BuyButton", "Shop should focus the first affordable skill after keyboard/controller navigation starts")
	_expect_focus_neighbor(shop, "CenterContainer/ShopPanel/ShopVBox/ScrollContainer/SkillsVBox/SkillCard1/Content/BuyButton", "right", "CenterContainer/ShopPanel/ShopVBox/ScrollContainer/SkillsVBox/SkillCard2/Content/BuyButton", "Shop should allow controller movement across the skill row")
	_expect_focus_neighbor(shop, "CenterContainer/ShopPanel/ShopVBox/ScrollContainer/SkillsVBox/SkillCard1/Content/BuyButton", "bottom", "CenterContainer/ShopPanel/ShopVBox/ContinueButton", "Shop should allow controller movement from skills down to Continue")
	_expect_focus_neighbor(shop, "CenterContainer/ShopPanel/ShopVBox/ContinueButton", "top", "CenterContainer/ShopPanel/ShopVBox/ScrollContainer/SkillsVBox/SkillCard1/Content/BuyButton", "Shop Continue should return focus to the skill row")
	_free_audio_streams(shop)
	_free_node(shop)
	await process_frame

func _expect_visible(root_node: Node, path: String, expected: bool, label: String) -> void:
	var node := root_node.get_node_or_null(path) as CanvasItem
	if node == null:
		_fail(label + " node missing: " + path)
		return
	if node.visible != expected:
		_fail(label + " expected visible=" + str(expected) + " but was " + str(node.visible))

func _toggle_checkbox(root_node: Node, path: String, missing_message: String) -> void:
	var checkbox := root_node.get_node_or_null(path) as CheckBox
	if checkbox == null:
		_fail(missing_message)
		return
	checkbox.button_pressed = true

func _verify_menu_layout(menu: Node, viewport_size: Vector2i, context: String) -> void:
	menu.call("_layout_menu", Vector2(viewport_size))
	await process_frame
	_expect_control_inside(menu, "MenuPanel", Vector2(viewport_size), context + " keeps menu panel inside viewport")
	_expect_control_inside(menu, "Stage/Logo", Vector2(viewport_size), context + " keeps logo inside viewport")
	_expect_control_inside(menu, "TutorialButton", Vector2(viewport_size), context + " keeps tutorial button inside viewport")
	var sign := menu.get_node_or_null("TutorialSign") as Control
	if sign != null and sign.position.x < 18.0:
		_fail(context + " keeps tutorial sign inside viewport")

func _verify_main_layout(main: Node, viewport_size: Vector2i, expect_compact_panels: bool, context: String) -> void:
	var wheel_for_visibility := main.get_node_or_null("Wheel") as Control
	if wheel_for_visibility != null:
		wheel_for_visibility.visible = true
	main.call("_layout_game_ui", Vector2(viewport_size))
	await process_frame
	_expect_control_inside(main, "Wheel", Vector2(viewport_size), context + " keeps wheel inside viewport")
	_expect_control_inside(main, "InGameOptionsButton", Vector2(viewport_size), context + " keeps options button inside viewport")
	_expect_control_inside(main, "InGameHelpButton", Vector2(viewport_size), context + " keeps help button inside viewport")
	var stats_panel := main.get_node_or_null("StatsPanel") as Control
	if stats_panel == null:
		_fail(context + " has the stats panel")
	elif expect_compact_panels:
		if stats_panel.visible:
			_fail(context + " should hide the stats panel in compact layout")
	else:
		if not stats_panel.visible:
			_fail(context + " should show the stats panel in wide layout")
		_expect_control_inside(main, "StatsPanel", Vector2(viewport_size), context + " keeps stats panel inside viewport")

func _expect_control_inside(root_node: Node, path: String, viewport_size: Vector2, label: String) -> void:
	var control := root_node.get_node_or_null(path) as Control
	if control == null:
		_fail(label + " missing: " + path)
		return
	if control.position.x < -0.5 or control.position.y < -0.5:
		_fail(label + " has negative position: " + str(control.position))
	var bottom_right := control.position + control.size * control.scale
	if bottom_right.x > viewport_size.x + 0.5 or bottom_right.y > viewport_size.y + 0.5:
		_fail(label + " exceeds viewport: " + str(bottom_right) + " > " + str(viewport_size))

func _expect_focus_owner(root_node: Node, path: String, label: String) -> void:
	var control := root_node.get_node_or_null(path) as Control
	if control == null:
		_fail(label + " missing: " + path)
		return
	var owner := root.gui_get_focus_owner()
	if owner != control:
		_fail(label)

func _expect_focus_neighbor(root_node: Node, path: String, direction: String, expected_path: String, label: String) -> void:
	var control := root_node.get_node_or_null(path) as Control
	var expected := root_node.get_node_or_null(expected_path) as Control
	if control == null or expected == null:
		_fail(label + " missing focus controls")
		return
	var actual_path := NodePath("")
	match direction:
		"top":
			actual_path = control.focus_neighbor_top
		"bottom":
			actual_path = control.focus_neighbor_bottom
		"left":
			actual_path = control.focus_neighbor_left
		"right":
			actual_path = control.focus_neighbor_right
		_:
			_fail(label + " invalid direction: " + direction)
			return
	if actual_path.is_empty():
		_fail(label + " has no focus neighbor")
		return
	var actual := control.get_node_or_null(actual_path) as Control
	if actual != expected:
		_fail(label)

func _assert_wheel_focus_unchanged(wheel: Control, original_position: Vector2, original_scale: Vector2, original_canvas_transform: Transform2D, label: String) -> void:
	if wheel.position != original_position or wheel.scale.distance_to(original_scale) > 0.001 or root.canvas_transform != original_canvas_transform:
		_fail(label)

func _count_direct_effect_particles(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if _is_effect_particle(child):
			count += 1
	return count

func _first_direct_effect_particle(node: Node) -> ColorRect:
	for child in node.get_children():
		if _is_effect_particle(child):
			return child as ColorRect
	return null

func _clear_direct_effect_particles(node: Node) -> void:
	for child in node.get_children():
		if _is_effect_particle(child):
			_free_node(child)

func _is_effect_particle(node: Node) -> bool:
	if not node is ColorRect:
		return false
	var rect := node as ColorRect
	return rect.mouse_filter == Control.MOUSE_FILTER_IGNORE and rect.size.x <= 10.0 and rect.size.y <= 10.0

func _free_audio_streams(node: Node) -> void:
	if node is AudioStreamPlayer:
		var player := node as AudioStreamPlayer
		player.stop()
		player.stream = null
	for child in node.get_children():
		_free_audio_streams(child)

func _expect_descendant_label(root_node: Node, text: String, label: String) -> void:
	if not _has_descendant_label(root_node, text):
		_fail(label)

func _assert_no_descendant_label(root_node: Node, text: String, label: String) -> void:
	if _has_descendant_label(root_node, text):
		_fail(label)

func _expect_descendant_label_contains(root_node: Node, text: String, label: String) -> void:
	if not _has_descendant_label_containing(root_node, text):
		_fail(label)

func _has_descendant_label(node: Node, text: String) -> bool:
	if node is Label and (node as Label).text == text:
		return true
	for child in node.get_children():
		if _has_descendant_label(child, text):
			return true
	return false

func _count_descendant_labels(node: Node, text: String) -> int:
	var count := 0
	if node is Label and (node as Label).text == text:
		count += 1
	for child in node.get_children():
		count += _count_descendant_labels(child, text)
	return count

func _has_descendant_label_containing(node: Node, text: String) -> bool:
	if node is Label and (node as Label).text.find(text) != -1:
		return true
	for child in node.get_children():
		if _has_descendant_label_containing(child, text):
			return true
	return false

func _assert_no_runtime_tooltips(node: Node, context: String) -> void:
	if node is Control and not (node as Control).tooltip_text.is_empty():
		_fail("Runtime tooltip should be empty in " + context + ": " + str(node.get_path()))
	for child in node.get_children():
		_assert_no_runtime_tooltips(child, context)

func _fail(message: String) -> void:
	failures.append(message)

func _free_node(node: Node) -> void:
	if node == null:
		return
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()

func _finish() -> void:
	save_manager = null
	game = null
	if failures.is_empty():
		print("Polish runtime verification passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
