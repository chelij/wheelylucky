# scripts/result_popup.gd
extends CanvasLayer

signal closed

@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var total_label: Label = $VBoxContainer/TotalLabel

func show_result(delta: int, outcome_color: Color):
	if delta > 0:
		result_label.text = "+" + str(delta)
	elif delta < 0:
		result_label.text = str(delta)
	else:
		result_label.text = "—"

	result_label.add_theme_color_override("font_color", outcome_color)
	total_label.text = "Total: " + str(Game.coins)

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
tween.tween_property(self, "self_modulate", Color(1, 1, 1, 0), 1.2)
	tween.tween_callback(_on_fade_done)

func _on_fade_done():
	closed.emit()
	queue_free()
