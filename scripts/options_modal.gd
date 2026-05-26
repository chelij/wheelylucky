extends CanvasLayer

signal close_requested
signal save_exit_requested
signal setting_changed(key: String, value)

@onready var panel: PanelContainer = $CenterContainer/Panel
@onready var window_mode_selector: OptionButton = $CenterContainer/Panel/VBox/WindowModeSelector
@onready var resolution_selector: OptionButton = $CenterContainer/Panel/VBox/ResolutionSelector
@onready var resolution_warning_label: Label = $CenterContainer/Panel/VBox/ResolutionWarningLabel
@onready var music_volume_slider: HSlider = $CenterContainer/Panel/VBox/MusicVolumeSlider
@onready var music_muted_label: Label = $CenterContainer/Panel/VBox/MusicMutedLabel
@onready var sfx_volume_slider: HSlider = $CenterContainer/Panel/VBox/SfxVolumeSlider
@onready var reduced_motion_check: CheckBox = $CenterContainer/Panel/VBox/ReducedMotionCheck
@onready var muted_flashes_check: CheckBox = $CenterContainer/Panel/VBox/MutedFlashesCheck
@onready var large_ui_text_check: CheckBox = $CenterContainer/Panel/VBox/LargeUiTextCheck
@onready var save_exit_button: Button = $CenterContainer/Panel/VBox/SaveExitButton
@onready var back_button: Button = $CenterContainer/Panel/VBox/BackButton

var is_configuring := false

func _ready() -> void:
	window_mode_selector.item_selected.connect(func(index):
		if is_configuring:
			return
		setting_changed.emit("window_mode", window_mode_selector.get_item_text(index).to_lower())
	)
	resolution_selector.item_selected.connect(func(index):
		if is_configuring:
			return
		var resolution := resolution_selector.get_item_text(index)
		_update_resolution_warning(resolution)
		setting_changed.emit("resolution", resolution)
	)
	music_volume_slider.value_changed.connect(func(value):
		if is_configuring:
			return
		_update_music_muted_warning(float(value))
		setting_changed.emit("music_volume", float(value))
	)
	sfx_volume_slider.value_changed.connect(func(value):
		if is_configuring:
			return
		setting_changed.emit("sfx_volume", float(value))
	)
	reduced_motion_check.toggled.connect(func(value):
		if not is_configuring:
			setting_changed.emit("reduced_motion", value)
	)
	muted_flashes_check.toggled.connect(func(value):
		if not is_configuring:
			setting_changed.emit("muted_flashes", value)
	)
	large_ui_text_check.toggled.connect(func(value):
		if not is_configuring:
			setting_changed.emit("large_ui_text", value)
	)
	save_exit_button.pressed.connect(func(): save_exit_requested.emit())
	back_button.pressed.connect(func(): close_requested.emit())

func configure(settings: Dictionary, resolution_options: Array, in_game: bool) -> void:
	is_configuring = true
	panel.custom_minimum_size = Vector2(560, 720 if in_game else 660)
	save_exit_button.visible = in_game
	var current_resolution := str(settings.get("resolution", "1280x720"))
	_populate_selector(window_mode_selector, ["Windowed", "Fullscreen"], str(settings.get("window_mode", "windowed")))
	_populate_selector(resolution_selector, resolution_options, current_resolution)
	_update_resolution_warning(current_resolution)
	music_volume_slider.value = float(settings.get("music_volume", 0.65))
	_update_music_muted_warning(music_volume_slider.value)
	sfx_volume_slider.value = float(settings.get("sfx_volume", 0.8))
	reduced_motion_check.button_pressed = bool(settings.get("reduced_motion", false))
	muted_flashes_check.button_pressed = bool(settings.get("muted_flashes", false))
	large_ui_text_check.button_pressed = bool(settings.get("large_ui_text", false))
	is_configuring = false

func _populate_selector(selector: OptionButton, options: Array, current_value: String) -> void:
	selector.clear()
	for option in options:
		selector.add_item(str(option))
		if str(option).to_lower() == current_value.to_lower():
			selector.selected = selector.get_item_count() - 1

func _update_resolution_warning(resolution: String) -> void:
	var parts := resolution.split("x")
	var width := 1280
	var height := 720
	if parts.size() == 2:
		width = int(parts[0])
		height = int(parts[1])
	resolution_warning_label.visible = width < 1280 or height < 720

func _update_music_muted_warning(value: float) -> void:
	music_muted_label.visible = value <= 0.001
