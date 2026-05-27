# scripts/end_screen.gd
extends CanvasLayer

const SkillManager = preload("res://scripts/skill_manager.gd")
const UiFormat = preload("res://scripts/ui_format.gd")

@export var skill_icon_atlas: Texture2D

@onready var jackpot_sound: AudioStreamPlayer = $JackpotSound
@onready var end_layout: CenterContainer = $EndLayout
@onready var final_score_label: Label = $EndLayout/Panel/Content/FinalScoreLabel
@onready var spins_value: Label = $EndLayout/Panel/Content/MetricRow/SpinsCard/VBox/Value
@onready var skills_value: Label = $EndLayout/Panel/Content/MetricRow/SkillsCard/VBox/Value
@onready var earned_value: Label = $EndLayout/Panel/Content/MetricRow/EarnedCard/VBox/Value
@onready var spent_value: Label = $EndLayout/Panel/Content/MetricRow/SpentCard/VBox/Value
@onready var time_value: Label = $EndLayout/Panel/Content/MetricRow/TimeCard/VBox/Value
@onready var outcome_rows: VBoxContainer = $EndLayout/Panel/Content/BodyRow/OutcomePanel/VBox/OutcomeRows
@onready var outcome_vbox: VBoxContainer = $EndLayout/Panel/Content/BodyRow/OutcomePanel/VBox
@onready var build_grid: GridContainer = $EndLayout/Panel/Content/BodyRow/BuildPanel/VBox/BuildScroll/SkillGrid
@onready var empty_build_label: Label = $EndLayout/Panel/Content/BodyRow/BuildPanel/VBox/EmptyBuildLabel
@onready var play_again_button: Button = $EndLayout/Panel/Content/ActionRow/PlayAgainButton
@onready var main_menu_button: Button = $EndLayout/Panel/Content/ActionRow/MainMenuButton

func _ready():
	if DisplayServer.get_name() != "headless":
		jackpot_sound.play()
	_populate_screen()
	_configure_focus_navigation()
	play_again_button.pressed.connect(_on_restart)
	main_menu_button.pressed.connect(_on_main_menu)
	_play_intro_animation()

func _populate_screen() -> void:
	final_score_label.text = UiFormat.full_number(Game.coins) + " coins"
	spins_value.text = str(Game.total_spins)
	skills_value.text = str(_get_skill_purchase_count())
	earned_value.text = UiFormat.compact_number(Game.run_coins_earned)
	spent_value.text = UiFormat.compact_number(Game.run_coins_spent)
	time_value.text = _format_elapsed(Game.get_elapsed_seconds())
	_populate_outcome_rows()
	_populate_breakdown_rows()
	_populate_build_grid()

func _populate_outcome_rows() -> void:
	for row in outcome_rows.get_children():
		var color_key := _color_key_for_row(row.name)
		if color_key.is_empty():
			continue
		var tint := _outcome_row_color(color_key)
		var label := row.get_node_or_null("Label") as Label
		var value_label := row.get_node_or_null("Value") as Label
		if label != null:
			label.add_theme_color_override("font_color", tint)
		if value_label != null:
			value_label.text = str(int(Game.run_color_counts.get(color_key, 0)))
			value_label.add_theme_color_override("font_color", tint.lightened(0.22))

func _populate_breakdown_rows() -> void:
	if outcome_vbox.has_node("CoinBreakdownTitle"):
		return
	var separator := HSeparator.new()
	separator.name = "CoinBreakdownSeparator"
	outcome_vbox.add_child(separator)
	var title := Label.new()
	title.name = "CoinBreakdownTitle"
	title.text = "Coin Breakdown"
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.24, 1))
	title.add_theme_font_size_override("font_size", 18)
	outcome_vbox.add_child(title)
	_add_breakdown_row("Base payouts", Game.run_base_payout)
	_add_breakdown_row("Skill payouts", Game.run_skill_payout)
	_add_breakdown_row("Spin costs", -Game.run_spin_costs)
	_add_breakdown_row("Shop spend", -Game.run_shop_spent)

func _add_breakdown_row(label_text: String, amount: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(0.9, 0.84, 0.7, 1))
	row.add_child(label)
	var value := Label.new()
	value.text = UiFormat.signed_compact(amount)
	value.custom_minimum_size = Vector2(72, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_color_override("font_color", Color(1.0, 0.92, 0.52, 1) if amount >= 0 else Color(1.0, 0.62, 0.32, 1))
	row.add_child(value)
	outcome_vbox.add_child(row)

func _color_key_for_row(row_name: String) -> String:
	match row_name:
		"GreenRow":
			return "green"
		"RedRow":
			return "red"
		"GoldRow":
			return "gold"
		"GreyRow":
			return "grey"
		"JackpotRow":
			return "jackpot"
		_:
			return ""

func _outcome_row_color(color_key: String) -> Color:
	match color_key:
		"green":
			return Color(0.4, 0.92, 0.44, 1)
		"red":
			return Color(1.0, 0.46, 0.38, 1)
		"gold":
			return Color(1.0, 0.84, 0.28, 1)
		"grey":
			return Color(0.82, 0.82, 0.82, 1)
		"jackpot":
			return Color(1.0, 0.92, 0.46, 1)
		_:
			return Color(0.92, 0.86, 0.74, 1)

func _populate_build_grid() -> void:
	for child in build_grid.get_children():
		child.queue_free()
	var bought := _get_bought_skills()
	empty_build_label.visible = bought.is_empty()
	build_grid.visible = not bought.is_empty()
	for item in bought:
		build_grid.add_child(_make_skill_chip(item))

func _make_skill_chip(item: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(64, 64)
	button.icon = _get_skill_icon(item["id"])
	button.expand_icon = true
	button.add_theme_stylebox_override("normal", _make_skill_style(Color(0.1, 0.035, 0.045, 0.78)))
	button.add_theme_stylebox_override("hover", _make_skill_style(Color(0.22, 0.075, 0.05, 0.94)))
	button.add_theme_stylebox_override("pressed", _make_skill_style(Color(0.33, 0.1, 0.04, 1)))

	var badge := Label.new()
	badge.text = str(item["level"])
	badge.position = Vector2(44, 42)
	badge.size = Vector2(20, 20)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_stylebox_override("normal", _make_badge_style())
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", Color(0.18, 0.05, 0.02, 1))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(badge)
	return button

func _get_bought_skills() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for skill_id in Game.bought_skill_order:
		var skill := SkillManager.get_skill_by_id(skill_id)
		if skill.is_empty():
			continue
		var is_unique := skill_id in Game.unique_skills
		var level := 1 if is_unique else int(Game.skill_levels.get(skill_id, 0))
		if level > 0:
			items.append({"id": skill_id, "name": skill.get("name", skill_id), "level": level, "unique": is_unique})
	return items

func _get_skill_purchase_count() -> int:
	var total := 0
	for skill_id in Game.bought_skill_order:
		total += 1 if skill_id in Game.unique_skills else int(Game.skill_levels.get(skill_id, 0))
	return total

func _get_skill_icon(skill_id: String) -> Texture2D:
	return UiFormat.skill_icon(skill_id, skill_icon_atlas)

func _format_elapsed(total_seconds: int) -> String:
	var seconds := total_seconds % 60
	var minutes := int(total_seconds / 60) % 60
	var hours := int(total_seconds / 3600)
	if hours > 0:
		return "%02d:%02d:%02d" % [hours, minutes, seconds]
	return "%02d:%02d" % [minutes, seconds]

func _make_skill_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(0.95, 0.72, 0.2, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4
	return style

func _make_badge_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.82, 0.24, 1)
	style.border_color = Color(0.38, 0.09, 0.02, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	return style

func _play_intro_animation() -> void:
	if bool(SaveManager.get_setting("reduced_motion")):
		end_layout.modulate.a = 1.0
		end_layout.scale = Vector2.ONE
		return
	end_layout.modulate.a = 0.0
	end_layout.scale = Vector2(0.96, 0.96)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(end_layout, "modulate:a", 1.0, 0.24)
	tween.tween_property(end_layout, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_restart() -> void:
	Game.reset_run(true)
	queue_free()

func _on_main_menu() -> void:
	var main := get_parent()
	Game.reset_run(false)
	if main != null and main.has_method("_set_game_ui_visible"):
		main.call("_set_game_ui_visible", false)
	if main != null and main.has_method("_show_main_menu"):
		main.call("_show_main_menu")
	queue_free()

func _configure_focus_navigation() -> void:
	play_again_button.focus_mode = Control.FOCUS_ALL
	main_menu_button.focus_mode = Control.FOCUS_ALL
	play_again_button.focus_neighbor_right = main_menu_button.get_path()
	play_again_button.focus_neighbor_left = play_again_button.get_path()
	main_menu_button.focus_neighbor_left = play_again_button.get_path()
	main_menu_button.focus_neighbor_right = main_menu_button.get_path()

	var chips: Array[Button] = []
	for child in build_grid.get_children():
		if child is Button:
			var button := child as Button
			button.focus_mode = Control.FOCUS_ALL
			chips.append(button)
	if chips.is_empty():
		play_again_button.focus_neighbor_top = play_again_button.get_path()
		main_menu_button.focus_neighbor_top = play_again_button.get_path()
		return

	var columns := maxi(1, build_grid.columns)
	for index in range(chips.size()):
		var button := chips[index]
		var left_index := maxi(index - 1, 0)
		var right_index := mini(index + 1, chips.size() - 1)
		var up_index := maxi(index - columns, 0)
		var down_index := index + columns
		button.focus_neighbor_left = chips[left_index].get_path()
		button.focus_neighbor_right = chips[right_index].get_path()
		button.focus_neighbor_top = chips[up_index].get_path()
		button.focus_neighbor_bottom = play_again_button.get_path() if down_index >= chips.size() else chips[down_index].get_path()

	play_again_button.focus_neighbor_top = chips[0].get_path()
	main_menu_button.focus_neighbor_top = chips[mini(chips.size() - 1, columns - 1)].get_path()

func focus_default_control() -> void:
	if play_again_button != null and play_again_button.visible and not play_again_button.disabled:
		play_again_button.grab_focus()
