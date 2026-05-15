# scripts/wheel.gd
extends Control

signal spin_finished(outcome)
signal spin_started

const WheelConfig = preload("res://scripts/wheel_config.gd")
const SoundFactory = preload("res://scripts/sound_factory.gd")
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
@onready var spin_sound: AudioStreamPlayer = $SpinSound

var is_spinning: bool = false
var current_rotation: float = 0.0
var target_rotation: float = 0.0
var spin_start_rotation: float = 0.0
var spin_start_time: float = 0.0
var base_spin_duration: float = 2.5

# Cached for consistent drawing during spin
var cached_outcomes: Array = []

func _ready():
	spin_sound.stream = SoundFactory.make_tone(520.0, 0.18)
	Game.coins_changed.connect(_on_coins_changed)
	Game.selected_wheel_changed.connect(_on_wheel_changed)
	Game.skills_changed.connect(_on_skills_changed)
	spin_button.pressed.connect(_on_spin_pressed)

	_on_wheel_changed(Game.selected_wheel)
	_on_coins_changed(Game.coins)
	_refresh_outcomes()
	queue_redraw()

func _refresh_outcomes():
	cached_outcomes = WheelConfig.get_outcomes(Game.selected_wheel)
	cached_outcomes = WheelConfig.apply_skill_modifiers(cached_outcomes, Game)
	cached_outcomes = WheelConfig.apply_display_modifiers(cached_outcomes, Game)

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
			spin_finished.emit(get_pointer_outcome())

func get_effective_spin_duration() -> float:
	var quick_level = Game.skill_levels.get("quick_spin", 0)
	return base_spin_duration * pow(0.988, quick_level)

func _on_spin_pressed():
	if is_spinning:
		return
	if not Game.can_afford_wheel(Game.selected_wheel):
		return
	start_spin()

func start_spin():
	var payment = Game.begin_spin()
	if not payment.get("success", false):
		return

	is_spinning = true
	spin_button.disabled = true
	spin_started.emit()
	spin_start_time = Time.get_ticks_msec() / 1000.0
	spin_sound.play()

	# Remember where we're starting from (accumulate rotation)
	spin_start_rotation = current_rotation

	# Refresh outcomes with current skill modifiers
	_refresh_outcomes()

	target_rotation = float(randi_range(10, 20)) * 360.0 + randf_range(0.0, 360.0)

	queue_redraw()

func instant_spin():
	if is_spinning:
		return
	var payment = Game.begin_spin()
	if not payment.get("success", false):
		return

	spin_started.emit()
	_refresh_outcomes()
	current_rotation += float(randi_range(10, 20)) * 360.0 + randf_range(0.0, 360.0)
	queue_redraw()
	spin_finished.emit(get_pointer_outcome())

func get_pointer_outcome():
	if cached_outcomes.size() == 0:
		_refresh_outcomes()
	if cached_outcomes.size() == 0:
		return null

	var total_weight = _get_total_weight(cached_outcomes)
	if total_weight <= 0.0:
		return cached_outcomes[0]

	# Pointer is on the right side of the wheel, where local angle 0° is drawn.
	var pointer_angle = fposmod(-current_rotation, 360.0)
	var cumulative = 0.0
	for outcome in cached_outcomes:
		var segment_degrees = 360.0 * (outcome[IDX_WEIGHT] / total_weight)
		if pointer_angle >= cumulative and pointer_angle < cumulative + segment_degrees:
			return outcome
		cumulative += segment_degrees

	return cached_outcomes[-1]

func _get_total_weight(outcomes: Array) -> float:
	var total = 0.0
	for outcome in outcomes:
		total += outcome[IDX_WEIGHT]
	return total

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

func _on_skills_changed():
	if is_spinning:
		return
	_refresh_outcomes()
	queue_redraw()

func _draw():
	var wheel_outcomes = cached_outcomes if cached_outcomes.size() > 0 else WheelConfig.get_outcomes(Game.selected_wheel)
	var center = size / 2.0
	var outer_radius = 150.0
	var hub_radius = 45.0

	if wheel_outcomes.size() == 0 or outer_radius <= 0:
		return

	var total_weight = _get_total_weight(wheel_outcomes)
	if total_weight <= 0.0:
		return

	var rotation_rad = deg_to_rad(current_rotation)
	var angle_cursor = rotation_rad

	for i in range(wheel_outcomes.size()):
		var outcome = wheel_outcomes[i]
		var segment_angle = TAU * (outcome[IDX_WEIGHT] / total_weight)
		var start_angle = angle_cursor
		var end_angle = rotation_rad + TAU if i == wheel_outcomes.size() - 1 else start_angle + segment_angle + 0.002
		angle_cursor = end_angle

		var points = PackedVector2Array()
		points.append(center)
		for j in range(65):
			var angle = start_angle + (end_angle - start_angle) * (float(j) / 64.0)
			points.append(center + Vector2(cos(angle), sin(angle)) * outer_radius)

		var segment_color: Color = outcome[IDX_COLOR].lightened(0.12)
		segment_color.a = 1.0
		draw_colored_polygon(points, segment_color)

		draw_line(
			center,
			center + Vector2(cos(start_angle), sin(start_angle)) * outer_radius,
			Color(1.0, 0.82, 0.24),
			1.8
		)

	draw_arc(center, outer_radius + 10.0, 0.0, TAU, 160, Color(0.35, 0.08, 0.04), 22.0)
	draw_arc(center, outer_radius + 14.0, 0.0, TAU, 160, Color(1.0, 0.82, 0.24), 5.0)
	draw_arc(center, outer_radius + 2.0, 0.0, TAU, 160, Color(1.0, 0.95, 0.48), 4.0)
	draw_arc(center, outer_radius, 0.0, TAU, 160, Color(0.45, 0.21, 0.02), 2.2)
	draw_circle(center, hub_radius, Color(0.93, 0.58, 0.08))
	draw_circle(center, hub_radius * 0.76, Color(1.0, 0.78, 0.2))
	draw_arc(center, hub_radius, 0.0, TAU, 128, Color(0.35, 0.18, 0.02), 2.0)
	draw_arc(center, hub_radius * 0.76, 0.0, TAU, 128, Color(1.0, 0.93, 0.46), 1.4)

	# Draw labels on segments
	angle_cursor = rotation_rad
	for i in range(wheel_outcomes.size()):
		var outcome = wheel_outcomes[i]
		var segment_angle = TAU * (outcome[IDX_WEIGHT] / total_weight)
		var mid_angle = angle_cursor + segment_angle / 2.0
		angle_cursor += segment_angle
		var label_pos = center + Vector2(cos(mid_angle), sin(mid_angle)) * ((hub_radius + outer_radius) / 2.0)

		draw_string(
			ThemeDB.fallback_font,
			label_pos,
			outcome[IDX_LABEL],
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			16,
			Color.WHITE
		)
