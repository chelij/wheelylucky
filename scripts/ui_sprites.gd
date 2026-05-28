extends RefCounted

const SHEET: Texture2D = preload("res://assets/ui/game-ui-spritesheet.png")
const SKILL_ICONS_REGION := Rect2(32, 32, 1536, 768)
const SKILL_ICON_CELL_SIZE := Vector2(256, 256)
const SKILL_ICON_COLUMNS := 6

static func sheet() -> Texture2D:
	return SHEET

static func skill_icon_region(index: int) -> Rect2:
	var x := float(index % SKILL_ICON_COLUMNS) * SKILL_ICON_CELL_SIZE.x
	var y := float(index / SKILL_ICON_COLUMNS) * SKILL_ICON_CELL_SIZE.y
	return Rect2(
		SKILL_ICONS_REGION.position.x + x,
		SKILL_ICONS_REGION.position.y + y,
		SKILL_ICON_CELL_SIZE.x,
		SKILL_ICON_CELL_SIZE.y
	)
