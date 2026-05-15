# scripts/shop.gd
extends CanvasLayer

const SkillManager = preload("res://scripts/skill_manager.gd")
const SKILL_ICON_ATLAS = preload("res://assets/ui/shop-skill-icons.png")

@onready var skills_container: GridContainer = $CenterContainer/ShopPanel/ShopVBox/ScrollContainer/SkillsVBox
@onready var coins_label: Label = $CenterContainer/ShopPanel/ShopVBox/CoinsLabel
@onready var continue_button: Button = $CenterContainer/ShopPanel/ShopVBox/ContinueButton

var refresh_queued := false

const SKILL_ICON_ORDER = [
	"lucky_charm",
	"quick_spin",
	"iron_skin",
	"coin_magnet",
	"sharp_mind",
	"double_down",
	"risk_taker",
	"fortunes_favor",
	"banker",
	"second_wind",
]

func _ready():
	continue_button.pressed.connect(_on_close)
	Game.coins_changed.connect(_on_coins_changed, CONNECT_DEFERRED)
	_on_coins_changed(Game.coins)

func _request_populate_skills():
	if refresh_queued:
		return
	refresh_queued = true
	call_deferred("_populate_skills")

func _populate_skills():
	refresh_queued = false
	for child in skills_container.get_children():
		child.queue_free()

	for skill in SkillManager.get_all_skills():
		var level = Game.skill_levels.get(skill["id"], 0)
		var owned = skill["id"] in Game.unique_skills

		if owned:
			continue
		if skill["max"] > 0 and level >= skill["max"]:
			continue

		var cost = SkillManager.get_purchase_cost(skill, level)
		var can_afford = Game.coins >= cost

		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(250, 250)
		card.tooltip_text = skill["desc"]

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(vbox)

		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(108, 108)
		icon.texture = _make_skill_icon(skill["id"])
		icon.expand_mode = 1
		icon.stretch_mode = 5
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(icon)

		var name = Label.new()
		name.text = skill["name"]
		if level > 0:
			name.text += " Lv." + str(level)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65, 1))
		name.add_theme_font_size_override("font_size", 18)
		name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(name)

		var buy_btn = Button.new()
		buy_btn.text = "BUY " + str(cost)
		buy_btn.disabled = not can_afford
		buy_btn.custom_minimum_size = Vector2(180, 64)
		buy_btn.add_theme_font_size_override("font_size", 20)
		buy_btn.pressed.connect(_on_buy.bind(skill))
		vbox.add_child(buy_btn)

		skills_container.add_child(card)

func _on_buy(skill: Dictionary):
	var level = Game.skill_levels.get(skill["id"], 0)
	var cost = SkillManager.get_purchase_cost(skill, level)
	Game.buy_skill(skill["id"], cost)

func _on_coins_changed(total: int):
	coins_label.text = "Coins: " + str(total)
	_request_populate_skills()

func _on_close():
	queue_free()

func _make_skill_icon(skill_id: String) -> AtlasTexture:
	var index = SKILL_ICON_ORDER.find(skill_id)
	if index < 0:
		index = 0
	var columns = 5
	var rows = 2
	var cell_size = Vector2(
		float(SKILL_ICON_ATLAS.get_width()) / float(columns),
		float(SKILL_ICON_ATLAS.get_height()) / float(rows)
	)
	var atlas = AtlasTexture.new()
	atlas.atlas = SKILL_ICON_ATLAS
	atlas.region = Rect2(
		float(index % columns) * cell_size.x,
		float(index / columns) * cell_size.y,
		cell_size.x,
		cell_size.y
	)
	return atlas
