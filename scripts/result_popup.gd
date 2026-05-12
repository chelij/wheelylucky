# scripts/result_popup.gd
extends CanvasLayer

@export var result_label: Label
@export var total_label: Label

func show_result(delta: int, outcome_color: Color):
	if delta > 0:
		result_label.text = "+" + str(delta)
	elif delta < 0:
		result_label.text = str(delta)
	else:
		result_label.text = "\u2014"

	result_label.add_theme_color_override("font_color", outcome_color)
	total_label.text = "Total: " + str(Game.coins)

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1.2)
	tween.tween_callback(queue_free)
