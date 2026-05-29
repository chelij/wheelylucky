# scripts/shop.gd
extends CanvasLayer

signal purchase_completed(cost)

const SkillManager = preload("res://scripts/skill_manager.gd")
const SkillEffects = preload("res://scripts/skill_effects.gd")
const UiFormat = preload("res://scripts/ui_format.gd")

@export var shop_panel_texture: Texture2D
@export var shop_close_button_texture: Texture2D
@export var skill_icon_atlas: Texture2D

@onready var shop_panel: PanelContainer = $CenterContainer/ShopPanel
@onready var coins_label: Label = $CenterContainer/ShopPanel/ShopVBox/CoinsLabel
@onready var continue_button: Button = $CenterContainer/ShopPanel/ShopVBox/ContinueButton
@onready var continue_button_art: TextureRect = $CenterContainer/ShopPanel/ShopVBox/ContinueButton/ButtonArt
@onready var continue_button_label: Label = $CenterContainer/ShopPanel/ShopVBox/ContinueButton/ButtonLabel
@onready var close_sound: AudioStreamPlayer = $CloseSound
@onready var skill_cards: Array[PanelContainer] = [
	$CenterContainer/ShopPanel/ShopVBox/ScrollContainer/SkillsVBox/SkillCard1 as PanelContainer,
	$CenterContainer/ShopPanel/ShopVBox/ScrollContainer/SkillsVBox/SkillCard2 as PanelContainer,
	$CenterContainer/ShopPanel/ShopVBox/ScrollContainer/SkillsVBox/SkillCard3 as PanelContainer,
	$CenterContainer/ShopPanel/ShopVBox/ScrollContainer/SkillsVBox/SkillCard4 as PanelContainer,
]
@onready var buy_buttons: Array[Button] = [
	$CenterContainer/ShopPanel/ShopVBox/ScrollContainer/SkillsVBox/SkillCard1/Content/BuyButton as Button,
	$CenterContainer/ShopPanel/ShopVBox/ScrollContainer/SkillsVBox/SkillCard2/Content/BuyButton as Button,
	$CenterContainer/ShopPanel/ShopVBox/ScrollContainer/SkillsVBox/SkillCard3/Content/BuyButton as Button,
	$CenterContainer/ShopPanel/ShopVBox/ScrollContainer/SkillsVBox/SkillCard4/Content/BuyButton as Button,
]

var refresh_queued := false
var offered_skills: Array[Dictionary] = []
var bought_skill_ids: Array[String] = []

func _ready():
	_style_shop_panel()
	_style_continue_button()
	_connect_skill_card_buttons()
	continue_button.mouse_entered.connect(_update_continue_button_state)
	continue_button.mouse_exited.connect(_update_continue_button_state)
	continue_button.button_down.connect(_update_continue_button_state)
	continue_button.button_up.connect(_update_continue_button_state)
	continue_button.pressed.connect(_on_close)
	Game.coins_changed.connect(_on_coins_changed, CONNECT_DEFERRED)
	offered_skills = Game.get_pending_shop_skills()
	_on_coins_changed(Game.coins)

func _request_populate_skills():
	if refresh_queued:
		return
	refresh_queued = true
	call_deferred("_populate_skills")

func _populate_skills():
	refresh_queued = false

	for index in range(skill_cards.size()):
		var card = skill_cards[index]
		if index >= offered_skills.size():
			_hide_card(card)
			continue

		var skill = offered_skills[index]
		var bought = skill["id"] in bought_skill_ids
		var level = Game.skill_levels.get(skill["id"], 0)
		if bought and skill["max"] != 0:
			level -= 1
		var cost_level = Game.unique_skills.size() if skill["max"] == 0 else level
		var cost = _get_discounted_cost(skill, cost_level)
		var can_afford = Game.coins >= cost and not bought

		_configure_card(card, skill, level, cost, can_afford, bought)
	_configure_focus_navigation()

func _connect_skill_card_buttons() -> void:
	for card in skill_cards:
		var buy_button = card.get_node("Content/BuyButton") as Button
		buy_button.pressed.connect(_on_card_buy_pressed.bind(card))

func _hide_card(card: PanelContainer) -> void:
	card.visible = false
	var index := skill_cards.find(card)
	if index >= 0 and index < buy_buttons.size() and buy_buttons[index] != null:
		buy_buttons[index].focus_mode = Control.FOCUS_NONE
	if card.has_meta("skill"):
		card.remove_meta("skill")

func _configure_card(card: PanelContainer, skill: Dictionary, level: int, cost: int, can_afford: bool, bought: bool) -> void:
	card.visible = true
	card.set_meta("skill", skill)

	var icon = card.get_node("Content/Icon") as TextureRect
	var name_label = card.get_node("Content/NameLabel") as Label
	var description_label = card.get_node("Content/DescriptionLabel") as Label
	var buy_button = card.get_node("Content/BuyButton") as Button
	var buy_content = card.get_node("Content/BuyButton/BuyContent") as HBoxContainer
	var buy_text_label = card.get_node("Content/BuyButton/BuyContent/BuyText") as Label
	var bought_overlay = card.get_node("BoughtOverlay") as TextureRect

	icon.texture = _get_skill_icon(skill["id"])
	name_label.text = str(skill["name"])
	description_label.text = _get_purchase_effect_text(skill, level)
	var content_node := card.get_node("Content") as Control

	bought_overlay.visible = bought
	if bought:
		bought_overlay.position = Vector2(
			buy_button.position.x + (content_node.position.x if content_node else 18.0),
			buy_button.position.y + (content_node.position.y if content_node else 18.0)
		)
		bought_overlay.size = buy_button.size
		bought_overlay.set_anchors_preset(Control.PRESET_TOP_LEFT)

	# Clean up any previous overlay decorations
	for child in card.get_children():
		if child.name.begins_with("_CardOverlay"):
			child.queue_free()
	if content_node:
		for child in content_node.get_children():
			if child.name.begins_with("_CardOverlay"):
				child.queue_free()
			if child.name == "_CardOverlay_buy_darken":
				child.queue_free()
	if buy_button != null:
		for child in buy_button.get_children():
			if child.name == "_CardOverlay_buy_darken":
				child.queue_free()

	# Dark overlay on the buy button when can't afford
	if not bought:
		if not can_afford:
			var buy_darken := Panel.new()
			buy_darken.name = "_CardOverlay_buy_darken"
			buy_darken.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var dark_style := StyleBoxFlat.new()
			dark_style.bg_color = Color(0.0, 0.0, 0.0, 0.55)
			dark_style.set_corner_radius_all(4)
			buy_darken.add_theme_stylebox_override("panel", dark_style)
			buy_darken.position = Vector2.ZERO
			buy_darken.size = buy_button.size
			buy_button.add_child(buy_darken)

	# Unique skills get a smooth rotating gold glow
	var is_unique := int(skill.get("max", 0)) == 0
	if is_unique:
		call_deferred("_spawn_card_glow", card)

	buy_button.text = ""
	buy_button.disabled = not can_afford
	buy_button.focus_mode = Control.FOCUS_ALL if can_afford else Control.FOCUS_NONE
	buy_content.visible = true
	buy_text_label.text = UiFormat.compact_number(cost)

	# Wire hover/press effect like continue button
	buy_button.set_meta("can_afford", can_afford)
	if not buy_button.has_meta("_hover_wired"):
		buy_button.set_meta("_hover_wired", true)
		buy_button.mouse_entered.connect(_on_buy_button_state_changed.bind(buy_button))
		buy_button.mouse_exited.connect(_on_buy_button_state_changed.bind(buy_button))
		buy_button.button_down.connect(_on_buy_button_state_changed.bind(buy_button))
		buy_button.button_up.connect(_on_buy_button_state_changed.bind(buy_button))
	_update_buy_button_state(buy_button)

func _spawn_card_glow(card: PanelContainer) -> void:
	if not is_instance_valid(card):
		return
	var content := card.get_node("Content") as Control
	if content == null:
		return

	var overlay := Control.new()
	overlay.name = "_CardOverlay_glow"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.size = card.size
	overlay.position = Vector2(-content.position.x, -content.position.y)
	overlay.set_script(preload("res://scripts/card_glow.gd"))
	content.add_child(overlay)

	create_tween().set_loops().tween_method(func(p: float): overlay.phase = p; overlay.queue_redraw(), 0.0, 1.0, 3.0)

func _on_buy_button_state_changed(button: Button) -> void:
	_update_buy_button_state(button)

func _update_buy_button_state(button: Button) -> void:
	if not is_instance_valid(button):
		return
	var can_afford := bool(button.get_meta("can_afford", false))
	var hovered := button.get_global_rect().has_point(button.get_global_mouse_position())
	var pressed := button.button_pressed

	if not can_afford or button.disabled:
		button.self_modulate = Color(0.72, 0.68, 0.64, 0.85)
	elif pressed:
		button.self_modulate = Color(0.82, 0.76, 0.62, 1)
	elif hovered:
		button.self_modulate = Color(1.08, 1.05, 1.0, 1)
	else:
		button.self_modulate = Color.WHITE

func _on_card_buy_pressed(card: PanelContainer) -> void:
	if not card.has_meta("skill"):
		return
	_on_buy(card.get_meta("skill") as Dictionary)

func _on_buy(skill: Dictionary):
	if skill["id"] in bought_skill_ids:
		return
	var level = Game.skill_levels.get(skill["id"], 0)
	var cost_level = Game.unique_skills.size() if skill["max"] == 0 else level
	var cost = _get_discounted_cost(skill, cost_level)
	if Game.buy_skill(skill["id"], cost):
		bought_skill_ids.append(skill["id"])
		purchase_completed.emit(cost)
		_request_populate_skills()

func _get_discounted_cost(skill: Dictionary, level: int) -> int:
	return Game._get_discounted_shop_cost(skill, level)

func _get_purchase_effect_text(skill: Dictionary, current_level: int) -> String:
	return SkillManager.get_effect_text(skill["id"], current_level)

func _get_skill_icon(skill_id: String) -> Texture2D:
	return UiFormat.skill_icon(skill_id, skill_icon_atlas)

func _style_shop_panel() -> void:
	var style = StyleBoxTexture.new()
	style.texture = shop_panel_texture
	style.texture_margin_left = 88
	style.texture_margin_top = 78
	style.texture_margin_right = 88
	style.texture_margin_bottom = 70
	style.content_margin_left = 58
	style.content_margin_top = 34
	style.content_margin_right = 58
	style.content_margin_bottom = 84
	shop_panel.add_theme_stylebox_override("panel", style)

func _style_continue_button() -> void:
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_button.custom_minimum_size = Vector2(360, 88)
	continue_button.flat = true
	continue_button.text = ""
	continue_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	continue_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	continue_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	continue_button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())

	continue_button_art.texture = shop_close_button_texture
	_update_continue_button_state()

func _update_continue_button_state() -> void:
	if continue_button_art == null or continue_button_label == null:
		return
	var pressed = continue_button.button_pressed or continue_button.has_focus() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var hovered = continue_button.get_global_rect().has_point(continue_button.get_global_mouse_position())
	if continue_button.disabled:
		continue_button_art.modulate = Color(0.45, 0.45, 0.45, 0.82)
		continue_button_label.modulate = Color(0.72, 0.68, 0.64, 1)
		continue_button_label.position = Vector2.ZERO
	elif pressed:
		continue_button_art.modulate = Color(0.78, 0.72, 0.68, 1)
		continue_button_label.modulate = Color(0.82, 0.76, 0.62, 1)
		continue_button_label.position = Vector2(0, 2)
	elif hovered:
		continue_button_art.modulate = Color(1.12, 1.08, 1.0, 1)
		continue_button_label.modulate = Color(1.0, 1.0, 0.9, 1)
		continue_button_label.position = Vector2.ZERO
	else:
		continue_button_art.modulate = Color.WHITE
		continue_button_label.modulate = Color.WHITE
		continue_button_label.position = Vector2.ZERO

func _on_coins_changed(total: int):
	coins_label.text = "Coins: " + UiFormat.compact_number(total)
	_request_populate_skills()

func _on_close():
	continue_button.disabled = true
	_update_continue_button_state()
	close_sound.play()
	await close_sound.finished
	if not Game.is_wheel_unlocked(Game.selected_wheel):
		Game.select_wheel(Game.get_highest_affordable_wheel())
	queue_free()

func _configure_focus_navigation() -> void:
	var active_buttons: Array[Button] = []
	for index in range(skill_cards.size()):
		var card := skill_cards[index]
		var button := buy_buttons[index]
		if card.visible and button != null and not button.disabled:
			active_buttons.append(button)

	continue_button.focus_mode = Control.FOCUS_ALL
	if active_buttons.is_empty():
		continue_button.focus_neighbor_top = continue_button.get_path()
		continue_button.focus_neighbor_left = continue_button.get_path()
		continue_button.focus_neighbor_right = continue_button.get_path()
		return

	for index in range(active_buttons.size()):
		var button := active_buttons[index]
		button.focus_neighbor_left = active_buttons[maxi(index - 1, 0)].get_path()
		button.focus_neighbor_right = active_buttons[mini(index + 1, active_buttons.size() - 1)].get_path()
		button.focus_neighbor_bottom = continue_button.get_path()
		button.focus_neighbor_top = button.get_path()
	continue_button.focus_neighbor_top = active_buttons[0].get_path()
	continue_button.focus_neighbor_left = continue_button.get_path()
	continue_button.focus_neighbor_right = continue_button.get_path()

func focus_default_control() -> void:
	for index in range(skill_cards.size()):
		var card := skill_cards[index]
		var button := buy_buttons[index]
		if card.visible and button != null and not button.disabled:
			button.grab_focus()
			return
	if continue_button != null and continue_button.visible and not continue_button.disabled:
		continue_button.grab_focus()
