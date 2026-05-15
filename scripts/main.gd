# scripts/main.gd
extends Control

const SoundFactory = preload("res://scripts/sound_factory.gd")
const SkillManager = preload("res://scripts/skill_manager.gd")
const WheelConfig = preload("res://scripts/wheel_config.gd")
const UPGRADE_BADGE_TEXTURE = preload("res://assets/ui/upgrade-badge.png")

@onready var stats_spins_label: Label = $StatsPanel/StatsVBox/StatsSpins
@onready var stats_cycles_label: Label = $StatsPanel/StatsVBox/StatsCycles
@onready var stats_skills_label: Label = $StatsPanel/StatsVBox/StatsSkills
@onready var stats_best_label: Label = $StatsPanel/StatsVBox/StatsBest
@onready var upgrades_vbox: VBoxContainer = $StatsPanel/StatsVBox/UpgradesVBox
@onready var probability_rows: VBoxContainer = $ProbabilityPanel/ProbabilityVBox/ProbabilityRows
@onready var top_coins_display: Label = $TopBar/TopCoinsDisplay
@onready var wheel_node: Control = $Wheel
@onready var spin_button: Button = $Wheel/SpinButton
@onready var shop_button_art: TextureRect = $Wheel/ShopButtonArt
@onready var shop_button: Button = $Wheel/ShopButton
@onready var wheel_selector_container: HBoxContainer = $WheelSelector/WheelSelectorHBox
@onready var result_positive_sound: AudioStreamPlayer = $ResultPositiveSound
@onready var result_negative_sound: AudioStreamPlayer = $ResultNegativeSound
@onready var shop_open_sound: AudioStreamPlayer = $ShopOpenSound

const MAX_WHEELS = 10
var wheel_buttons: Array[Button] = []

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	result_positive_sound.stream = SoundFactory.make_tone(880.0, 0.22)
	result_negative_sound.stream = SoundFactory.make_tone(220.0, 0.28)
	shop_open_sound.stream = SoundFactory.make_tone(660.0, 0.16)

	# Create 10 wheel selector buttons
	for i in range(MAX_WHEELS):
		var btn = Button.new()
		btn.text = str(i + 1)
		btn.custom_minimum_size = Vector2(72, 72)
		btn.add_theme_font_size_override("font_size", 22)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.add_to_group("click_buttons")
		btn.pressed.connect(_on_wheel_select.bind(i + 1))
		wheel_selector_container.add_child(btn)
		wheel_buttons.append(btn)

	_make_non_buttons_click_through(self)

	wheel_node.spin_finished.connect(_on_spin_finished)
	wheel_node.spin_started.connect(_on_wheel_spin_started)
	Game.shop_available_changed.connect(_on_shop_available_changed)
	Game.game_ended.connect(_on_game_ended)
	Game.coins_changed.connect(_update_top_coins)
	Game.selected_wheel_changed.connect(_update_wheel_selector)
	Game.selected_wheel_changed.connect(func(_wheel_num): _update_stats())
	Game.selected_wheel_changed.connect(func(_wheel_num): _update_probability_chart())
	Game.skills_changed.connect(_on_skills_changed)

	_update_top_coins(Game.coins)
	_update_stats()
	_update_probability_chart()
	_update_wheel_selector(Game.selected_wheel)
	_on_shop_available_changed(Game.shop_available)
	shop_button.add_to_group("click_buttons")
	shop_button.pressed.connect(_on_shop_button_pressed)

func _make_non_buttons_click_through(node: Node):
	for child in node.get_children():
		if child is Control and not child is Button:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_make_non_buttons_click_through(child)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			wheel_node.instant_spin()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_W:
			Game.coins += 100
			_update_stats()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not wheel_node.is_spinning and not _is_shop_open() and not _is_mouse_over_enabled_button(event.position):
			wheel_node.start_spin()
			get_viewport().set_input_as_handled()

func _is_mouse_over_enabled_button(mouse_position: Vector2) -> bool:
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
		if child.name == "Shop" or child.scene_file_path == "res://scenes/shop.tscn":
			return true
	return false

func _update_top_coins(total: int):
	top_coins_display.text = str(total)
	_update_wheel_selector(Game.selected_wheel)

func _update_wheel_selector(_selected):
	for i in range(MAX_WHEELS):
		var btn = wheel_buttons[i]
		var wheel_num = i + 1
		var unlocked = Game.is_wheel_unlocked(wheel_num)
		var can_afford = Game.can_afford_wheel(wheel_num)
		var is_selected = wheel_num == Game.selected_wheel

		btn.disabled = not unlocked
		btn.visible = true

		if is_selected:
			btn.modulate = Color(1, 0.85, 0, 1)
		elif not unlocked:
			btn.modulate = Color(0.3, 0.3, 0.3, 1)
			btn.text = "?"
		elif not can_afford:
			btn.modulate = Color(0.6, 0.3, 0.3, 1)
			btn.text = str(wheel_num)
		else:
			btn.modulate = Color(0.7, 0.9, 0.7, 1)
			btn.text = str(wheel_num)

func _on_wheel_select(wheel_num: int):
	if Game.is_wheel_unlocked(wheel_num) and not wheel_node.is_spinning:
		Game.select_wheel(wheel_num)

func _on_spin_finished(outcome):
	var result = Game.spin_wheel(outcome)
	_update_stats()
	_update_probability_chart()
	_on_shop_available_changed(Game.shop_available)
	
	if result.get("success", false):
		_show_floating_result(result.get("delta", 0), result.get("outcome_color", Color.WHITE))

func _on_wheel_spin_started():
	_on_shop_available_changed(Game.shop_available)

func _show_floating_result(delta: int, color: Color):
	var label = Label.new()
	label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	label.position = Vector2(490, 350)
	label.size = Vector2(100, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	
	if delta > 0:
		label.text = "+" + str(delta)
		result_positive_sound.play()
	elif delta < 0:
		label.text = str(delta)
		result_negative_sound.play()
	else:
		label.text = "—"
	
	wheel_node.add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 60, 1.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

func _on_shop_requested():
	shop_open_sound.play()

	var shop_path = preload("res://scenes/shop.tscn")
	var shop = shop_path.instantiate()
	add_child(shop)

	shop.tree_exited.connect(func():
		_update_stats()
		_update_wheel_selector(Game.selected_wheel)
	)

func _on_shop_available_changed(is_available: bool):
	shop_button_art.visible = is_available
	shop_button.visible = is_available
	shop_button.disabled = not is_available or wheel_node.is_spinning

func _on_shop_button_pressed():
	if wheel_node.is_spinning:
		return
	if not Game.consume_shop_available():
		return
	_on_shop_requested()

func _on_game_ended(_final_coins: int):
	var end_path = preload("res://scenes/end_screen.tscn")
	var end_screen = end_path.instantiate()
	add_child(end_screen)

func _update_stats():
	stats_spins_label.text = "Total Spins: " + str(Game.total_spins)
	stats_cycles_label.text = "Cycles: " + str(Game.cycle_count)
	var skill_count = Game.unique_skills.size()
	var level_sum = 0
	for val in Game.skill_levels.values():
		level_sum += val
	stats_skills_label.text = "Skills: " + str(skill_count) + " unique, " + str(level_sum) + " upgrades"
	stats_best_label.text = "Best Score: " + str(SaveManager.get_best_score())
	_update_upgrades_summary()

func _on_skills_changed():
	_update_stats()
	_update_probability_chart()

func _update_upgrades_summary():
	for child in upgrades_vbox.get_children():
		upgrades_vbox.remove_child(child)
		child.free()

	var lines = _get_upgrades_summary()
	if lines.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No upgrades yet"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		upgrades_vbox.add_child(empty_label)
		return

	for line in lines:
		var badge = TextureRect.new()
		badge.custom_minimum_size = Vector2(220, 48)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.texture = UPGRADE_BADGE_TEXTURE
		badge.expand_mode = 1
		badge.stretch_mode = 5

		var label = Label.new()
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.offset_left = 28.0
		label.offset_top = 6.0
		label.offset_right = -28.0
		label.offset_bottom = -6.0
		label.text = line
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(1, 0.95, 0.78, 1))
		label.add_theme_font_size_override("font_size", 13)
		label.clip_text = true
		badge.add_child(label)
		upgrades_vbox.add_child(badge)

func _get_upgrades_summary() -> Array[String]:
	var lines: Array[String] = []
	for skill in SkillManager.UPGRADEABLE_SKILLS:
		var level = Game.skill_levels.get(skill["id"], 0)
		if level > 0:
			lines.append(skill["name"] + " Lv." + str(level))
	for skill_id in Game.unique_skills:
		var skill = SkillManager.get_skill_by_id(skill_id)
		lines.append(skill.get("name", skill_id))
	return lines

func _update_probability_chart():
	for child in probability_rows.get_children():
		probability_rows.remove_child(child)
		child.free()

	var outcomes = WheelConfig.get_outcomes(Game.selected_wheel)
	outcomes = WheelConfig.apply_skill_modifiers(outcomes, Game)
	outcomes = WheelConfig.apply_display_modifiers(outcomes, Game)

	var total_weight = 0.0
	for outcome in outcomes:
		total_weight += outcome[WheelConfig.IDX_WEIGHT]
	if total_weight <= 0.0:
		return

	for outcome in outcomes:
		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 26)
		row.add_theme_constant_override("separation", 8)

		var swatch = ColorRect.new()
		swatch.custom_minimum_size = Vector2(18, 18)
		swatch.color = outcome[WheelConfig.IDX_COLOR].lightened(0.12)
		row.add_child(swatch)

		var label = Label.new()
		label.text = outcome[WheelConfig.IDX_LABEL]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92, 1))
		label.add_theme_font_size_override("font_size", 14)
		row.add_child(label)

		var percent = Label.new()
		percent.text = _format_probability(outcome[WheelConfig.IDX_WEIGHT] / total_weight * 100.0)
		percent.custom_minimum_size = Vector2(64, 0)
		percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		percent.add_theme_color_override("font_color", Color(1.0, 0.86, 0.38, 1))
		percent.add_theme_font_size_override("font_size", 14)
		row.add_child(percent)

		probability_rows.add_child(row)

func _format_probability(value: float) -> String:
	var rounded = round(value)
	if abs(value - rounded) < 0.05:
		return str(int(rounded)) + "%"
	return String.num(value, 1) + "%"
