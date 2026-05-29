# scripts/main.gd
extends Control

const SkillManager = preload("res://scripts/skill_manager.gd")
const WheelConfig = preload("res://scripts/wheel_config.gd")
const UiFormat = preload("res://scripts/ui_format.gd")

@export var shop_scene: PackedScene
@export var end_screen_scene: PackedScene
@export var menu_background_texture: Texture2D
@export var menu_button_texture: Texture2D
@export var coin_texture: Texture2D
@export var skill_icon_atlas: Texture2D
@export var button_hover_stream: AudioStream
@export var button_press_stream: AudioStream
@export var options_modal_scene: PackedScene
@export var tutorial_modal_scene: PackedScene
@export var main_menu_scene: PackedScene

@onready var upgrades_vbox: VBoxContainer = $StatsPanel/StatsVBox/UpgradesScroll/UpgradesVBox
@onready var wheel_node: Control = $Wheel
@onready var coins_display: Label = $Wheel/CoinsDisplay
@onready var pointer_indicator: Control = $Wheel/PointerArrow/PointerIndicator
@onready var result_positive_sound: AudioStreamPlayer = $ResultPositiveSound
@onready var result_negative_sound: AudioStreamPlayer = $ResultNegativeSound
@onready var multiplier_sound: AudioStreamPlayer = $MultiplierSound
@onready var w10_loss_sound: AudioStreamPlayer = $W10LossSound
@onready var shop_open_sound: AudioStreamPlayer = $ShopOpenSound
@onready var music_player: AudioStreamPlayer = $BackgroundMusic
@onready var in_game_options_button: Button = $InGameOptionsButton
@onready var in_game_help_button: Button = $InGameHelpButton

var button_hover_sound: AudioStreamPlayer = null
var button_press_sound: AudioStreamPlayer = null
var debug_skills_layer: CanvasLayer = null
var main_menu_layer: CanvasLayer = null
var modal_layer: CanvasLayer = null
var dev_tools_layer: CanvasLayer = null
var dev_spin_speed_index: int = 4
var dev_coin_gain_index: int = 0
var dev_shop_list_page: int = 0
var skill_icon_frames: Dictionary = {}
var reduced_motion_enabled: bool = false
var muted_flashes_enabled: bool = false
var large_ui_text_enabled: bool = false
var last_highest_affordable_wheel: int = 1
var w10_preview_focus_played: bool = false
var navigation_focus_enabled: bool = false
var effect_rng := RandomNumberGenerator.new()

const MAX_WHEELS = 10
const RESOLUTION_OPTIONS := [
	"1024x768",
	"1280x720",
	"1280x800",
	"1280x960",
	"1366x768",
	"1600x900",
	"1680x1050",
	"1920x1080",
	"1920x1200",
	"2560x1080",
	"2560x1440",
	"2560x1600",
	"3440x1440",
	"3840x2160",
]
const SPIN_SPEED_OPTIONS := [0.35, 0.65, 1.0, 1.5, 2.5]
const COIN_GAIN_OPTIONS := [1.0, 2.0, 5.0, 10.0, 50.0]
const DEBUG_SHOP_PAGE_SIZE := 4
const RUN_HISTORY_PAGE_SIZE := 3

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	effect_rng.randomize()
	get_viewport().size_changed.connect(_layout_game_ui)
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)
	_setup_button_sounds()
	_setup_in_game_options_button()
	_apply_saved_settings()
	_setup_background_music()

	_make_non_buttons_click_through(self)

	wheel_node.spin_finished.connect(_on_spin_finished)
	wheel_node.spin_started.connect(_on_wheel_spin_started)
	if wheel_node.has_signal("near_jackpot_tension"):
		wheel_node.connect("near_jackpot_tension", _on_near_jackpot_tension)
	wheel_node.shop_requested.connect(_on_shop_button_requested)
	Game.shop_available_changed.connect(_on_shop_available_changed)
	Game.game_ended.connect(_on_game_ended)
	Game.skills_changed.connect(_on_skills_changed)

	_update_stats()
	_on_shop_available_changed(Game.shop_available)
	_set_game_ui_visible(false)
	_layout_game_ui()
	_show_main_menu()

func _exit_tree() -> void:
	for player in [
		result_positive_sound,
		result_negative_sound,
		multiplier_sound,
		w10_loss_sound,
		shop_open_sound,
		music_player,
		button_hover_sound,
		button_press_sound,
	]:
		if player != null:
			player.stop()
			player.stream = null
	# Reset viewport transform in case _play_w10_loss_focus tween was killed mid-flight.
	if is_inside_tree():
		get_viewport().canvas_transform = Transform2D()

func _make_non_buttons_click_through(node: Node):
	# Let clicks fall through decorative UI panels so the wheel can be clicked anywhere.
	for child in node.get_children():
		if child is Button:
			pass
		elif child is ScrollContainer:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
		elif child is Label or child is TextureRect or child is ColorRect or child is PanelContainer:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_make_non_buttons_click_through(child)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		_set_navigation_focus_enabled(true)
		if event.unicode == 126:
			_toggle_dev_tools()
			get_viewport().set_input_as_handled()
		elif _is_dev_tools_open() and _handle_dev_tool_key(event.keycode):
			get_viewport().set_input_as_handled()
		elif get_viewport().gui_get_focus_owner() == null:
			_focus_default_control_for_active_surface()
	elif event is InputEventJoypadButton and event.pressed:
		_set_navigation_focus_enabled(true)
		if get_viewport().gui_get_focus_owner() == null:
			_focus_default_control_for_active_surface()
	elif event is InputEventJoypadMotion and abs(event.axis_value) > 0.55:
		_set_navigation_focus_enabled(true)
		if get_viewport().gui_get_focus_owner() == null:
			_focus_default_control_for_active_surface()
	elif event is InputEventMouseMotion:
		_set_navigation_focus_enabled(false)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_navigation_focus_enabled(false)
		# A background click spins the wheel, but never steal clicks from active buttons, modals, or stats panel.
		if wheel_node.has_method("can_start_spin") and bool(wheel_node.call("can_start_spin")) and not _is_modal_open() and not _is_mouse_over_enabled_button(event.position) and not _is_click_on_stats_panel(event.position) and not _is_popup_open():
			wheel_node.start_spin()
			get_viewport().set_input_as_handled()

func _setup_background_music() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if music_player == null:
		return
	if music_player.stream == null:
		return
	music_player.autoplay = false
	music_player.stream_paused = false
	if not music_player.finished.is_connected(_restart_background_music):
		music_player.finished.connect(_restart_background_music)
	call_deferred("_ensure_background_music_playing")

func _ensure_background_music_playing() -> void:
	if music_player == null or music_player.stream == null:
		return
	if not music_player.playing:
		music_player.play()

func _restart_background_music() -> void:
	if music_player == null or music_player.stream == null:
		return
	music_player.play()

func _apply_saved_settings() -> void:
	var settings := SaveManager.get_all_settings()
	_apply_window_settings(str(settings.get("window_mode", "windowed")), str(settings.get("resolution", "1280x720")))
	_apply_audio_settings(float(settings.get("music_volume", 0.5)), float(settings.get("sfx_volume", 0.5)))
	_apply_accessibility_settings(settings)

func _apply_accessibility_settings(settings: Dictionary) -> void:
	reduced_motion_enabled = bool(settings.get("reduced_motion", false))
	muted_flashes_enabled = bool(settings.get("muted_flashes", false))
	large_ui_text_enabled = bool(settings.get("large_ui_text", false))
	_apply_large_ui_text(self)
	if main_menu_layer != null and is_instance_valid(main_menu_layer) and main_menu_layer.has_method("apply_accessibility_settings"):
		main_menu_layer.call("apply_accessibility_settings", settings)

func _apply_large_ui_text(node: Node) -> void:
	for child in node.get_children():
		if child is Label or child is Button:
			_apply_large_ui_text_to_control(child)
		_apply_large_ui_text(child)

func _apply_large_ui_text_to_control(node: Node) -> void:
	var control := node as Control
	if control == null or not (control is Label or control is Button):
		return
	if not control.has_meta("base_font_size"):
		control.set_meta("base_font_size", control.get_theme_font_size("font_size"))
	var base_size := int(control.get_meta("base_font_size"))
	control.add_theme_font_size_override("font_size", int(round(float(base_size) * (1.14 if large_ui_text_enabled else 1.0))))

func _apply_large_ui_text_to_control_deferred(instance_id: int) -> void:
	var node := instance_from_id(instance_id)
	if node != null:
		_apply_large_ui_text_to_control(node)

func _apply_window_settings(window_mode: String, resolution: String) -> void:
	var parts := resolution.split("x")
	var width := 1280
	var height := 720
	if parts.size() == 2:
		width = int(parts[0])
		height = int(parts[1])
	if window_mode == "fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(width, height))
		var screen_size := DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen_size - Vector2i(width, height)) / 2)

func _apply_audio_settings(music_volume: float, sfx_volume: float) -> void:
	if music_player != null:
		var was_playing := music_player.playing
		music_player.volume_db = _volume_to_db(music_volume)
		var music_muted := music_volume <= 0.001
		if music_muted:
			music_player.stop()
		music_player.stream_paused = music_muted
		if not music_muted and was_playing and not music_player.playing:
			music_player.play()
	for player in [result_positive_sound, result_negative_sound, multiplier_sound, w10_loss_sound, shop_open_sound, button_hover_sound, button_press_sound]:
		if player == null:
			continue
		player.volume_db = _volume_to_db(sfx_volume)
	if wheel_node != null and wheel_node.has_node("SpinSound"):
		wheel_node.get_node("SpinSound").volume_db = _volume_to_db(sfx_volume)

func _setup_button_sounds() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if button_hover_stream == null or button_press_stream == null:
		return
	button_hover_sound = AudioStreamPlayer.new()
	button_hover_sound.name = "ButtonHoverSound"
	button_hover_sound.stream = button_hover_stream
	add_child(button_hover_sound)

	button_press_sound = AudioStreamPlayer.new()
	button_press_sound.name = "ButtonPressSound"
	button_press_sound.stream = button_press_stream
	add_child(button_press_sound)

	call_deferred("_wire_existing_button_sounds")

func _wire_existing_button_sounds() -> void:
	for button in _get_all_buttons(self):
		_wire_button_sounds(button)

func _on_node_added(node: Node) -> void:
	if node is Button:
		call_deferred("_wire_button_sounds", node)
	if node is Label or node is Button:
		call_deferred("_apply_large_ui_text_to_control_deferred", node.get_instance_id())

func _wire_button_sounds(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	if button.has_meta("button_sounds_wired"):
		return
	button.set_meta("button_sounds_wired", true)
	button.mouse_entered.connect(func():
		if not button.disabled and button_hover_sound != null:
			button_hover_sound.play()
	)
	button.pressed.connect(func():
		if button_press_sound != null:
			button_press_sound.play()
	)

func _volume_to_db(value: float) -> float:
	if value <= 0.001:
		return -80.0
	return linear_to_db(clamp(value, 0.0, 1.0))

func _format_elapsed(total_seconds: int) -> String:
	return UiFormat.format_elapsed(total_seconds)

func _set_game_ui_visible(is_visible: bool) -> void:
	wheel_node.visible = is_visible
	$StatsPanel.visible = is_visible
	if in_game_options_button != null:
		in_game_options_button.visible = is_visible
	if in_game_help_button != null:
		in_game_help_button.visible = is_visible
	_layout_game_ui()

func _layout_game_ui(viewport_override: Vector2 = Vector2.ZERO) -> void:
	if wheel_node == null:
		return
	var viewport_size := viewport_override if viewport_override != Vector2.ZERO else get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var margin: float = 28.0
	var stats_visible := wheel_node.visible and viewport_size.x >= 980.0

	# StatsPanel positioning handled entirely by scene anchors/offsets
	$StatsPanel.visible = stats_visible

	if in_game_options_button != null:
		in_game_options_button.position = Vector2(max(margin, viewport_size.x - 196.0), 20.0)
	if in_game_help_button != null:
		in_game_help_button.position = Vector2(max(margin, viewport_size.x - 62.0), 20.0)

func _setup_in_game_options_button() -> void:
	in_game_options_button.pressed.connect(func(): _show_options_window(true))
	in_game_help_button.pressed.connect(_show_how_to_play_window)

func _show_main_menu() -> void:
	_close_modal()
	if main_menu_layer != null and is_instance_valid(main_menu_layer):
		main_menu_layer.queue_free()
	if main_menu_scene == null:
		return
	main_menu_layer = main_menu_scene.instantiate()
	add_child(main_menu_layer)
	_apply_large_ui_text(main_menu_layer)
	if main_menu_layer.has_method("set_continue_available"):
		main_menu_layer.call("set_continue_available", SaveManager.has_saved_run())
	if main_menu_layer.has_method("apply_accessibility_settings"):
		main_menu_layer.call("apply_accessibility_settings", SaveManager.get_all_settings())
	main_menu_layer.connect("new_game_requested", _start_new_game)
	main_menu_layer.connect("continue_requested", _continue_game)
	main_menu_layer.connect("stats_requested", _show_stats_window)
	main_menu_layer.connect("history_requested", _show_run_history_window)
	main_menu_layer.connect("credits_requested", _show_credits_window)
	main_menu_layer.connect("options_requested", func(): _show_options_window(false))
	main_menu_layer.connect("tutorial_requested", _show_how_to_play_window)
	main_menu_layer.connect("exit_requested", func(): get_tree().quit())
	if navigation_focus_enabled:
		_focus_default_control_for_active_surface()

func _make_menu_button(text: String, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(340, 64 if primary else 58)
	button.add_theme_font_size_override("font_size", 27 if primary else 23)
	button.add_theme_stylebox_override("normal", _make_menu_button_style(Color(0.96, 0.93, 0.86, 1), primary))
	button.add_theme_stylebox_override("hover", _make_menu_button_style(Color(1.12, 1.05, 0.92, 1), primary))
	button.add_theme_stylebox_override("pressed", _make_menu_button_style(Color(0.78, 0.68, 0.58, 1), primary))
	button.add_theme_stylebox_override("disabled", _make_menu_button_style(Color(0.38, 0.34, 0.32, 0.82), primary))
	button.add_theme_color_override("font_color", Color(1.0, 0.95, 0.78, 1))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.88, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.68, 0.62, 0.56, 1))
	button.add_theme_color_override("font_shadow_color", Color(0.18, 0.035, 0.018, 1))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)
	button.pressed.connect(callback)
	return button

func _start_new_game() -> void:
	if SaveManager.has_saved_run():
		_show_confirmation_window(
			"Start New Game?",
			"A saved run exists. Starting a new game will replace it.",
			"Start New Game",
			func():
				Game.reset_run(true)
				_enter_game()
		)
		return
	Game.reset_run(true)
	_enter_game()

func _continue_game() -> void:
	if Game.load_saved_run():
		_enter_game()

func _enter_game() -> void:
	if main_menu_layer != null and is_instance_valid(main_menu_layer):
		main_menu_layer.queue_free()
	main_menu_layer = null
	_set_game_ui_visible(true)
	_update_stats()
	_on_shop_available_changed(Game.shop_available)
	last_highest_affordable_wheel = Game.get_highest_affordable_wheel()
	wheel_node._update_wheel_arrow_buttons()

func _show_stats_window() -> void:
	var vbox := _open_modal("Stats", Vector2(620, 560))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)
	_add_stat_row(grid, "Games Started", str(SaveManager.get_games_started()))
	_add_stat_row(grid, "Games Won", str(SaveManager.get_games_won()))
	_add_stat_row(grid, "Total Spins", str(SaveManager.get_total_spins()))

	var colors := SaveManager.get_color_counts()
	for color_key in SaveManager.COLOR_KEYS:
		_add_stat_row(grid, _color_label(color_key) + " Spins", str(colors.get(color_key, 0)))

	var skills_title := Label.new()
	skills_title.text = "Total skills level bought"
	skills_title.add_theme_font_size_override("font_size", 20)
	skills_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.24, 1))
	vbox.add_child(skills_title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(540, 260)
	vbox.add_child(scroll)
	var skill_grid := GridContainer.new()
	skill_grid.columns = 3
	skill_grid.add_theme_constant_override("h_separation", 10)
	skill_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(skill_grid)
	var skill_totals := SaveManager.get_skill_level_totals()
	for skill in SkillManager.get_all_skills():
		var label := Label.new()
		label.text = skill["name"] + ": " + str(skill_totals.get(skill["id"], 0))
		label.custom_minimum_size = Vector2(160, 28)
		label.add_theme_color_override("font_color", Color(0.94, 0.9, 0.78, 1))
		skill_grid.add_child(label)

	vbox.add_child(_make_menu_button("Back", _close_modal))

func _show_run_history_window() -> void:
	var vbox := _open_modal("Run History", Vector2(980, 680))
	var history := SaveManager.get_run_history()
	if history.is_empty():
		var empty := Label.new()
		empty.text = "No completed runs yet"
		empty.custom_minimum_size = Vector2(820, 420)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 28)
		empty.add_theme_color_override("font_color", Color(0.94, 0.9, 0.78, 1))
		vbox.add_child(empty)
	else:
		var page_state := {"index": 0}
		var subtitle := Label.new()
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle.add_theme_color_override("font_color", Color(0.9, 0.84, 0.72, 1))
		subtitle.add_theme_font_size_override("font_size", 18)
		vbox.add_child(subtitle)

		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 14)
		content.custom_minimum_size = Vector2(860, 500)
		vbox.add_child(content)

		var list := VBoxContainer.new()
		list.name = "HistoryPageList"
		list.add_theme_constant_override("separation", 14)
		content.add_child(list)

		var nav := HBoxContainer.new()
		nav.alignment = BoxContainer.ALIGNMENT_CENTER
		nav.add_theme_constant_override("separation", 16)
		vbox.add_child(nav)

		var prev_button := _make_menu_button("Prev", func(): pass)
		prev_button.custom_minimum_size = Vector2(150, 54)
		var page_label := Label.new()
		page_label.custom_minimum_size = Vector2(180, 40)
		page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		page_label.add_theme_font_size_override("font_size", 20)
		page_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72, 1))
		var next_button := _make_menu_button("Next", func(): pass)
		next_button.custom_minimum_size = Vector2(150, 54)
		nav.add_child(prev_button)
		nav.add_child(page_label)
		nav.add_child(next_button)

		var render_page := func() -> void:
			for child in list.get_children():
				child.queue_free()
			var page_count := int(ceil(float(history.size()) / float(RUN_HISTORY_PAGE_SIZE)))
			page_state["index"] = clamp(int(page_state["index"]), 0, max(0, page_count - 1))
			var start := int(page_state["index"]) * RUN_HISTORY_PAGE_SIZE
			var end: int = min(start + RUN_HISTORY_PAGE_SIZE, history.size())
			subtitle.text = "Recent runs in a paged run-summary layout"
			page_label.text = "Page %d / %d" % [int(page_state["index"]) + 1, max(page_count, 1)]
			prev_button.disabled = int(page_state["index"]) <= 0
			next_button.disabled = int(page_state["index"]) >= page_count - 1
			for entry_index in range(start, end):
				list.add_child(_make_history_entry_card(history[entry_index], entry_index))

		prev_button.pressed.connect(func():
			page_state["index"] = int(page_state["index"]) - 1
			render_page.call()
		)
		next_button.pressed.connect(func():
			page_state["index"] = int(page_state["index"]) + 1
			render_page.call()
		)
		render_page.call()
	vbox.add_child(_make_menu_button("Back", _close_modal))

func _make_history_entry_card(entry: Dictionary, entry_index: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.025, 0.04, 0.94)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)

	var title := Label.new()
	title.text = "Run %02d  |  %s  |  %s coins" % [
		entry_index + 1,
		str(entry.get("timestamp", "Recent run")),
		UiFormat.compact_number(int(entry.get("final_coins", 0))),
	]
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.24, 1))
	box.add_child(title)

	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 10)
	box.add_child(metrics)
	metrics.add_child(_make_history_metric_card("Wheel", "Wheel " + str(int(entry.get("highest_wheel", 1))) + " reached"))
	metrics.add_child(_make_history_metric_card("Spins", str(int(entry.get("spins", 0)))))
	metrics.add_child(_make_history_metric_card("Time", _format_elapsed(int(entry.get("elapsed_seconds", 0)))))
	metrics.add_child(_make_history_metric_card("Skills", str(int(entry.get("skills_bought", 0)))))

	var breakdown := Label.new()
	breakdown.text = "Payouts: base " + UiFormat.compact_number(int(entry.get("base_payout", 0))) + ", skills " + UiFormat.compact_number(int(entry.get("skill_payout", 0))) + "   |   Spent: spins " + UiFormat.compact_number(int(entry.get("spin_costs", 0))) + ", shop " + UiFormat.compact_number(int(entry.get("shop_spent", 0)))
	breakdown.add_theme_color_override("font_color", Color(0.86, 0.8, 0.66, 1))
	breakdown.add_theme_font_size_override("font_size", 17)
	box.add_child(breakdown)

	var skills := _format_history_skills(entry.get("skills", []))
	var skill_label := Label.new()
	skill_label.text = skills if not skills.is_empty() else "No purchased skills recorded"
	skill_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_label.add_theme_color_override("font_color", Color(0.78, 0.92, 0.72, 1) if not skills.is_empty() else Color(0.86, 0.82, 0.72, 0.8))
	box.add_child(skill_label)
	return card

func _make_history_metric_card(label_text: String, value_text: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.045, 0.035, 0.88)
	style.border_color = Color(0.94, 0.68, 0.18, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	card.add_child(box)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.62, 0.92))
	box.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", Color(1.0, 0.94, 0.8, 1))
	box.add_child(value)
	return card

func _format_history_skills(skills_value) -> String:
	var parts: Array[String] = []
	for item in skills_value:
		if item is Dictionary:
			var name := str(item.get("name", item.get("id", "Skill")))
			var level := int(item.get("level", 1))
			parts.append(name if bool(item.get("unique", false)) else name + " Lv." + str(level))
	return ", ".join(parts)

func _add_stat_row(grid: GridContainer, label_text: String, value_text: String) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78, 1))
	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_color_override("font_color", Color(1.0, 0.82, 0.24, 1))
	grid.add_child(label)
	grid.add_child(value)

func _show_options_window(in_game: bool) -> void:
	_close_modal()
	if options_modal_scene == null:
		return
	modal_layer = options_modal_scene.instantiate()
	modal_layer.name = "Modal"
	add_child(modal_layer)
	_apply_large_ui_text(modal_layer)
	if modal_layer.has_method("configure"):
		modal_layer.call("configure", SaveManager.get_all_settings(), RESOLUTION_OPTIONS, in_game)
	if modal_layer.has_signal("setting_changed"):
		modal_layer.connect("setting_changed", func(key: String, value):
			SaveManager.set_setting(key, value)
			_apply_saved_settings()
		)
	if modal_layer.has_signal("save_requested"):
		modal_layer.connect("save_requested", _save_run_and_close_options)
	if modal_layer.has_signal("save_exit_requested"):
		modal_layer.connect("save_exit_requested", _confirm_save_exit_to_main_menu)
	if modal_layer.has_signal("close_requested"):
		modal_layer.connect("close_requested", _close_modal)
	if navigation_focus_enabled:
		_focus_default_control_for_active_surface()

func _save_run_and_close_options() -> void:
	Game.save_current_run()
	_close_modal()
	_show_toast("Run saved")

func _confirm_save_exit_to_main_menu() -> void:
	_show_confirmation_window(
		"Save & Exit?",
		"Save the current run and return to the main menu.",
		"Save & Exit",
		_save_exit_to_main_menu
	)

func _save_exit_to_main_menu() -> void:
	Game.save_current_run()
	_set_game_ui_visible(false)
	if _is_dev_tools_open():
		dev_tools_layer.queue_free()
		dev_tools_layer = null
	if debug_skills_layer != null and is_instance_valid(debug_skills_layer):
		debug_skills_layer.queue_free()
		debug_skills_layer = null
	_close_modal()
	_show_main_menu()

func _show_credits_window() -> void:
	var vbox := _open_modal("Credits", Vector2(860, 620))
	var intro := Label.new()
	intro.text = "Wheely Lucky ships CC0 assets. Source links are recorded in assets/sounds/SOURCES.md."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(760, 56)
	intro.add_theme_font_size_override("font_size", 18)
	intro.add_theme_color_override("font_color", Color(0.94, 0.9, 0.78, 1))
	vbox.add_child(intro)
	var text := RichTextLabel.new()
	text.bbcode_enabled = false
	text.fit_content = false
	text.scroll_active = true
	text.custom_minimum_size = Vector2(760, 430)
	text.text = "\n".join([
		"Background music",
		"Jazz n' brass loop by Emma_MA (CC0)",
		"",
		"Sound effects",
		"Level up, power up, Coin get (13 Sounds) by wobbleboxx (CC0)",
		"54 Casino sound effects by Kenney (CC0)",
		"Classic fanfare lick by fvcalderan (CC0)",
		"Button click sound effect by qubodup (CC0)",
		"Project-generated hover/press tones dedicated to the public domain",
		"",
		"Art",
		"End-game background generated for this project",
		"Game logo and UI assembly are project assets in this repo",
	])
	text.add_theme_font_size_override("normal_font_size", 20)
	text.add_theme_color_override("default_color", Color(0.94, 0.9, 0.78, 1))
	vbox.add_child(text)
	vbox.add_child(_make_menu_button("Back", _close_modal))

func _show_how_to_play_window() -> void:
	_close_modal()
	if tutorial_modal_scene == null:
		return
	modal_layer = tutorial_modal_scene.instantiate()
	modal_layer.name = "Modal"
	add_child(modal_layer)
	_apply_large_ui_text(modal_layer)
	if modal_layer.has_signal("close_requested"):
		modal_layer.connect("close_requested", _close_modal)
	if navigation_focus_enabled:
		_focus_default_control_for_active_surface()

func _open_modal(title_text: String, size: Vector2) -> VBoxContainer:
	_close_modal()
	modal_layer = CanvasLayer.new()
	modal_layer.name = "Modal"
	modal_layer.layer = 40
	add_child(modal_layer)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.52)
	modal_layer.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = size
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.07, 0.02, 0.045, 0.96)))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.24, 1))
	vbox.add_child(title)
	return vbox

func _show_confirmation_window(title_text: String, body_text: String, confirm_text: String, on_confirm: Callable) -> void:
	var vbox := _open_modal(title_text, Vector2(660, 360))
	var body := Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(560, 120)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 22)
	body.add_theme_color_override("font_color", Color(0.94, 0.9, 0.78, 1))
	vbox.add_child(body)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	vbox.add_child(buttons)
	buttons.add_child(_make_menu_button("Cancel", _close_modal))
	buttons.add_child(_make_menu_button(confirm_text, func():
		_close_modal()
		on_confirm.call()
	, true))

func _show_toast(message: String) -> void:
	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78, 1))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.custom_minimum_size = Vector2(220, 40)
	label.global_position = Vector2((get_viewport_rect().size.x - 220.0) * 0.5, 86.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "global_position:y", label.global_position.y - 22.0, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

func _close_modal() -> void:
	if modal_layer != null and is_instance_valid(modal_layer):
		modal_layer.queue_free()
	modal_layer = null
	if navigation_focus_enabled:
		call_deferred("_focus_default_control_for_active_surface")
	else:
		_clear_focus_if_navigation_disabled()

func _make_panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(1.0, 0.74, 0.18, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 28
	style.content_margin_top = 24
	style.content_margin_right = 28
	style.content_margin_bottom = 24
	return style

func _make_menu_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.018, 0.04, 0.94)
	style.border_color = Color(1.0, 0.75, 0.22, 0.95)
	style.set_border_width_all(4)
	style.set_corner_radius_all(8)
	style.content_margin_left = 34
	style.content_margin_top = 28
	style.content_margin_right = 34
	style.content_margin_bottom = 28
	return style

func _make_menu_button_style(modulate: Color, primary: bool = false) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = menu_button_texture
	style.modulate_color = modulate
	style.texture_margin_left = 36
	style.texture_margin_top = 20
	style.texture_margin_right = 36
	style.texture_margin_bottom = 20
	style.content_margin_left = 24
	style.content_margin_top = 9 if primary else 7
	style.content_margin_right = 24
	style.content_margin_bottom = 9 if primary else 7
	return style

func _make_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(1.0, 0.8, 0.22, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_top = 8
	style.content_margin_right = 16
	style.content_margin_bottom = 8
	return style

func _make_help_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(1.0, 0.82, 0.24, 0.96)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.content_margin_left = 6
	style.content_margin_top = 4
	style.content_margin_right = 6
	style.content_margin_bottom = 4
	return style

func _color_label(color_key: String) -> String:
	match color_key:
		"green":
			return "Plus"
		"red":
			return "Minus"
		"gold":
			return "Multiply"
		"grey":
			return "None"
		"jackpot":
			return "Jackpot"
		_:
			return color_key.capitalize()

func _toggle_dev_tools() -> void:
	if _is_dev_tools_open():
		dev_tools_layer.queue_free()
		dev_tools_layer = null
		return
	dev_tools_layer = CanvasLayer.new()
	dev_tools_layer.name = "DevTools"
	dev_tools_layer.layer = 45
	add_child(dev_tools_layer)
	_refresh_dev_tools()

func _is_dev_tools_open() -> bool:
	return dev_tools_layer != null and is_instance_valid(dev_tools_layer)

func _refresh_dev_tools() -> void:
	if not _is_dev_tools_open():
		return
	for child in dev_tools_layer.get_children():
		child.queue_free()

	var panel := PanelContainer.new()
	panel.offset_left = 18
	panel.offset_top = 18
	panel.custom_minimum_size = Vector2(430, 350)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.02, 0.035, 0.96)))
	dev_tools_layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Dev Tools (~)"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.24, 1))
	vbox.add_child(title)

	var lines := [
		"1. Instant spin",
		"2. Add 999,999 coins",
		"3. Toggle skill picker",
		"4. Open shop",
		"5. Show end screen",
		"6. Change spin speed: " + str(SPIN_SPEED_OPTIONS[dev_spin_speed_index]) + "s",
		"7. Change coins gained: x" + str(COIN_GAIN_OPTIONS[dev_coin_gain_index]),
		"8. Open skill-list shop: " + _get_debug_shop_page_label(),
		"9. Next skill-list page",
	]
	for line in lines:
		var label := Label.new()
		label.text = line
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", Color(0.94, 0.9, 0.8, 1))
		vbox.add_child(label)

func _handle_dev_tool_key(keycode: int) -> bool:
	match keycode:
		KEY_1:
			if main_menu_layer == null:
				wheel_node.instant_spin()
			return true
		KEY_2:
			if main_menu_layer == null:
				Game.coins += 999999
				Game.save_current_run()
				_update_stats()
			return true
		KEY_3:
			if main_menu_layer == null:
				_toggle_debug_skills()
			return true
		KEY_4:
			_open_debug_shop()
			return true
		KEY_5:
			_show_debug_end_screen()
			return true
		KEY_6:
			_cycle_dev_spin_speed()
			return true
		KEY_7:
			_cycle_dev_coin_gain()
			return true
		KEY_8:
			_open_debug_shop_list_page()
			return true
		KEY_9:
			_cycle_debug_shop_list_page()
			return true
	return false

func _cycle_dev_spin_speed() -> void:
	dev_spin_speed_index = (dev_spin_speed_index + 1) % SPIN_SPEED_OPTIONS.size()
	wheel_node.base_spin_duration = SPIN_SPEED_OPTIONS[dev_spin_speed_index]
	_refresh_dev_tools()

func _cycle_dev_coin_gain() -> void:
	dev_coin_gain_index = (dev_coin_gain_index + 1) % COIN_GAIN_OPTIONS.size()
	Game.dev_coin_gain_multiplier = COIN_GAIN_OPTIONS[dev_coin_gain_index]
	_refresh_dev_tools()

func _open_debug_shop() -> void:
	if wheel_node.is_spinning or _is_shop_open() or main_menu_layer != null:
		return
	if Game.pending_shop_skills.is_empty():
		Game.pending_shop_skills = Game._roll_shop_skills()
	_on_shop_requested()

func _open_debug_shop_list_page() -> void:
	if wheel_node.is_spinning or _is_shop_open() or main_menu_layer != null:
		return
	Game.coins = max(Game.coins, 999999)
	Game.pending_shop_skills = _get_debug_shop_page_skills()
	_on_shop_requested()

func _cycle_debug_shop_list_page() -> void:
	var page_count := _get_debug_shop_page_count()
	dev_shop_list_page = (dev_shop_list_page + 1) % page_count
	_refresh_dev_tools()

func _get_debug_shop_page_count() -> int:
	return maxi(1, int(ceil(float(SkillManager.get_all_skills().size()) / float(DEBUG_SHOP_PAGE_SIZE))))

func _get_debug_shop_page_skills() -> Array[Dictionary]:
	var skills := SkillManager.get_all_skills()
	var page_count := _get_debug_shop_page_count()
	dev_shop_list_page = clampi(dev_shop_list_page, 0, page_count - 1)
	var start_index := dev_shop_list_page * DEBUG_SHOP_PAGE_SIZE
	var result: Array[Dictionary] = []
	for index in range(start_index, mini(start_index + DEBUG_SHOP_PAGE_SIZE, skills.size())):
		result.append(skills[index])
	return result

func _get_debug_shop_page_label() -> String:
	var skills := SkillManager.get_all_skills()
	if skills.is_empty():
		return "empty"
	var page_count := _get_debug_shop_page_count()
	dev_shop_list_page = clampi(dev_shop_list_page, 0, page_count - 1)
	var start_index := dev_shop_list_page * DEBUG_SHOP_PAGE_SIZE
	var end_index := mini(start_index + DEBUG_SHOP_PAGE_SIZE, skills.size()) - 1
	return str(start_index + 1) + "-" + str(end_index + 1) + "/" + str(skills.size())

func _toggle_debug_skills() -> void:
	if debug_skills_layer != null and is_instance_valid(debug_skills_layer):
		debug_skills_layer.queue_free()
		debug_skills_layer = null
		return

	debug_skills_layer = CanvasLayer.new()
	debug_skills_layer.name = "DebugSkills"
	add_child(debug_skills_layer)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 560)
	panel.offset_left = 24
	panel.offset_top = 24
	debug_skills_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "Debug Skills - click to acquire"
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(400, 510)
	vbox.add_child(scroll)

	var list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	for skill in SkillManager.UPGRADEABLE_SKILLS:
		list.add_child(_make_debug_skill_button(skill, false))
	for skill in SkillManager.UNIQUE_SKILLS:
		list.add_child(_make_debug_skill_button(skill, true))

func _make_debug_skill_button(skill: Dictionary, is_unique: bool) -> Button:
	var button = Button.new()
	button.text = _get_debug_skill_button_text(skill, is_unique)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(func():
		if is_unique:
			if skill["id"] in Game.unique_skills:
				Game.unique_skills.erase(skill["id"])
				Game.bought_skill_order.erase(skill["id"])
			else:
				Game.unique_skills.append(skill["id"])
				if skill["id"] not in Game.bought_skill_order:
					Game.bought_skill_order.append(skill["id"])
		else:
			if skill["id"] not in Game.bought_skill_order:
				Game.bought_skill_order.append(skill["id"])
			Game.skill_levels[skill["id"]] = Game.skill_levels.get(skill["id"], 0) + 1
		Game.skills_changed.emit()
		button.text = _get_debug_skill_button_text(skill, is_unique)
	)
	return button

func _get_debug_skill_button_text(skill: Dictionary, is_unique: bool) -> String:
	if is_unique:
		var owned = "OWNED" if skill["id"] in Game.unique_skills else "not owned"
		return skill["name"] + " [unique, " + owned + "]"
	return skill["name"] + " [Lv." + str(Game.skill_levels.get(skill["id"], 0)) + "]"

func _is_mouse_over_enabled_button(mouse_position: Vector2) -> bool:
	# Check explicit click buttons first, then any dynamically-created buttons under this scene.
	for button in get_tree().get_nodes_in_group("click_buttons"):
		if button is Button and button.visible:
			if button.get_global_rect().has_point(mouse_position):
				return true
	for button in _get_all_buttons(self):
		if button.visible and button.get_global_rect().has_point(mouse_position):
			return true
	return false

func _get_all_buttons(node: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	for child in node.get_children():
		if child is Button:
			buttons.append(child)
		buttons.append_array(_get_all_buttons(child))
	return buttons

func _is_shop_open() -> bool:
	for child in get_children():
		if child.name == "Shop":
			return true
	return false

func _is_modal_open() -> bool:
	return _is_shop_open() or _is_end_screen_open() or main_menu_layer != null or modal_layer != null

func _is_click_on_stats_panel(pos: Vector2) -> bool:
	if $StatsPanel.visible and $StatsPanel.is_inside_tree():
		return $StatsPanel.get_global_rect().has_point(pos)
	return false

func _is_end_screen_open() -> bool:
	for child in get_children():
		if child.name == "EndScreen":
			return true
	return false

func _show_debug_end_screen() -> void:
	if _is_end_screen_open() or main_menu_layer != null:
		return
	_on_game_ended(Game.coins, Game.get_elapsed_seconds())

func _on_spin_finished(outcome):
	# Wheel animation chooses the visual outcome; Game applies it so result and pointer stay in sync.
	var result = Game.spin_wheel(outcome)
	_update_stats()
	_on_shop_available_changed(Game.shop_available)
	
	if result.get("success", false):
		await _play_result_polish(result)
		if not is_instance_valid(self):
			return
		if wheel_node != null and wheel_node.has_method("set_spin_locked"):
			wheel_node.call("set_spin_locked", true)
		await _play_resolution_events(result.get("resolution_events", []))
		if not is_instance_valid(self):
			return
		Game.flush_coin_changed()
		if not Game.is_wheel_unlocked(Game.selected_wheel):
			Game.select_wheel(Game.get_highest_affordable_wheel())
		if wheel_node != null and wheel_node.has_method("set_spin_locked"):
			wheel_node.call("set_spin_locked", false)
		var highest := Game.get_highest_affordable_wheel()
		if highest > last_highest_affordable_wheel:
			_pulse_wheel_indicator(highest)
		last_highest_affordable_wheel = highest
		wheel_node.set_all_buttons_visible(true)
		await get_tree().process_frame
		if not is_instance_valid(self):
			return
		wheel_node._update_wheel_arrow_buttons()
		if bool(result.get("game_over", false)):
			await get_tree().create_timer(0.6 if not reduced_motion_enabled else 0.18).timeout
			if not is_instance_valid(self):
				return
			_on_game_ended(Game.coins, Game.get_elapsed_seconds())
	else:
		wheel_node.set_all_buttons_visible(true)

func _play_result_polish(result: Dictionary) -> void:
	var outcome_label := str(result.get("outcome_label", ""))
	var spun_wheel := int(result.get("spun_wheel", 0))
	var color: Color = result.get("outcome_color", Color.WHITE)
	var near_jackpot := spun_wheel == Game.MAX_WHEELS and wheel_node.has_method("is_pointer_near_jackpot") and bool(wheel_node.call("is_pointer_near_jackpot", 8))
	if outcome_label == "JACKPOT":
		_spawn_jackpot_celebration(_get_wheel_effect_position())
		if near_jackpot:
			await _play_w10_loss_focus(true)
	elif outcome_label.begins_with("x"):
		_spawn_multiplier_celebration(_get_wheel_effect_position(), color.lightened(0.25))
	if spun_wheel == Game.MAX_WHEELS and outcome_label != "JACKPOT" and near_jackpot:
		if not w10_preview_focus_played:
			await _play_w10_loss_focus(false)

func _get_wheel_effect_position() -> Vector2:
	if pointer_indicator != null:
		return pointer_indicator.global_position + pointer_indicator.size * 0.5
	return wheel_node.global_position + wheel_node.size * 0.5

func _spawn_particle_burst(origin: Vector2, color: Color, count: int) -> void:
	if reduced_motion_enabled:
		return
	var alpha := 0.42 if muted_flashes_enabled else 0.95
	for index in range(count):
		var particle := ColorRect.new()
		particle.color = Color(color.r, color.g, color.b, alpha)
		particle.size = Vector2(effect_rng.randf_range(5.0, 10.0), effect_rng.randf_range(5.0, 10.0))
		particle.global_position = origin - particle.size * 0.5
		particle.rotation = effect_rng.randf_range(0.0, TAU)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(particle)
		var angle := effect_rng.randf_range(0.0, TAU)
		var distance := effect_rng.randf_range(42.0, 128.0)
		var target := origin + Vector2(cos(angle), sin(angle)) * distance
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "global_position", target, effect_rng.randf_range(0.42, 0.68)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "rotation", particle.rotation + effect_rng.randf_range(-3.0, 3.0), 0.6)
		tween.tween_property(particle, "modulate:a", 0.0, 0.6)
		tween.chain().tween_callback(particle.queue_free)

func _spawn_flash_ring(origin: Vector2, color: Color, radius: float, thickness: float, lifetime: float) -> void:
	if reduced_motion_enabled:
		return
	var ring := PanelContainer.new()
	ring.size = Vector2(radius, radius)
	ring.pivot_offset = ring.size * 0.5
	ring.global_position = origin - ring.size * 0.5
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ring)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(color.r, color.g, color.b, 0.95)
	style.set_border_width_all(int(max(2.0, thickness)))
	style.set_corner_radius_all(int(radius * 0.5))
	ring.add_theme_stylebox_override("panel", style)
	ring.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(1.32, 1.32), lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, lifetime)
	tween.tween_callback(ring.queue_free)

func _spawn_jackpot_celebration(origin: Vector2) -> void:
	_spawn_flash_ring(origin, Color(1.0, 0.84, 0.22, 1), 66.0, 5.0, 0.78)
	_spawn_flash_ring(origin, Color(1.0, 0.45, 0.12, 1), 102.0, 3.0, 0.92)
	_spawn_particle_burst(origin, Color(1.0, 0.82, 0.24, 1), 44)
	_spawn_particle_burst(origin, Color(1.0, 0.56, 0.16, 1), 26)
	_spawn_particle_burst(origin, Color(1.0, 0.96, 0.72, 1), 18)

func _spawn_multiplier_celebration(origin: Vector2, color: Color) -> void:
	_spawn_flash_ring(origin, color, 54.0, 3.0, 0.5)
	_spawn_particle_burst(origin, color, 24)

func _play_w10_loss_focus(is_jackpot: bool = false) -> void:
	if reduced_motion_enabled:
		return
	var original_position := wheel_node.position
	var original_scale := wheel_node.scale
	var pointer_global := _get_wheel_effect_position()
	var original_canvas_transform := get_viewport().canvas_transform
	var tween := create_tween()
	var focus_zoom := 1.1 if is_jackpot else 1.075
	var intro_time := 0.22 if is_jackpot else 0.16
	var settle_time := 0.34 if is_jackpot else 0.26
	var shake_distance := 12.0 if is_jackpot else 8.0
	tween.tween_method(func(value: float): _set_viewport_focus_zoom_custom(value, pointer_global, focus_zoom), 0.0, 1.0, intro_time)
	tween.parallel().tween_property(wheel_node, "scale", original_scale * (1.05 if is_jackpot else 1.03), intro_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in range(8 if is_jackpot else 6):
		var offset := Vector2(shake_distance if i % 2 == 0 else -shake_distance, -shake_distance * 0.45 if i % 3 == 0 else shake_distance * 0.35)
		tween.tween_property(wheel_node, "position", original_position + offset, 0.045 if is_jackpot else 0.038)
	tween.tween_method(func(value: float): _set_viewport_focus_zoom_custom(1.0 - value, pointer_global, focus_zoom), 0.0, 1.0, settle_time)
	tween.tween_property(wheel_node, "position", original_position, settle_time)
	tween.parallel().tween_property(wheel_node, "scale", original_scale, settle_time)
	tween.tween_callback(func(): get_viewport().canvas_transform = original_canvas_transform)
	await tween.finished

func _set_viewport_focus_zoom(amount: float, focus: Vector2) -> void:
	_set_viewport_focus_zoom_custom(amount, focus, 1.045)

func _set_viewport_focus_zoom_custom(amount: float, focus: Vector2, max_zoom: float) -> void:
	var zoom: float = lerp(1.0, max_zoom, clamp(amount, 0.0, 1.0))
	var origin: Vector2 = focus - focus * zoom
	get_viewport().canvas_transform = Transform2D(Vector2(zoom, 0.0), Vector2(0.0, zoom), origin)

func _get_next_wheel_arc_focus(target_wheel: int) -> Vector2:
	var scale_factor: float = wheel_node.size.y / 560.0
	var center := wheel_node.global_position + wheel_node.size * 0.5
	var radius := 278.0 * scale_factor
	var ratio: float = clamp(float(target_wheel - 1) / float(Game.MAX_WHEELS - 1), 0.0, 1.0)
	var angle: float = lerp(deg_to_rad(210.0), deg_to_rad(330.0), ratio)
	return center + Vector2(cos(angle), sin(angle)) * radius

func _pulse_wheel_indicator(target_wheel: int = 0) -> void:
	var focus_point := _get_next_wheel_arc_focus(target_wheel if target_wheel > 0 else min(Game.MAX_WHEELS, last_highest_affordable_wheel + 1))
	if pointer_indicator == null:
		return
	if not reduced_motion_enabled:
		var ring_tint := Color(1.0, 0.92, 0.36, 1)
		_spawn_flash_ring(focus_point, ring_tint, 56.0, 4.0, 0.62)
		_spawn_flash_ring(focus_point, Color(1.0, 0.62, 0.22, 1), 84.0, 2.0, 0.84)
	_spawn_indicator_sparkles(focus_point)

func _spawn_indicator_sparkles(origin: Vector2) -> void:
	if reduced_motion_enabled:
		return
	_spawn_particle_burst(origin, Color(1.0, 0.92, 0.36, 1), 16)

func _on_wheel_spin_started(cost: int = 0):
	w10_preview_focus_played = false
	_on_shop_available_changed(Game.shop_available)
	if cost > 0:
		_show_coin_delta(-cost, Color(1.0, 0.62, 0.24, 1), "", 0, false)

func _on_near_jackpot_tension(is_jackpot_target: bool) -> void:
	if w10_preview_focus_played:
		return
	w10_preview_focus_played = true
	_play_w10_loss_focus(is_jackpot_target)

func _show_coin_delta(delta: int, color: Color, outcome_label: String = "", spun_wheel: int = 0, play_sound: bool = true):
	# Lightweight floating label for spin rewards, spin costs, and shop purchases.
	if delta == 0:
		return

	if play_sound:
		if outcome_label.begins_with("x"):
			multiplier_sound.play()
		elif delta > 0:
			result_positive_sound.play()
		elif delta < 0 and spun_wheel == Game.MAX_WHEELS:
			w10_loss_sound.play()
		elif delta < 0:
			result_negative_sound.play()

	var label = Label.new()
	label.text = UiFormat.signed_compact(delta)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.global_position = wheel_node.global_position + coins_display.position + Vector2(40, -32)
	label.size = Vector2(120, 38)
	add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "global_position:y", label.global_position.y - 42.0, 0.65)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.65)
	tween.tween_callback(label.queue_free)

func _play_resolution_events(events: Array) -> void:
	for event in events:
		if not event is Dictionary:
			continue
		var delta := int(event.get("delta", 0))
		if delta == 0:
			continue
		if not is_instance_valid(self):
			return
		if str(event.get("type", "")) == "base":
			_show_coin_delta(
				delta,
				event.get("outcome_color", Color.WHITE),
				str(event.get("outcome_label", "")),
				int(event.get("spun_wheel", 0))
			)
			_set_displayed_coin_total(int(event.get("display_total", Game.coins)))
			await get_tree().create_timer(0.62).timeout
			if not is_instance_valid(self):
				return
			continue
		await _show_skill_coin_delta(
			str(event.get("skill_id", "")),
			delta,
			str(event.get("skill_name", "")),
			int(event.get("display_total", Game.coins))
		)
		if not is_instance_valid(self):
			return
		await get_tree().create_timer(0.24).timeout

func _show_skill_coin_delta(skill_id: String, delta: int, _skill_name: String, display_total: int) -> void:
	if not is_instance_valid(self):
		return
	var frame = skill_icon_frames.get(skill_id)
	if frame == null or not is_instance_valid(frame):
		_show_coin_delta(delta, Color(1.0, 0.84, 0.24, 1), "", 0)
		_set_displayed_coin_total(display_total)
		await get_tree().create_timer(0.52).timeout
		return

	result_positive_sound.play()
	$StatsPanel.visible = true
	await get_tree().process_frame
	var frame_node = frame as Control
	var icon: Vector2 = (frame_node.get_child(0) as TextureRect).global_position if frame_node.get_child_count() > 0 else frame_node.global_position
	var start_position: Vector2 = icon + Vector2(-23, 23) + Vector2(0, -44)

	var label = Label.new()
	label.text = UiFormat.signed_compact(delta)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.24, 1))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", 28)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.global_position = start_position
	label.size = Vector2(92, 30)
	add_child(label)

	var glow = ColorRect.new()
	glow.color = Color(1.0, 0.76, 0.12, 0.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.position = Vector2(-4, -4)
	glow.size = (frame as Control).custom_minimum_size + Vector2(8, 8)
	(frame as Control).add_child(glow)
	(frame as Control).move_child(glow, 0)

	var original_scale := (frame as Control).scale
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(frame, "scale", original_scale * 1.16, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(glow, "color:a", 0.42, 0.10)
	tween.tween_property(label, "global_position:y", start_position.y - 34.0, 0.48)
	tween.tween_property(label, "modulate:a", 0.0, 0.48).set_delay(0.12)
	tween.parallel().tween_method(func(value: float): _set_displayed_coin_total(int(round(value))), float(max(display_total - delta, 0)), float(display_total), 0.40)
	tween.chain().tween_property(frame, "scale", original_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(glow, "color:a", 0.0, 0.16)
	tween.tween_callback(func():
		if is_instance_valid(label):
			label.queue_free()
		if is_instance_valid(glow):
			glow.queue_free()
	)
	await tween.finished
	if not is_instance_valid(self):
		return

func _set_displayed_coin_total(total: int) -> void:
	if coins_display != null:
		coins_display.text = UiFormat.compact_number(total)

func _on_shop_requested():
	# Shop is instanced only when offered so it does not sit in the tree during normal spins.
	shop_open_sound.play()

	if shop_scene == null:
		return
	var shop = shop_scene.instantiate()
	add_child(shop)
	if navigation_focus_enabled and shop.has_method("focus_default_control"):
		shop.call_deferred("focus_default_control")

	shop.purchase_completed.connect(func(cost):
		_show_coin_delta(-cost, Color(1.0, 0.62, 0.24, 1), "", 0, false)
	)
	shop.tree_exited.connect(func():
		_update_stats()
		Game.save_current_run()
	)

func _on_shop_button_requested() -> void:
	if wheel_node.is_spinning or _is_shop_open():
		return
	if not Game.consume_shop_available():
		return
	wheel_node.set_shop_available(false)
	_on_shop_requested()

func _on_shop_available_changed(is_available: bool):
	wheel_node.set_shop_available(is_available and not _is_shop_open())

func _on_game_ended(_final_coins: int, _elapsed_seconds: int):
	if _is_end_screen_open():
		return
	if end_screen_scene == null:
		return
	var end_screen = end_screen_scene.instantiate()
	add_child(end_screen)
	_apply_large_ui_text(end_screen)
	if navigation_focus_enabled and end_screen.has_method("focus_default_control"):
		end_screen.call_deferred("focus_default_control")
	if in_game_options_button != null:
		in_game_options_button.visible = false
	if in_game_help_button != null:
		in_game_help_button.visible = false
	end_screen.tree_exited.connect(func():
		_update_stats()
		if main_menu_layer == null and wheel_node.visible and in_game_options_button != null:
			in_game_options_button.visible = true
		if main_menu_layer == null and wheel_node.visible and in_game_help_button != null:
			in_game_help_button.visible = true
	)

func _update_stats():
	_update_upgrades_summary()

func _on_skills_changed():
	_update_stats()

func _update_upgrades_summary():
	# Rebuild is cheap here because upgrades only change after shop purchases.
	skill_icon_frames.clear()
	for child in upgrades_vbox.get_children():
		upgrades_vbox.remove_child(child)
		child.free()

	var owned = _get_owned_skill_icons()
	if owned.is_empty():
		var empty_label = Label.new()
		empty_label.custom_minimum_size = Vector2(0, 54)
		empty_label.text = " "
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		empty_label.add_theme_font_size_override("font_size", 18)
		upgrades_vbox.add_child(empty_label)
		return

	var grid = GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	upgrades_vbox.add_child(grid)

	for item in owned:
		grid.add_child(_make_upgrade_icon(item["id"], item["level"], item["name"]))

func _set_navigation_focus_enabled(is_enabled: bool) -> void:
	if navigation_focus_enabled == is_enabled:
		if navigation_focus_enabled and get_viewport().gui_get_focus_owner() == null:
			_focus_default_control_for_active_surface()
		return
	navigation_focus_enabled = is_enabled
	if navigation_focus_enabled:
		if get_viewport().gui_get_focus_owner() == null:
			_focus_default_control_for_active_surface()
	else:
		_clear_focus_if_navigation_disabled()

func _clear_focus_if_navigation_disabled() -> void:
	if navigation_focus_enabled:
		return
	var owner := get_viewport().gui_get_focus_owner()
	if owner != null and owner is Control:
		(owner as Control).release_focus()

func _focus_default_control_for_active_surface() -> void:
	if modal_layer != null and is_instance_valid(modal_layer) and modal_layer.has_method("focus_default_control"):
		modal_layer.call("focus_default_control")
		return
	for child in get_children():
		if child.name == "Shop" and child.has_method("focus_default_control"):
			child.call("focus_default_control")
			return
	for child in get_children():
		if child.name == "EndScreen" and child.has_method("focus_default_control"):
			child.call("focus_default_control")
			return
	if main_menu_layer != null and is_instance_valid(main_menu_layer) and main_menu_layer.has_method("focus_default_control"):
		main_menu_layer.call("focus_default_control")

func _get_owned_skill_icons() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for skill_id in Game.bought_skill_order:
		var skill = SkillManager.get_skill_by_id(skill_id)
		if skill.is_empty():
			continue
		var level = 1 if skill_id in Game.unique_skills else Game.skill_levels.get(skill_id, 0)
		if level > 0:
			items.append({"id": skill_id, "name": skill.get("name", skill_id), "level": level})
	return items

func _make_upgrade_icon(skill_id: String, level: int, _skill_name: String) -> Control:
	var frame = Control.new()
	frame.name = "SkillIcon_" + skill_id
	frame.set_meta("skill_id", skill_id)
	frame.custom_minimum_size = Vector2(58, 58)
	frame.pivot_offset = frame.custom_minimum_size / 2.0
	frame.gui_input.connect(Callable(self, "_on_skill_icon_clicked").bind(skill_id, level))
	skill_icon_frames[skill_id] = frame

	var icon = TextureRect.new()
	icon.texture = _get_skill_icon(skill_id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(46, 46)
	icon.size = Vector2(46, 46)
	icon.position = Vector2(6, 6)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(icon)

	var level_badge = Label.new()
	level_badge.custom_minimum_size = Vector2(22, 22)
	level_badge.size = Vector2(22, 22)
	level_badge.position = frame.custom_minimum_size - level_badge.size
	level_badge.text = str(level)
	level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_badge.add_theme_stylebox_override("normal", _make_level_badge_style())
	level_badge.add_theme_color_override("font_color", Color(0.18, 0.06, 0.02, 1))
	level_badge.add_theme_font_size_override("font_size", 13)
	level_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(level_badge)

	return frame

func _get_skill_icon(skill_id: String) -> Texture2D:
	return UiFormat.skill_icon(skill_id, skill_icon_atlas)

func _make_level_badge_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.82, 0.24, 1)
	style.border_color = Color(0.38, 0.09, 0.02, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(11)
	return style

func _on_skill_icon_clicked(event: InputEvent, skill_id: String, level: int) -> void:
	if not (event is InputEventMouseButton and (event as InputEventMouseButton).pressed):
		return
	get_viewport().set_input_as_handled()
	var skill = SkillManager.get_skill_by_id(skill_id)
	if skill.is_empty():
		return
	var max_level: int = skill.get("max", 0)
	var is_unique := skill_id in Game.unique_skills
	var is_maxed := (max_level > 0 and level >= max_level)

	var current_effect := SkillManager.get_effect_text(skill_id, level) if not is_maxed else "Max Level"
	var next_effect := SkillManager.get_effect_text(skill_id, level + 1) if not is_maxed else ""
	var cost = SkillManager.get_purchase_cost(skill, level)

	_skill_info_popup(skill_id, skill.get("name", skill_id), skill.get("desc", ""), level, current_effect, next_effect, cost, is_maxed, is_unique)

func _close_skill_popup() -> void:
	for child in $StatsPanel.get_children():
		if child.name == "SkillInfoPopup":
			child.queue_free()
			break
	for overlay in get_children():
		if overlay.name == "SkillPopupOverlay":
			overlay.queue_free()
			break

func _on_popup_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_close_skill_popup()
		get_viewport().set_input_as_handled()

func _is_popup_open() -> bool:
	for child in $StatsPanel.get_children():
		if child.name == "SkillInfoPopup":
			return true
	return false

func _skill_info_popup(skill_id: String, name: String, desc: String, level: int, current_effect: String, next_effect: String, cost: int, is_maxed: bool, is_unique: bool) -> void:
	_close_skill_popup()

	var frame = skill_icon_frames.get(skill_id)
	if frame == null or not is_instance_valid(frame):
		return
	$StatsPanel.visible = true
	await get_tree().process_frame

	# Overlay to capture clicks outside popup
	var overlay = Control.new()
	overlay.name = "SkillPopupOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_popup_overlay_input)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var popup = PanelContainer.new()
	popup.name = "SkillInfoPopup"
	popup.mouse_filter = Control.MOUSE_FILTER_PASS
	popup.visible = false

	# Background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.14, 0.95)
	bg_style.set_corner_radius_all(8)
	bg_style.set_border_width_all(2)
	bg_style.border_color = Color(0.35, 0.35, 0.45, 1)
	bg_style.set_content_margin_all(16)
	popup.add_theme_stylebox_override("panel", bg_style)

	# Content
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.set_anchors_preset(Control.PRESET_VCENTER_WIDE)
	popup.add_child(vbox)

	var title = Label.new()
	title.text = name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.24, 1))
	title.size_flags_horizontal = Control.SIZE_FILL
	vbox.add_child(title)

	var spacer1 = Label.new()
	spacer1.text = ""
	spacer1.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer1)

	var desc_label = Label.new()
	desc_label.text = desc
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 1))
	desc_label.size_flags_horizontal = Control.SIZE_FILL
	vbox.add_child(desc_label)

	var spacer2 = Label.new()
	spacer2.text = ""
	spacer2.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer2)

	if not is_unique:
		var current_label = Label.new()
		current_label.text = "Current (Lvl " + str(level) + "):\n" + current_effect
		current_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		current_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		current_label.add_theme_font_size_override("font_size", 15)
		current_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.65, 1))
		current_label.size_flags_horizontal = Control.SIZE_FILL
		vbox.add_child(current_label)

	if not is_maxed and not is_unique:
		var next_label = Label.new()
		next_label.text = "Next (Lvl " + str(level + 1) + "):\n" + next_effect + "\n◆" + str(cost)
		next_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		next_label.add_theme_font_size_override("font_size", 15)
		next_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.3, 1))
		next_label.size_flags_horizontal = Control.SIZE_FILL
		vbox.add_child(next_label)

	$StatsPanel.add_child(popup)
	popup.z_index = 10
	popup.layout_mode = 1
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.set_offsets_preset(Control.PRESET_FULL_RECT)
	popup.visible = true
