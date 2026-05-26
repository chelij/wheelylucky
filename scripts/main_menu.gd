extends CanvasLayer

signal new_game_requested
signal continue_requested
signal stats_requested
signal history_requested
signal options_requested
signal tutorial_requested
signal exit_requested

@onready var continue_button: Button = $MenuPanel/MenuVBox/ContinueButton
@onready var new_game_button: Button = $MenuPanel/MenuVBox/NewGameButton
@onready var stats_button: Button = $MenuPanel/MenuVBox/StatsButton
@onready var history_button: Button = $MenuPanel/MenuVBox/HistoryButton
@onready var options_button: Button = $MenuPanel/MenuVBox/OptionsButton
@onready var exit_button: Button = $MenuPanel/MenuVBox/ExitButton
@onready var tutorial_button: Button = $TutorialButton
@onready var stage: Control = $Stage
@onready var logo: TextureRect = $Stage/Logo
@onready var menu_panel: PanelContainer = $MenuPanel

var tutorial_sign: Label = null
var tutorial_sign_tween: Tween = null
var tutorial_sign_base_y: float = 24.0

func _ready() -> void:
	new_game_button.pressed.connect(func(): new_game_requested.emit())
	continue_button.pressed.connect(func(): continue_requested.emit())
	stats_button.pressed.connect(func(): stats_requested.emit())
	history_button.pressed.connect(func(): history_requested.emit())
	options_button.pressed.connect(func(): options_requested.emit())
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	exit_button.pressed.connect(func(): exit_requested.emit())
	get_viewport().size_changed.connect(_layout_menu)
	_layout_menu()
	_setup_tutorial_sign()
	_layout_menu()

func set_continue_available(is_available: bool) -> void:
	continue_button.disabled = not is_available
	continue_button.modulate = Color.WHITE if is_available else Color(0.65, 0.65, 0.65, 0.72)

func _layout_menu(viewport_override: Vector2 = Vector2.ZERO) -> void:
	if logo == null or menu_panel == null:
		return
	var viewport_size := viewport_override if viewport_override != Vector2.ZERO else get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var margin := 48.0
	var panel_size := Vector2(
		clamp(viewport_size.x * 0.32, 360.0, 430.0),
		clamp(viewport_size.y * 0.7, 470.0, 530.0)
	)
	var stacked := viewport_size.x < 980.0

	if stacked:
		var logo_width: float = min(viewport_size.x - margin * 2.0, 620.0)
		var logo_height: float = logo_width * 0.46
		logo.position = Vector2((viewport_size.x - logo_width) * 0.5, max(36.0, viewport_size.y * 0.08))
		logo.size = Vector2(logo_width, logo_height)
		menu_panel.position = Vector2((viewport_size.x - panel_size.x) * 0.5, min(viewport_size.y - panel_size.y - 28.0, logo.position.y + logo_height + 18.0))
		menu_panel.size = panel_size
	else:
		var logo_width: float = clamp(viewport_size.x * 0.52, 560.0, 760.0)
		var logo_height: float = logo_width * 0.46
		logo.position = Vector2(margin, (viewport_size.y - logo_height) * 0.36)
		logo.size = Vector2(logo_width, logo_height)
		menu_panel.position = Vector2(viewport_size.x - panel_size.x - 64.0, (viewport_size.y - panel_size.y) * 0.5)
		menu_panel.size = panel_size

	tutorial_button.position = Vector2(viewport_size.x - 62.0, 20.0)
	if tutorial_sign != null:
		tutorial_sign_base_y = 24.0
		tutorial_sign.position = Vector2(max(18.0, viewport_size.x - 292.0), tutorial_sign_base_y)

func apply_accessibility_settings(settings: Dictionary) -> void:
	_set_tutorial_sign_motion_enabled(not bool(settings.get("reduced_motion", false)))

func _setup_tutorial_sign() -> void:
	if bool(SaveManager.get_setting("tutorial_sign_seen")):
		return
	tutorial_sign = Label.new()
	tutorial_sign.name = "TutorialSign"
	tutorial_sign.text = "Tutorial ->"
	tutorial_sign.custom_minimum_size = Vector2(190, 34)
	tutorial_sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tutorial_sign.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_sign.add_theme_color_override("font_color", Color(1.0, 0.92, 0.48, 1))
	tutorial_sign.add_theme_color_override("font_shadow_color", Color(0.1, 0.02, 0.01, 1))
	tutorial_sign.add_theme_constant_override("shadow_offset_x", 1)
	tutorial_sign.add_theme_constant_override("shadow_offset_y", 2)
	tutorial_sign.add_theme_font_size_override("font_size", 22)
	add_child(tutorial_sign)
	_layout_menu()
	_set_tutorial_sign_motion_enabled(not bool(SaveManager.get_setting("reduced_motion")))

func _set_tutorial_sign_motion_enabled(is_enabled: bool) -> void:
	if tutorial_sign == null:
		return
	if tutorial_sign_tween != null and tutorial_sign_tween.is_valid():
		tutorial_sign_tween.kill()
	tutorial_sign_tween = null
	tutorial_sign.position.y = tutorial_sign_base_y
	if not is_enabled:
		return
	tutorial_sign_tween = create_tween()
	tutorial_sign_tween.set_loops()
	tutorial_sign_tween.tween_property(tutorial_sign, "position:y", tutorial_sign_base_y - 8.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tutorial_sign_tween.tween_property(tutorial_sign, "position:y", tutorial_sign_base_y, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_tutorial_pressed() -> void:
	SaveManager.set_setting("tutorial_sign_seen", true)
	if tutorial_sign_tween != null and tutorial_sign_tween.is_valid():
		tutorial_sign_tween.kill()
	tutorial_sign_tween = null
	if tutorial_sign != null and is_instance_valid(tutorial_sign):
		tutorial_sign.queue_free()
	tutorial_sign = null
	tutorial_requested.emit()
