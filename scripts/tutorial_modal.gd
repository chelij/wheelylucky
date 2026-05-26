extends CanvasLayer

signal close_requested

const PAGE_TITLES := [
	"Basics",
	"Wheels & Shops",
	"Outcome Names",
	"Upgradeable Skills",
	"Unique Skills",
]

@onready var page_title_label: Label = $CenterContainer/Panel/VBox/PageTitleLabel
@onready var page_stack: Control = $CenterContainer/Panel/VBox/PagePanel/PageStack
@onready var prev_button: Button = $CenterContainer/Panel/VBox/NavRow/PrevButton
@onready var page_indicator_label: Label = $CenterContainer/Panel/VBox/NavRow/PageIndicatorLabel
@onready var next_button: Button = $CenterContainer/Panel/VBox/NavRow/NextButton
@onready var back_button: Button = $CenterContainer/Panel/VBox/BackButton

var pages: Array[CanvasItem] = []
var page_index: int = 0

func _ready() -> void:
	for child in page_stack.get_children():
		if child is CanvasItem:
			pages.append(child)
	prev_button.pressed.connect(func(): _change_page(-1))
	next_button.pressed.connect(func(): _change_page(1))
	back_button.pressed.connect(func(): close_requested.emit())
	_render_page()

func _change_page(direction: int) -> void:
	if pages.is_empty():
		return
	page_index = clampi(page_index + direction, 0, pages.size() - 1)
	_render_page()

func _render_page() -> void:
	if pages.is_empty():
		return
	for i in range(pages.size()):
		pages[i].visible = i == page_index
	page_title_label.text = PAGE_TITLES[page_index] if page_index < PAGE_TITLES.size() else ""
	page_indicator_label.text = "Page " + str(page_index + 1) + " / " + str(pages.size())
	prev_button.disabled = page_index == 0
	next_button.disabled = page_index == pages.size() - 1
