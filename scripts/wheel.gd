# scripts/wheel.gd
extends Control

signal spin_finished(outcome)

const WheelConfig = preload("res://scripts/wheel_config.gd")
const IDX_LABEL = 0
const IDX_OP = 1
const IDX_VALUE = 2
const IDX_WEIGHT = 3
const IDX_COLOR = 4

@onready var cycle_label: Label = $CycleLabel
@onready var wheel_number_label: Label = $WheelNumber
@onready var cost_label: Label = $CostDisplay
@onready var coins_label: Label = $CoinsDisplay
@onready var spin_button: Button = $SpinButton

var is_spinning: bool = false
var current_rotation: float = 0.0
var target_rotation: float = 0.0
var spin_start_time: float = 0.0
var base_spin_duration: float = 2.5
var pending_result: Variant = null

# Cached for consistent drawing during spin
var cached_outcomes: Array = []

func _ready():
	Game.coins_changed.connect(_on_coins_changed)
	Game.selected_wheel_changed.connect(_on_wheel_changed)
	spin_button.pressed.connect(_on_spin_pressed)

	_on_wheel_changed(Game.selected_wheel)
	_on_coins_changed(Game.coins)
	_refresh_outcomes()
	queue_redraw()

func _refresh_outcomes():
	cached_outcomes = WheelConfig.get_outcomes(Game.selected_wheel)
	cached_outcomes = WheelConfig.apply_skill_modifiers(cached_outcomes, Game)

func _process(_delta):
	if is_spinning:
		var elapsed = Time.get_ticks_msec() / 1000.0 - spin_start_time
		var duration = get_effective_spin_duration()
		var progress = min(elapsed / duration, 1.0)

		# Fast start, slow end: ease-out quint
		var eased = 1.0 - pow(1.0 - progress, 5)
		current_rotation = spin_start_rotation + target_rotation * eased
		queue_redraw()

		if progress >= 1.0:
			is_spinning = false
			spin_button.disabled = false
			current_rotation = spin_start_rotation + target_rotation
			spin_finished.emit(pending_result)

func get_effective_spin_duration() -> float:
	var quick_level = Game.skill_levels.get("quick_spin", 0)
	return base_spin_duration * pow(0.88, quick_level)

func _on_spin_pressed():
	if is_spinning:
		return
	if not Game.can_afford_wheel(Game.selected_wheel):
		return
	start_spin()

func start_spin():
	is_spinning = true
	spin_button.disabled = true
	spin_start_time = Time.get_ticks_msec() / 1000.0

	# Remember where we're starting from (accumulate rotation)
	spin_start_rotation = current_rotation

	# Refresh outcomes with current skill modifiers
	_refresh_outcomes()

	var chosen = WheelConfig.weighted_random(cached_outcomes)
	var chosen_index = -1
	for i in range(cached_outcomes.size()):
		if cached_outcomes[i][IDX_LABEL] == chosen[IDX_LABEL] and cached_outcomes[i][IDX_OP] == chosen[IDX_OP]:
			chosen_index = i
			break

	# Store for game logic — visual and game use the SAME outcome
	pending_result = chosen

	if chosen_index >= 0:
		var segment_angle = 360.0 / cached_outcomes.size()
		var segment_center = chosen_index * segment_angle + segment_angle / 2.0
		var jitter = randf_range(-segment_angle * 0.3, segment_angle * 0.3)
		var target_segment = segment_center + jitter
		var full_rotations = randi_range(3, 5) * 360
		# Pointer at right side = 0° offset
		target_rotation = full_rotations + fmod(360.0 - target_segment, 360.0)
	else:
		target_rotation = randi_range(3, 5) * 360

	queue_redraw()

func _on_coins_changed(total: int):
	coins_label.text = str(total)
	spin_button.disabled = not Game.can_afford_wheel(Game.selected_wheel) or is_spinning

func _on_wheel_changed(wheel_num: int):
	wheel_number_label.text = "Wheel " + str(wheel_num) + " / 10"
	cycle_label.text = "Cycle " + str(Game.cycle_count)
	var cost = Game.get_wheel_cost(wheel_num)
	cost_label.text = "FREE" if cost == 0 else "Cost: " + str(cost)
	spin_button.disabled = not Game.can_afford_wheel(wheel_num) or is_spinning
	_refresh_outcomes()
	queue_redraw()

func _draw():
	var wheel_outcomes = cached_outcomes if cached_outcomes.size() > 0 else WheelConfig.get_outcomes(Game.selected_wheel)
	var center = size / 2.0
	var radius = 150.0

	if wheel_outcomes.size() == 0 or radius <= 0:
		return

	var segment_angle = TAU / wheel_outcomes.size()
	var rotation_rad = deg_to_rad(current_rotation)

	for i in range(wheel_outcomes.size()):
		var outcome = wheel_outcomes[i]
		var start_angle = i * segment_angle + rotation_rad
		var end_angle = start_angle + segment_angle

		var points = PackedVector2Array()
		points.append(center)

		for j in range(33):
			var angle = start_angle + (end_angle - start_angle) * (float(j) / 32.0)
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)

		draw_colored_polygon(points, outcome[IDX_COLOR])

		for j in range(points.size() - 1):
			draw_line(points[j], points[j + 1], Color.BLACK, 1.0)

	# Draw labels on segments
	for i in range(wheel_outcomes.size()):
		var outcome = wheel_outcomes[i]
		var mid_angle = i * segment_angle + segment_angle / 2.0 + rotation_rad
		var label_pos = center + Vector2(cos(mid_angle), sin(mid_angle)) * (radius * 0.6)

		draw_string(
			ThemeDB.fallback_font,
			label_pos,
			outcome[IDX_LABEL],
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			16,
			Color.WHITE
		)
