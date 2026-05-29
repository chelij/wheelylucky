# scripts/wheel.gd
extends Control

signal spin_finished(outcome)
signal spin_started(cost)
signal shop_requested
signal near_jackpot_tension(is_jackpot_target)

const WheelConfig = preload("res://scripts/wheel_config.gd")
const SkillEffects = preload("res://scripts/skill_effects.gd")
const UiFormat = preload("res://scripts/ui_format.gd")

@onready var wheel_shell: TextureRect = $WheelShell
@onready var center_medallion: TextureRect = $CenterMedallion

@export_group("Wheel Dimensions")
# Pixel margin from the edge of the shell texture inward to where sections end.
# Accounts for decorative borders on the wheel-shell image.
@export var shell_border_margin: float = 96.0
# Pixel margin added to the medallion texture radius for the inner cutout.
@export var hub_inner_margin: float = 0.0
# Pixel distance from section edge to the progress arc.
@export var arc_offset_pixels: float = 14.0

# Fallback colors when textures are not set on scene nodes
var fallback_shell_color: Color = Color(0.18, 0.035, 0.035, 0.98)
var fallback_medallion_color: Color = Color(0.12, 0.035, 0.07, 1.0)

@export_group("Wheel Palette")
@export var shell_outer_fill_color: Color = Color(0.18, 0.035, 0.035, 0.98)
@export var shell_outer_gold_color: Color = Color(1.0, 0.75, 0.18, 0.88)
@export var shell_outer_accent_color: Color = Color(0.9, 0.16, 0.04, 0.9)
@export var separator_color: Color = Color(1.0, 0.82, 0.24, 0.92)
@export var shell_mid_dark_color: Color = Color(0.35, 0.08, 0.04, 1.0)
@export var shell_mid_gold_color: Color = Color(1.0, 0.82, 0.24, 1.0)
@export var shell_mid_highlight_color: Color = Color(1.0, 0.95, 0.48, 1.0)
@export var shell_inner_stroke_color: Color = Color(0.45, 0.21, 0.02, 1.0)
@export var progress_dark_color: Color = Color(0.12, 0.03, 0.025, 1.0)
@export var progress_gold_color: Color = Color(1.0, 0.76, 0.18, 1.0)
@export var progress_accent_color: Color = Color(0.88, 0.18, 0.04, 0.95)
@export var progress_highlight_color: Color = Color(1.0, 0.92, 0.42, 0.75)
@export var fallback_medallion_fill_color: Color = Color(0.12, 0.035, 0.07, 0.92)
@export var label_shadow_color: Color = Color(0.05, 0.015, 0.01, 0.82)
@export var label_text_color: Color = Color(1.0, 0.98, 0.9, 0.98)


@onready var wheel_number_label: Label = $WheelNumber
@onready var cost_label: Label = $CostDisplay
@onready var coins_label: Label = $CoinsDisplay

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
var pointer_base_angle_degrees: float = 0.0
var shop_offer_available: bool = false
var shop_pulse_time: float = 0.0
var rng := RandomNumberGenerator.new()

# Cached for consistent drawing during spin
var cached_outcomes: Array = []
var cached_slots: Array = []
var cached_section_tris: Array[Dictionary] = []
var cached_section_edges: Array[float] = []
var cached_label_layouts: Array[Dictionary] = []
var w10_tension_emitted: bool = false
var w10_tension_active: bool = false
var spin_locked: bool = false
var cached_jackpot_index: int = -1

func _ready():
	rng.randomize()
	pointer_arrow.pivot_offset = pointer_arrow.size / 2.0
	pointer_default_position = pointer_arrow.position
	pointer_default_rotation = pointer_arrow.rotation_degrees
	# Derive the pointer's base angle from its visual position relative to wheel center.
	_recompute_pointer_base_angle()
	_update_pointer_visual()
	_style_arrow_buttons()
	_style_shop_button()
	Game.coins_changed.connect(_on_coins_changed)
	Game.selected_wheel_changed.connect(_on_wheel_changed)
	Game.skills_changed.connect(_on_skills_changed)

	prev_wheel_button.pressed.connect(_on_prev_wheel_pressed)
	next_wheel_button.pressed.connect(_on_next_wheel_pressed)
	shop_button.pressed.connect(_on_shop_button_pressed)

	_on_wheel_changed(Game.selected_wheel)
	_on_coins_changed(Game.coins)
	_refresh_outcomes()
	_update_pointer_indicator()
	queue_redraw()
	# Rebuild geometry cache after layout so node sizes are known.
	call_deferred("_rebuild_wheel_geometry_cache")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_recompute_pointer_base_angle()

func _recompute_pointer_base_angle() -> void:
	if pointer_arrow == null:
		return
	var p_center = pointer_arrow.position + pointer_arrow.size / 2.0
	pointer_base_angle_degrees = rad_to_deg(atan2(p_center.y - size.y * 0.5, p_center.x - size.x * 0.5))

func _refresh_outcomes():
	cached_outcomes = WheelConfig.get_outcomes(Game.selected_wheel)
	cached_outcomes = WheelConfig.apply_skill_modifiers(cached_outcomes, Game, Game.selected_wheel)
	cached_outcomes = WheelConfig.apply_display_modifiers(cached_outcomes, Game)
	cached_slots = []
	cached_jackpot_index = -1
	for index in range(cached_outcomes.size()):
		var outcome = cached_outcomes[index]
		for _i in range(int(outcome[WheelConfig.IDX_SLOTS])):
			cached_slots.append(outcome)
		# Cache jackpot index for O(1) lookup during spin.
		if str(outcome[WheelConfig.IDX_LABEL]) == "JACKPOT":
			cached_jackpot_index = index
	if "randomizer" in Game.unique_skills:
		# Randomizer shuffles individual slot positions on the wheel while preserving total odds.
		cached_slots.shuffle()
	if wheel_shell != null:
		_rebuild_wheel_geometry_cache()

func _rebuild_wheel_geometry_cache() -> void:
	cached_section_tris.clear()
	cached_section_edges.clear()
	cached_label_layouts.clear()

	if cached_slots.is_empty():
		return

	var outer_radius := _get_outer_radius()
	var hub_radius := _get_hub_radius()
	var slot_angle := TAU / float(cached_slots.size())
	var sections := _build_label_sections(cached_slots)

	for slot_index in range(cached_slots.size()):
		var outcome = cached_slots[slot_index]
		var start_angle := float(slot_index) * slot_angle
		var end_angle := start_angle + slot_angle
		var arc_pts: Array[Vector2] = []
		for j in range(9):
			var t = float(j) / 8.0
			var angle = start_angle + (end_angle - start_angle) * t
			arc_pts.append(Vector2(cos(angle), sin(angle)))
		var segment_color: Color = outcome[WheelConfig.IDX_COLOR].lightened(0.12)
		segment_color.a = 1.0
		# Build ring quads split into 2 triangles each — no center fill.
		for j in range(8):
			var inner_j = arc_pts[j] * hub_radius
			var inner_j1 = arc_pts[j + 1] * hub_radius
			var outer_j = arc_pts[j] * outer_radius
			var outer_j1 = arc_pts[j + 1] * outer_radius
			cached_section_tris.append({"a": inner_j, "b": outer_j1, "c": outer_j, "color": segment_color})
			cached_section_tris.append({"a": inner_j, "b": inner_j1, "c": outer_j1, "color": segment_color})

		var next_outcome = cached_slots[(slot_index + 1) % cached_slots.size()]
		if next_outcome != outcome:
			cached_section_edges.append(end_angle)

	for section in sections:
		var start_index := int(section["start"])
		var slot_count := int(section["count"])
		var outcome: Array = section["outcome"]
		var sweep := slot_angle * float(slot_count)
		var mid_angle := (float(start_index) + float(slot_count) * 0.5) * slot_angle
		var radius := hub_radius + (outer_radius - hub_radius) * 0.6
		var tangent := mid_angle + PI * 0.5
		if cos(mid_angle) < 0.0:
			tangent += PI

		var value := _segment_label_value(outcome)
		var value_size: int = clamp(int(round(16.0 + float(slot_count) * 0.24)), 11, 28)
		if sweep < 0.18:
			value = _segment_micro_label(outcome)
			value_size = min(value_size, 10)
		elif sweep < 0.34:
			value_size = min(value_size, 13)

		cached_label_layouts.append({
			"mid_angle": mid_angle,
			"radius": radius,
			"tangent": tangent,
			"value": value,
			"font_size": value_size,
		})

func _process(delta):
	if is_spinning:
		var elapsed = Time.get_ticks_msec() / 1000.0 - spin_start_time
		var duration = get_effective_spin_duration()
		var progress = min(elapsed / duration, 1.0)
		if Game.selected_wheel == Game.MAX_WHEELS and progress >= 0.72 and is_pointer_near_jackpot(8):
			w10_tension_active = true
			if not w10_tension_emitted:
				w10_tension_emitted = true
				var near_outcome = get_pointer_outcome()
				near_jackpot_tension.emit(near_outcome != null and str(near_outcome[WheelConfig.IDX_LABEL]) == "JACKPOT")

		# Fast launch with a longer slow tail, while keeping the same total duration.
		var eased = _get_spin_eased_progress(progress)
		current_rotation = spin_start_rotation + target_rotation * eased
		if "double_spin" in Game.unique_skills:
			pointer_current_rotation = pointer_start_rotation + pointer_target_rotation * eased
		_update_pointer_visual()
		_update_pointer_indicator()
		queue_redraw()

		if progress >= 1.0:
			is_spinning = false
			current_rotation = fposmod(spin_start_rotation + target_rotation, 360.0)
			if "double_spin" in Game.unique_skills:
				pointer_current_rotation = fposmod(pointer_start_rotation + pointer_target_rotation, 360.0)
			_update_pointer_visual()
			_apply_fortunes_favor_spin_push()
			_update_pointer_indicator()
			_update_shop_button()
			spin_finished.emit(get_pointer_outcome())
	elif shop_offer_available and shop_button.visible:
		shop_pulse_time += delta
		var pulse := 1.0 + 0.08 * (0.5 + 0.5 * sin(shop_pulse_time * 4.6))
		shop_button.scale = Vector2(pulse, pulse)
		var tint := 0.82 + 0.18 * (0.5 + 0.5 * sin(shop_pulse_time * 5.2))
		shop_button.modulate = Color(1.0, tint, 0.78, 1.0)
	else:
		shop_button.scale = Vector2.ONE
		shop_button.modulate = Color.WHITE

func _get_spin_eased_progress(progress: float) -> float:
	var eased := 1.0 - pow(1.0 - progress, 7)
	if not w10_tension_active:
		return eased
	var tension_start := 0.72
	if progress <= tension_start:
		return eased
	var start_eased := 1.0 - pow(1.0 - tension_start, 7)
	var late_progress: float = clamp((progress - tension_start) / (1.0 - tension_start), 0.0, 1.0)
	return lerp(start_eased, 1.0, 1.0 - pow(1.0 - late_progress, 2.0))

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

func _on_prev_wheel_pressed() -> void:
	if _is_busy():
		return
	for wheel_num in range(Game.selected_wheel - 1, 0, -1):
		if Game.is_wheel_unlocked(wheel_num):
			Game.select_wheel(wheel_num)
			return

func _on_next_wheel_pressed() -> void:
	if _is_busy():
		return
	for wheel_num in range(Game.selected_wheel + 1, Game.MAX_WHEELS + 1):
		if Game.is_wheel_unlocked(wheel_num):
			Game.select_wheel(wheel_num)
			return

func _on_shop_button_pressed() -> void:
	if _is_busy() or not shop_offer_available:
		return
	shop_requested.emit()

func set_shop_available(is_available: bool) -> void:
	shop_offer_available = is_available
	_update_shop_button()

func _update_shop_button() -> void:
	if shop_button == null:
		return
	var should_show = shop_offer_available and not _is_busy()
	shop_button.visible = should_show
	shop_button.disabled = not should_show
	if not should_show:
		shop_pulse_time = 0.0
		shop_button.scale = Vector2.ONE
		shop_button.modulate = Color.WHITE

func set_all_buttons_visible(is_visible: bool) -> void:
	if is_visible:
		_update_wheel_arrow_buttons()
	else:
		prev_wheel_button.visible = false
		next_wheel_button.visible = false
	shop_button.visible = is_visible and shop_offer_available

func start_spin():
	if not can_start_spin():
		return
	var payment = Game.begin_spin()
	if not payment.get("success", false):
		return

	_refresh_outcomes()
	w10_tension_emitted = false
	w10_tension_active = false
	if _should_resolve_risk_taker_w1_now():
		spin_started.emit(int(payment.get("cost", 0)))
		spin_finished.emit(_get_risk_taker_w1_plus_outcome())
		return

	is_spinning = true
	set_all_buttons_visible(false)
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
	if _is_busy():
		return
	var payment = Game.begin_spin()
	if not payment.get("success", false):
		return

	spin_started.emit(int(payment.get("cost", 0)))
	_refresh_outcomes()
	w10_tension_emitted = false
	w10_tension_active = false
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
		if outcome[WheelConfig.IDX_OP] == WheelConfig.OP_ADD:
			return outcome
	return cached_outcomes[0] if cached_outcomes.size() > 0 else null

func _apply_fortunes_favor_spin_push() -> void:
	if "fortunes_favor" not in Game.unique_skills:
		return
	var outcome = get_pointer_outcome()
	if outcome == null:
		return
	if outcome[WheelConfig.IDX_OP] == WheelConfig.OP_SUBTRACT:
		var slot_degrees = 360.0 / float(cached_slots.size())
		current_rotation += slot_degrees * SkillEffects.FORTUNES_FAVOR_PUSH_SLOTS
		queue_redraw()

func get_pointer_outcome():
	# Cache must be populated by _refresh_outcomes() at controlled entry points.
	# Lazy-initializing here would mutate outcome data at unexpected times.
	if cached_slots.size() == 0:
		return null

	var slot_index = _get_pointer_slot_index()
	return cached_slots[slot_index]

func _refresh_wheel_hub() -> void:
	wheel_number_label.text = "◎ " + str(Game.selected_wheel) + " / 10"
	var cost = Game.get_wheel_cost(Game.selected_wheel)
	cost_label.text = "◆ FREE" if cost == 0 else "◆ " + str(cost)
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
	var locked = _is_busy() or not Game.can_afford_wheel(Game.selected_wheel)
	var has_prev = Game.selected_wheel > 1
	for wheel_num in range(Game.selected_wheel - 1, 0, -1):
		if Game.is_wheel_unlocked(wheel_num):
			has_prev = true
			break
	prev_wheel_button.visible = has_prev and not locked
	prev_wheel_button.disabled = false

	var has_next = false
	for wheel_num in range(Game.selected_wheel + 1, Game.MAX_WHEELS + 1):
		if Game.is_wheel_unlocked(wheel_num):
			has_next = true
			break
	next_wheel_button.visible = has_next and not locked
	next_wheel_button.disabled = false

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

func set_spin_locked(is_locked: bool) -> void:
	spin_locked = is_locked
	_refresh_wheel_hub()

func can_start_spin() -> bool:
	return not _is_busy() and Game.can_afford_wheel(Game.selected_wheel)

func _is_busy() -> bool:
	return is_spinning or spin_locked

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
	var spin_offset = _get_pointer_angle_degrees()
	var angle = deg_to_rad(pointer_base_angle_degrees + spin_offset)
	var pointer_center = center + Vector2(cos(angle), sin(angle)) * orbit_radius
	pointer_arrow.position = pointer_center - pointer_size / 2.0
	pointer_arrow.rotation_degrees = pointer_base_angle_degrees + spin_offset + pointer_default_rotation

func _get_pointer_angle_degrees() -> float:
	return pointer_current_rotation if "double_spin" in Game.unique_skills else 0.0

func _update_pointer_indicator() -> void:
	if pointer_indicator == null:
		return
	var outcome = get_pointer_outcome()
	if outcome == null:
		pointer_indicator.modulate = Color(1.0, 0.82, 0.24, 1.0)
		return
	pointer_indicator.modulate = outcome[WheelConfig.IDX_COLOR].lightened(0.18)

func _get_pointer_slot_index() -> int:
	if cached_slots.size() == 0:
		return 0
	# Pointer angle = base visual angle + double_spin offset - wheel rotation.
	var pointer_angle = fposmod(pointer_base_angle_degrees + _get_pointer_angle_degrees() - current_rotation, 360.0)
	var slot_degrees = 360.0 / float(cached_slots.size())
	return int(floor(pointer_angle / slot_degrees)) % cached_slots.size()

func is_pointer_near_jackpot(radius_slots: int = 8) -> bool:
	if cached_slots.size() == 0 or cached_jackpot_index < 0:
		return false
	var pointer_index := _get_pointer_slot_index()
	var distance: int = abs(pointer_index - cached_jackpot_index)
	var wrapped_distance: int = min(distance, cached_slots.size() - distance)
	return wrapped_distance <= max(1, radius_slots)

func _draw():
	if cached_slots.size() == 0:
		_refresh_outcomes()

	var center = size / 2.0
	var outer_radius := _get_outer_radius()
	var hub_radius := _get_hub_radius()

	if cached_slots.size() == 0 or outer_radius <= 0:
		return

	var rotation_rad = deg_to_rad(current_rotation)

	_draw_alpha_gradient_shadow(center, outer_radius + 10.0, 28.0, 0.13, 10, Vector2(0, 4))
	# WheelShell texture drawn by the scene node ($WheelShell).
	if wheel_shell == null or wheel_shell.texture == null:
		draw_set_transform(center, rotation_rad, Vector2.ONE)
		draw_circle(Vector2.ZERO, outer_radius + 26.0, shell_outer_fill_color)
		draw_arc(Vector2.ZERO, outer_radius + 31.0, 0.0, TAU, 180, shell_outer_gold_color, 5.0)
		draw_arc(Vector2.ZERO, outer_radius + 18.0, 0.0, TAU, 180, shell_outer_accent_color, 4.0)
	draw_set_transform(center, rotation_rad, Vector2.ONE)
	for tri_data in cached_section_tris:
		var pts := PackedVector2Array([tri_data["a"], tri_data["b"], tri_data["c"]])
		var c = tri_data["color"]
		var cols := PackedColorArray([c, c, c])
		draw_primitive(pts, cols, PackedVector2Array())
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for edge_angle_base in cached_section_edges:
		var edge_angle: float = rotation_rad + float(edge_angle_base)
		if _is_pointer_side_edge(fposmod(edge_angle, TAU)):
			continue
		draw_line(center + Vector2(cos(edge_angle), sin(edge_angle)) * hub_radius, center + Vector2(cos(edge_angle), sin(edge_angle)) * outer_radius, separator_color, 1.0, true)

	if wheel_shell == null or wheel_shell.texture == null:
		draw_arc(center, outer_radius + 10.0, 0.0, TAU, 160, shell_mid_dark_color, 22.0)
		draw_arc(center, outer_radius + 14.0, 0.0, TAU, 160, shell_mid_gold_color, 5.0)
		draw_arc(center, outer_radius + 2.0, 0.0, TAU, 160, shell_mid_highlight_color, 4.0)
		_draw_alpha_gradient_arc_shadow(center, outer_radius - 3.0, 18.0, 0.14, 8, 10.0)
		draw_arc(center, outer_radius, 0.0, TAU, 160, shell_inner_stroke_color, 2.2)
	_draw_segment_labels(center, rotation_rad)
	_draw_wheel_progress()

func _get_texture_size(texture: Texture2D) -> Vector2:
	# AtlasTexture stores the cropped region in its size property.
	if texture is AtlasTexture:
		return texture.region.size
	return texture.get_size()

func _get_rendered_radius(node: TextureRect) -> float:
	if node == null or node.texture == null:
		return 0.0
	var tex_size: Vector2 = _get_texture_size(node.texture)
	# With STRETCH_KEEP_ASPECT_CENTERED the texture fits inside the node
	# maintaining aspect ratio (contain). Scale = min(w_ratio, h_ratio).
	if node.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and node.size.x > 0:
		var w_ratio: float = node.size.x / tex_size.x
		var h_ratio: float = node.size.y / tex_size.y
		var scale: float = min(w_ratio, h_ratio)
		return tex_size.x * scale * 0.5
	# STRETCH_SCALE — texture stretches to fill node
	if node.stretch_mode == TextureRect.STRETCH_SCALE and node.size.x > 0:
		return min(node.size.x, node.size.y) * 0.5
	# Default: use the actual image pixel size
	return min(tex_size.x, tex_size.y) * 0.5

func _get_outer_radius() -> float:
	var r: float = _get_rendered_radius(wheel_shell)
	if r > 0:
		return max(1.0, r - shell_border_margin)
	return size.x * 0.25  # Fallback

func _get_hub_radius() -> float:
	var r: float = _get_rendered_radius(center_medallion)
	if r > 0:
		return max(1.0, r + hub_inner_margin)
	return size.x * 0.1  # Fallback

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

func _draw_segment_labels(center: Vector2, rotation_rad: float) -> void:
	if cached_label_layouts.is_empty():
		return
	var font := ThemeDB.fallback_font
	if font == null:
		return
	for layout in cached_label_layouts:
		var mid_angle := rotation_rad + float(layout["mid_angle"])
		var radius := float(layout["radius"])
		var center_pos := center + Vector2(cos(mid_angle), sin(mid_angle)) * radius
		var tangent := rotation_rad + float(layout["tangent"])
		draw_set_transform(center_pos, tangent, Vector2.ONE)
		_draw_segment_text_line(font, str(layout["value"]), int(layout["font_size"]), 0.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_segment_text_line(font: Font, text: String, font_size: int, y_offset: float) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var origin := Vector2(-width * 0.5, y_offset)
	draw_string(font, origin + Vector2(2.0, 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, label_shadow_color)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, label_text_color)

func _build_label_sections(wheel_slots: Array) -> Array:
	var sections: Array = []
	var start_index := 0
	var current = wheel_slots[0]
	for index in range(1, wheel_slots.size() + 1):
		var at_end := index == wheel_slots.size()
		var next_outcome = null if at_end else wheel_slots[index]
		if at_end or next_outcome != current:
			sections.append({
				"start": start_index,
				"count": index - start_index,
				"outcome": current,
			})
			if not at_end:
				start_index = index
				current = next_outcome
	return sections

func _segment_label_value(outcome: Array) -> String:
	var label := str(outcome[WheelConfig.IDX_LABEL])
	if label == "JACKPOT":
		return "x10"
	if label == "0":
		return "0"
	var prefix := label.substr(0, 1)
	if prefix in ["+", "-", "x", "/"]:
		return prefix + UiFormat.compact_number(int(round(label.substr(1).replace(",", "").to_float())))
	return label

func _segment_micro_label(outcome: Array) -> String:
	return _segment_label_value(outcome)

func _draw_wheel_progress() -> void:
	var center = size / 2.0
	var outer_radius := _get_outer_radius()
	var radius = outer_radius + arc_offset_pixels
	var start_angle = deg_to_rad(220.0)
	var end_angle = deg_to_rad(320.0)
	draw_arc(center, radius + 4.0, start_angle, end_angle, 84, progress_dark_color, 20.0, true)
	draw_arc(center, radius + 4.0, start_angle, end_angle, 84, progress_dark_color, 12.0, true)
	draw_arc(center, radius + 8.0, start_angle, end_angle, 84, progress_gold_color, 3.0, true)
	##draw_arc(center, radius - 2.0, start_angle, end_angle, 84, progress_accent_color, 1.0, true)
	draw_arc(center, radius - 10.0, start_angle, end_angle, 84, progress_highlight_color, 1.4, true)

	for wheel_num in range(1, Game.MAX_WHEELS + 1):
		var t = float(wheel_num - 1) / float(Game.MAX_WHEELS - 1)
		var angle = lerp(start_angle, end_angle, t)
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		var unlocked = Game.is_wheel_unlocked(wheel_num)
		var selected = wheel_num == Game.selected_wheel
		var color = Color(0.32, 0.18, 0.12, 1.0)
		if unlocked:
			color = Color(0.95, 0.42, 0.12, 1.0)
		if selected:
			color = Color(1.0, 0.86, 0.26, 1.0)
		draw_circle(pos, 11.0 if selected else 6.2, Color(0.05, 0.015, 0.012, 1.0))
		draw_circle(pos, 8.0 if selected else 4.8, color)
		draw_circle(pos, 3.7 if selected else 2.1, Color(1.0, 0.96, 0.72, 1.0) if unlocked else Color(0.08, 0.035, 0.03, 1.0))
		if selected:
			draw_arc(pos, 13.0, 0.0, TAU, 32, Color(0.35, 1.0, 0.72, 1.0), 2.0)
