extends RefCounted

const UiSprites = preload("res://scripts/ui_sprites.gd")

const SKILL_ICON_ORDER = [
	"lucky_charm",
	"quick_spin",
	"discount_card",
	"coin_magnet",
	"sharp_mind",
	"free_gift",
	"shop_savvy",
	"market_bell",
	"collector",
	"double_down",
	"risk_taker",
	"fortunes_favor",
	"banker",
	"second_wind",
	"randomizer",
	"momentum",
	"golden_ticket",
	"double_spin",
]

static func full_number(value: int) -> String:
	var sign = "-" if value < 0 else ""
	var text = str(abs(value))
	var out = ""
	while text.length() > 3:
		out = "," + text.substr(text.length() - 3, 3) + out
		text = text.substr(0, text.length() - 3)
	return sign + text + out

static func compact_number(value: int) -> String:
	var sign = "-" if value < 0 else ""
	var amount = float(abs(value))
	if amount < 10000.0:
		return sign + full_number(int(amount))

	var units = [
		{"suffix": "B", "value": 1000000000.0},
		{"suffix": "M", "value": 1000000.0},
		{"suffix": "K", "value": 1000.0},
	]
	for unit in units:
		if amount >= unit["value"]:
			var scaled = amount / unit["value"]
			var decimals = 0 if scaled >= 100.0 or is_equal_approx(scaled, round(scaled)) else 1
			return sign + _trim_decimal(scaled, decimals) + unit["suffix"]
	return sign + str(value)

static func signed_compact(value: int) -> String:
	if value > 0:
		return "+" + compact_number(value)
	return compact_number(value)

static func signed_full(value: int) -> String:
	if value > 0:
		return "+" + full_number(value)
	return full_number(value)

static func skill_icon(skill_id: String, icon_atlas: Texture2D) -> AtlasTexture:
	var index = SKILL_ICON_ORDER.find(skill_id)
	if index < 0:
		index = 0
	var atlas = AtlasTexture.new()
	atlas.atlas = icon_atlas if icon_atlas != null else UiSprites.sheet()
	if atlas.atlas != null and atlas.atlas.get_width() == 1536 and atlas.atlas.get_height() == 768:
		atlas.region = Rect2(
			float(index % UiSprites.SKILL_ICON_COLUMNS) * UiSprites.SKILL_ICON_CELL_SIZE.x,
			float(index / UiSprites.SKILL_ICON_COLUMNS) * UiSprites.SKILL_ICON_CELL_SIZE.y,
			UiSprites.SKILL_ICON_CELL_SIZE.x,
			UiSprites.SKILL_ICON_CELL_SIZE.y
		)
	else:
		atlas.region = UiSprites.skill_icon_region(index)
	return atlas

static func _trim_decimal(value: float, decimals: int) -> String:
	if decimals <= 0:
		return str(int(round(value)))
	var text = str(value).pad_decimals(decimals)
	while text.ends_with("0"):
		text = text.substr(0, text.length() - 1)
	if text.ends_with("."):
		text = text.substr(0, text.length() - 1)
	return text
