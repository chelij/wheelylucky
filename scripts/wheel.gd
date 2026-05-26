# scripts/wheel.gd
extends Control

signal spin_finished(outcome)
signal spin_started(cost)
signal shop_requested

const WheelConfig = preload("res://scripts/wheel_config.gd")
const SkillEffects = preload("res://scripts/skill_effects.gd")
const UiFormat = preload("res://scripts/ui_format.gd")

@export var center_medallion_texture: Texture2D

const IDX_LABEL = 0
const IDX_OP = 1
const IDX_VALUE = 2
const IDX_SLOTS = 3
const IDX_COLOR = 4

@onready var cycle_label: Label = $CycleLabel
@onready var wheel_number_label: Label = $WheelNumber
@onready var cost_label: Label = $CostDisplay
@onready var coins_label: Label = $CoinsDisplay
@onready var spin_button: Button = $SpinButton
@onready var prev_wheel_button: Button = $PrevWheelButton
@onready var next_wheel_button: Button = $NextWheelButton
@onready var shop_button: Button = $ShopButton
@onready var pointer_arrow: TextureRect = $PointerArrow
@onready var pointer_indicator: TextureRect = $PointerArrow/PointerIndicator
@onready var spin_sound: AudioStreamPlayer = $SpinSound

var is_spinning: bool = false
var current_rotation: float = 0.0
var target_rotation: float = 0.0
var spin_start_rotation: float = 0.0
var spin_start_time: float = 0.0
var pointer_start_rotation: float = 0.0
var pointer_current_rotation: float = 0.0
var pointer_target_rotation: float = 0.0
var base_spin_duration: float = 2.5
var pointer_default_position: Vector2 = Vector2.ZERO
var pointer_default_rotation: float = 0.0
var shop_offer_available: bool = false
var rng := RandomNumberGenerator.new()

# Cached for consistent drawing during spin
var cached_outcomes: Array = []
var cached_slots: Array = []

func _ready():
	rng.randomize()
	pointer_arrow.pivot_offset = pointer_arrow.size / 2.0
	pointer_default_position = pointer_arrow.position
	pointer_default_rotation = pointer_arrow.rotation_degrees
	_update_pointer_visual()
	_style_arrow_buttons()
	_style_shop_button()
	Game.coins_changed.connect(_on_coins_changed)
	Game.selected_wheel_changed.connect(_on_wheel_changed)
	Game.skills_changed.connect(_on_skills_changed)
	spin_button.pressed.connect(_on_spin_pressed)
	prev_wheel_button.pressed.connect(_on_prev_wheel_pressed)
	next_wheel_button.pressed.connect(_on_next_wheel_pressed)
	shop_button.pressed.connect(_on_shop_button_pressed)

	_on_wheel_changed(Game.selected_wheel)
	_on_coins_changed(Game.coins)
	_refresh_outcomes()
	_update_pointer_indicator()
	queue_redraw()

func _refresh_outcomes():
	cached_outcomes = WheelConfig.get_outcomes(Game.selected_wheel)
	cached_outcomes = WheelConfig.apply_skill_modifiers(cached_outcomes, Game, Game.selected_wheel)
	cached_outcomes = WheelConfig.apply_display_modifiers(cached_outcomes, Game)
	cached_slots = []
	for outcome in cached_outcomes:
		for _i in range(int(outcome[IDX_SLOTS])):
			cached_slots.append(outcome)
	if "randomizer" in Game.unique_skills:
		# Randomizer shuffles individual slot positions on the wheel while preserving total odds.
		cached_slots.shuffle()

func _process(_delta):
	if is_spinning:
		var elapsed = Time.get_ticks_msec() / 1000.0 - spin_start_time
		var duration = get_effective_spin_duration()
		var progress = min(elapsed / duration, 1.0)

		# Fast launch with a longer slow tail, while keeping the same total duration.
		var eased = 1.0 - pow(1.0 - progress, 7)
		current_rotation = spin_start_rotation + target_rotation * eased
		if "double_spin" in Game.unique_skills:
			pointer_current_rotation = pointer_start_rotation + pointer_target_rotation * eased
		_update_pointer_visual()
		_update_pointer_indicator()
		queue_redraw()

		if progress >= 1.0:
			is_spinning = false
			spin_button.disabled = false
			current_rotation = fposmod(spin_start_rotation + target_rotation, 360.0)
			if "double_spin" in Game.unique_skills:
				pointer_current_rotation = fposmod(pointer_start_rotation + pointer_target_rotation, 360.0)
			_update_pointer_visual()
			_apply_fortunes_favor_spin_push()
			_update_pointer_indicator()
			_update_shop_button()
			spin_finished.emit(get_pointer_outcome())

func get_effective_spin_duration() -> float:
	if _should_resolve_risk_taker_w1_now():
		return 0.0
	var quick_level = Game.skill_levels.get("quick_spin", 0)
	return base_spin_duration * pow(SkillEffects.QUICK_SPIN_DURATION_MULTIPLIER_PER_LEVEL, quick_level)

func _style_arrow_button(button: Button) -> void:
	var normal = StyleBoxEmpty.new()
	var hover = StyleBoxEmpty.new()
	var pressed = StyleBoxEmpty.new()
	var disabled = StyleBoxEmpty.new()
	button.flat = true
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("icon_normal_color", Color(1.0, 1.0, 1.0, 1))
	button.add_theme_color_override("icon_hover_color", Color(1.08, 1.05, 0.98, 1))
	button.add_theme_color_override("icon_pressed_color", Color(0.88, 0.82, 0.72, 1))
	button.add_theme_color_override("icon_disabled_color", Color(1.0, 1.0, 1.0, 0.42))
	button.text = ""
	button.expand_icon = true

func _style_arrow_buttons() -> void:
	_style_arrow_button(prev_wheel_button)
	_style_arrow_button(next_wheel_button)

func _style_shop_button() -> void:
	_style_arrow_button(shop_button)
	shop_button.visible = false
	shop_button.disabled = true

func _on_spin_pressed():
	if is_spinning:
		return
	if not Game.can_afford_wheel(Game.selected_wheel):
		return
	start_spin()

func _on_prev_wheel_pressed() -> void:
	if is_spinning:
		return
	for wheel_num in range(Game.selected_wheel - 1, 0, -1):
		if Game.is_wheel_unlocked(wheel_num):
			Game.select_wheel(wheel_num)
			return

func _on_next_wheel_pressed() -> void:
	if is_spinning:
		return
	for wheel_num in range(Game.selected_wheel + 1, Game.MAX_WHEELS + 1):
		if Game.is_wheel_unlocked(wheel_num):
			Game.select_wheel(wheel_num)
			return

func _on_shop_button_pressed() -> void:
	if is_spinning or not shop_offer_available:
		return
	shop_requested.emit()

func set_shop_available(is_available: bool) -> void:
	shop_offer_available = is_available
	_update_shop_button()

func _update_shop_button() -> void:
	if shop_button == null:
		return
	var should_show = shop_offer_available and not is_spinning
	shop_button.visible = should_show
	shop_button.disabled = not should_show

func start_spin():
	var payment = Game.begin_spin()
	if not payment.get("success", false):
		return

	_refresh_outcomes()
	if _should_resolve_risk_taker_w1_now():
		spin_started.emit(int(payment.get("cost", 0)))
		spin_finished.emit(_get_risk_taker_w1_plus_outcome())
		return

	is_spinning = true
	spin_button.disabled = true
	_update_shop_button()
	spin_started.emit(int(payment.get("cost", 0)))
	spin_start_time = Time.get_ticks_msec() / 1000.0
	spin_sound.play()

	# Normalize before each spin to avoid large accumulated rotations hurting angle precision.
	spin_start_rotation = fposmod(current_rotation, 360.0)
	current_rotation = spin_start_rotation

	target_rotation = float(rng.randi_range(12, 24)) * 360.0 + rng.randf_range(0.0, 360.0)
	pointer_start_rotation = fposmod(pointer_current_rotation, 360.0)
	pointer_current_rotation = pointer_start_rotation
	pointer_target_rotation = 0.0
	if "double_spin" in Game.unique_skills:
		pointer_target_rotation = -float(rng.randi_range(8, 18)) * 360.0 - rng.randf_range(0.0, 360.0)

	queue_redraw()

func instant_spin():
	if is_spinning:
		return
	var payment = Game.begin_spin()
	if not payment.get("success", false):
		return

	spin_started.emit(int(payment.get("cost", 0)))
	_refresh_outcomes()
	if _should_resolve_risk_taker_w1_now():
		spin_finished.emit(_get_risk_taker_w1_plus_outcome())
		return
	current_rotation = fposmod(current_rotation + float(rng.randi_range(12, 24)) * 360.0 + rng.randf_range(0.0, 360.0), 360.0)
	if "double_spin" in Game.unique_skills:
		pointer_current_rotation = fposmod(pointer_current_rotation - float(rng.randi_range(8, 18)) * 360.0 - rng.randf_range(0.0, 360.0), 360.0)
	_apply_fortunes_favor_spin_push()
	_update_pointer_visual()
	_update_pointer_indicator()
	queue_redraw()
	spin_finished.emit(get_pointer_outcome())

func _should_resolve_risk_taker_w1_now() -> bool:
	return Game.selected_wheel == 1 and "risk_taker" in Game.unique_skills

func _get_risk_taker_w1_plus_outcome():
	for outcome in cached_outcomes:
		if outcome[IDX_OP] == WheelConfig.OP_ADD:
			return outcome
	return cached_outcomes[0] if cached_outcomes.size() > 0 else null

func _apply_fortunes_favor_spin_push() -> void:
	if "fortunes_favor" not in Game.unique_skills:
		return
	var outcome = get_pointer_outcome()
	if outcome == null:
		return
	if outcome[IDX_OP] in [WheelConfig.OP_SUBTRACT, WheelConfig.OP_DIVIDE]:
		var slot_degrees = 360.0 / float(cached_slots.size())
		current_rotation += slot_degrees * SkillEffects.FORTUNES_FAVOR_PUSH_SLOTS
		queue_redraw()

func get_pointer_outcome():
	if cached_slots.size() == 0:
		_refresh_outcomes()
	if cached_slots.size() == 0:
		return null

	var slot_index = _get_pointer_slot_index()
	return cached_slots[slot_index]

func _refresh_wheel_hub() -> void:
	wheel_number_label.text = "◎ " + str(Game.selected_wheel) + " / 10"
	cycle_label.visible = false
	var cost = Game.get_wheel_cost(Game.selected_wheel)
	cost_label.text = "◆ FREE" if cost == 0 else "◆ " + str(cost)
	spin_button.disabled = not Game.can_afford_wheel(Game.selected_wheel) or is_spinning
	_update_wheel_arrow_buttons()
	_update_shop_button()
	queue_redraw()

func _on_coins_changed(total: int):
	coins_label.text = UiFormat.compact_number(total)
	_refresh_wheel_hub()

func _on_wheel_changed(_wheel_num: int):
	_refresh_wheel_hub()
	_refresh_outcomes()
	_update_pointer_indicator()
	queue_redraw()

func _update_wheel_arrow_buttons() -> void:
	var has_prev = false
	for wheel_num in range(Game.selected_wheel - 1, 0, -1):
		if Game.is_wheel_unlocked(wheel_num):
			has_prev = true
			break
	prev_wheel_button.visible = has_prev
	prev_wheel_button.disabled = is_spinning or not has_prev

	var has_next = false
	for wheel_num in range(Game.selected_wheel + 1, Game.MAX_WHEELS + 1):
		if Game.is_wheel_unlocked(wheel_num):
			has_next = true
			break
	next_wheel_button.visible = has_next
	next_wheel_button.disabled = is_spinning or not has_next

func _on_skills_changed():
	_refresh_wheel_hub()
	if is_spinning:
		return
	if "double_spin" not in Game.unique_skills:
		pointer_current_rotation = 0.0
		_update_pointer_visual()
	_refresh_outcomes()
	_update_pointer_indicator()
	queue_redraw()

func _update_pointer_visual() -> void:
	if pointer_arrow == null:
		return
	if "double_spin" not in Game.unique_skills:
		pointer_arrow.position = pointer_default_position
		pointer_arrow.rotation_degrees = pointer_default_rotation
		return

	var center = size / 2.0
	var pointer_size = pointer_arrow.size
	var normal_pointer_center = pointer_default_position + pointer_size / 2.0
	var orbit_radius = normal_pointer_center.distance_to(center)
	var pointer_angle_degrees = _get_pointer_angle_degrees()
	var angle = deg_to_rad(pointer_angle_degrees)
	var pointer_center = center + Vector2(cos(angle), sin(angle)) * orbit_radius
	pointer_arrow.position = pointer_center - pointer_size / 2.0
	pointer_arrow.rotation_degrees = pointer_angle_degrees + pointer_default_rotation

func _get_pointer_angle_degrees() -> float:
	return pointer_current_rotation if "double_spin" in Game.unique_skills else 0.0

func _update_pointer_indicator() -> void:
	if pointer_indicator == null:
		return
	var outcome = get_pointer_outcome()
	if outcome == null:
		pointer_indicator.modulate = Color(1.0, 0.82, 0.24, 1.0)
		return
	pointer_indicator.modulate = outcome[IDX_COLOR].lightened(0.18)

func _get_pointer_slot_index() -> int:
	if cached_slots.size() == 0:
		return 0
	# Use the same pointer angle that drives the visible pointer node.
	var pointer_angle = fposmod(_get_pointer_angle_degrees() - current_rotation, 360.0)
	var slot_degrees = 360.0 / float(cached_slots.size())
	return int(floor(pointer_angle / slot_degrees)) % cached_slots.size()

func _draw():
	var wheel_slots = cached_slots
	if wheel_slots.size() == 0:
		_refresh_outcomes()
		wheel_slots = cached_slots

	var center = size / 2.0
	var outer_radius = 250.0
	var hub_radius = 120.0

	if wheel_slots.size() == 0 or outer_radius <= 0:
		return

	var rotation_rad = deg_to_rad(current_rotation)
	var slot_angle = TAU / float(wheel_slots.size())
	var section_edges: Array[float] = []

	_draw_alpha_gradient_shadow(center, outer_radius + 10.0, 28.0, 0.13, 10, Vector2(0, 4))
	draw_circle(center, outer_radius + 26.0, Color(0.18, 0.035, 0.035, 0.98))
	draw_arc(center, outer_radius + 31.0, 0.0, TAU, 180, Color(1.0, 0.75, 0.18, 0.88), 5.0)
	draw_arc(center, outer_radius + 18.0, 0.0, TAU, 180, Color(0.9, 0.16, 0.04, 0.9), 4.0)

	for slot_index in range(wheel_slots.size()):
		var outcome = wheel_slots[slot_index]
		var start_angle = rotation_rad + float(slot_index) * slot_angle
		var end_angle = start_angle + slot_angle + 0.001
		var points = PackedVector2Array()
		points.append(center)
		for j in range(9):
			var angle = start_angle + (end_angle - start_angle) * (float(j) / 8.0)
			points.append(center + Vector2(cos(angle), sin(angle)) * outer_radius)

		var segment_color: Color = outcome[IDX_COLOR].lightened(0.12)
		segment_color.a = 1.0
		draw_colored_polygon(points, segment_color)

		var next_outcome = wheel_slots[(slot_index + 1) % wheel_slots.size()]
		if next_outcome != outcome:
			section_edges.append(end_angle)

	var separator_color = Color(1.0, 0.82, 0.24, 0.92)
	for edge_angle in section_edges:
		if _is_pointer_side_edge(edge_angle):
			continue
		draw_line(center, center + Vector2(cos(edge_angle), sin(edge_angle)) * outer_radius, separator_color, 1.0, true)

	draw_arc(center, outer_radius + 10.0, 0.0, TAU, 160, Color(0.35, 0.08, 0.04), 22.0)
	draw_arc(center, outer_radius + 14.0, 0.0, TAU, 160, Color(1.0, 0.82, 0.24), 5.0)
	draw_arc(center, outer_radius + 2.0, 0.0, TAU, 160, Color(1.0, 0.95, 0.48), 4.0)
	_draw_alpha_gradient_arc_shadow(center, outer_radius - 3.0, 18.0, 0.14, 8, 10.0)
	draw_arc(center, outer_radius, 0.0, TAU, 160, Color(0.45, 0.21, 0.02), 2.2)
	_draw_center_medallion(center, hub_radius)
	_draw_wheel_progress()

	# Labels are intentionally omitted on the wheel for mobile readability.
	# Outcome values are shown in the probability panel and floating result feedback instead.

func _draw_center_medallion(center: Vector2, hub_radius: float) -> void:
	var size_px = hub_radius * 2.55
	var rect = Rect2(center - Vector2(size_px, size_px) / 2.0, Vector2(size_px, size_px))
	_draw_alpha_gradient_shadow(center, hub_radius * 1.04, 22.0, 0.15, 9, Vector2(0, 3))
	if center_medallion_texture != null:
		draw_texture_rect(center_medallion_texture, rect, false)
	else:
		draw_circle(center, hub_radius, Color(0.12, 0.035, 0.07, 0.92))

func _draw_alpha_gradient_shadow(center: Vector2, base_radius: float, spread: float, max_alpha: float, rings: int, offset: Vector2 = Vector2.ZERO) -> void:
	var ring_count = max(2, rings)
	for i in range(ring_count):
		var t = float(i) / float(ring_count - 1)
		var alpha = max_alpha * t * t
		if alpha <= 0.001:
			continue
		var radius = base_radius + spread * (1.0 - t)
		draw_circle(center + offset, radius, Color(0.0, 0.0, 0.0, alpha))

func _draw_alpha_gradient_arc_shadow(center: Vector2, base_radius: float, spread: float, max_alpha: float, rings: int, max_width: float) -> void:
	var ring_count = max(2, rings)
	for i in range(ring_count):
		var t = float(i) / float(ring_count - 1)
		var alpha = max_alpha * t * t
		if alpha <= 0.001:
			continue
		var radius = base_radius - spread * (1.0 - t)
		var width = lerp(1.5, max_width, t)
		draw_arc(center, radius, 0.0, TAU, 160, Color(0.0, 0.0, 0.0, alpha), width)

func _is_pointer_side_edge(angle: float) -> bool:
	var normalized = fposmod(angle, TAU)
	return normalized < 0.035 or normalized > TAU - 0.035

func _draw_wheel_progress() -> void:
	var center = size / 2.0
	var radius = 268.0
	var start_angle = deg_to_rad(214.0)
	var end_angle = deg_to_rad(326.0)
	draw_arc(center, radius + 4.0, start_angle, end_angle, 84, Color(0.12, 0.03, 0.025, 0.92), 10.0, true)
	draw_arc(center, radius + 8.0, start_angle, end_angle, 84, Color(1.0, 0.76, 0.18, 0.92), 3.0, true)
	draw_arc(center, radius - 2.0, start_angle, end_angle, 84, Color(0.88, 0.18, 0.04, 0.72), 3.0, true)
	draw_arc(center, radius - 10.0, start_angle, end_angle, 84, Color(1.0, 0.92, 0.42, 0.55), 1.4, true)

	for wheel_num in range(1, Game.MAX_WHEELS + 1):
		var t = float(wheel_num - 1) / float(Game.MAX_WHEELS - 1)
		var angle = lerp(start_angle, end_angle, t)
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		var unlocked = Game.is_wheel_unlocked(wheel_num)
		var selected = wheel_num == Game.selected_wheel
		var color = Color(0.32, 0.18, 0.12, 0.85)
		if unlocked:
			color = Color(0.95, 0.42, 0.12, 0.95)
		if selected:
			color = Color(1.0, 0.86, 0.26, 1.0)
		draw_circle(pos, 11.0 if selected else 6.2, Color(0.05, 0.015, 0.012, 0.82))
		draw_circle(pos, 8.0 if selected else 4.8, color)
		draw_circle(pos, 3.7 if selected else 2.1, Color(1.0, 0.96, 0.72, 0.82) if unlocked else Color(0.08, 0.035, 0.03, 0.65))
		if selected:
			draw_arc(pos, 13.0, 0.0, TAU, 32, Color(0.35, 1.0, 0.72, 0.9), 2.0)
