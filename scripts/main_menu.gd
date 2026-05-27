extends CanvasLayer

signal new_game_requested
signal continue_requested
signal stats_requested
signal history_requested
signal credits_requested
signal options_requested
signal tutorial_requested
signal exit_requested

@onready var continue_button: Button = $MenuPanel/MenuVBox/ContinueButton
@onready var new_game_button: Button = $MenuPanel/MenuVBox/NewGameButton
@onready var stats_button: Button = $MenuPanel/MenuVBox/StatsButton
@onready var history_button: Button = $MenuPanel/MenuVBox/HistoryButton
@onready var credits_button: Button = $MenuPanel/MenuVBox/CreditsButton
@onready var options_button: Button = $MenuPanel/MenuVBox/OptionsButton
@onready var exit_button: Button = $MenuPanel/MenuVBox/ExitButton
@onready var tutorial_button: Button = $TutorialButton
@onready var stage: Control = $Stage
@onready var logo: TextureRect = $Stage/Logo
@onready var menu_panel: PanelContainer = $MenuPanel

var tutorial_sign: Control = null
var tutorial_sign_tween: Tween = null
var tutorial_sign_base_y: float = 24.0

func _ready() -> void:
	new_game_button.pressed.connect(func(): new_game_requested.emit())
	continue_button.pressed.connect(func(): continue_requested.emit())
	stats_button.pressed.connect(func(): stats_requested.emit())
	history_button.pressed.connect(func(): history_requested.emit())
	credits_button.pressed.connect(func(): credits_requested.emit())
	options_button.pressed.connect(func(): options_requested.emit())
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	exit_button.pressed.connect(func(): exit_requested.emit())
	get_viewport().size_changed.connect(_layout_menu)
	_layout_menu()
	_setup_tutorial_sign()
	_configure_focus_navigation()
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
	tutorial_sign = Control.new()
	tutorial_sign.name = "TutorialSign"
	tutorial_sign.custom_minimum_size = Vector2(190, 42)
	tutorial_sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_sign.size = tutorial_sign.custom_minimum_size

	var beam := ColorRect.new()
	beam.name = "Beam"
	beam.position = Vector2(18, 16)
	beam.size = Vector2(108, 10)
	beam.color = Color(1.0, 0.84, 0.22, 0.92)
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_sign.add_child(beam)

	var beam_glow := ColorRect.new()
	beam_glow.name = "BeamGlow"
	beam_glow.position = Vector2(12, 10)
	beam_glow.size = Vector2(124, 22)
	beam_glow.color = Color(1.0, 0.5, 0.18, 0.18)
	beam_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_sign.add_child(beam_glow)
	tutorial_sign.move_child(beam_glow, 0)

	var head := Polygon2D.new()
	head.name = "ArrowHead"
	head.color = Color(1.0, 0.9, 0.34, 0.96)
	head.polygon = PackedVector2Array([
		Vector2(120, 6),
		Vector2(176, 21),
		Vector2(120, 36),
	])
	tutorial_sign.add_child(head)

	for index in range(3):
		var dot := ColorRect.new()
		dot.name = "Dot%d" % index
		dot.position = Vector2(0 + index * 12, 15)
		dot.size = Vector2(6, 12)
		dot.color = Color(1.0, 0.96, 0.72, 0.82 - index * 0.18)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tutorial_sign.add_child(dot)

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

func _configure_focus_navigation() -> void:
	var menu_buttons: Array[Button] = [
		new_game_button,
		continue_button,
		stats_button,
		history_button,
		credits_button,
		options_button,
		exit_button,
	]
	for index in range(menu_buttons.size()):
		var button := menu_buttons[index]
		if button == null:
			continue
		button.focus_mode = Control.FOCUS_ALL
		button.focus_neighbor_top = menu_buttons[maxi(index - 1, 0)].get_path()
		button.focus_neighbor_bottom = menu_buttons[mini(index + 1, menu_buttons.size() - 1)].get_path()
	new_game_button.focus_neighbor_right = tutorial_button.get_path()
	tutorial_button.focus_mode = Control.FOCUS_ALL
	tutorial_button.focus_neighbor_left = new_game_button.get_path()
	tutorial_button.focus_neighbor_bottom = new_game_button.get_path()

func focus_default_control() -> void:
	if new_game_button != null and new_game_button.visible and not new_game_button.disabled:
		new_game_button.grab_focus()
