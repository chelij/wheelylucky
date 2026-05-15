# scripts/end_screen.gd
extends CanvasLayer

const SoundFactory = preload("res://scripts/sound_factory.gd")

@onready var title_label: Label = $CenterContainer/EndPanel/EndVBox/TitleLabel
@onready var final_coins_label: Label = $CenterContainer/EndPanel/EndVBox/FinalCoinsLabel
@onready var stats_label: Label = $CenterContainer/EndPanel/EndVBox/StatsLabel
@onready var rating_label: Label = $CenterContainer/EndPanel/EndVBox/RatingLabel
@onready var restart_button: Button = $CenterContainer/EndPanel/EndVBox/RestartButton
@onready var jackpot_sound: AudioStreamPlayer = $JackpotSound

func _ready():
	jackpot_sound.stream = SoundFactory.make_tone(1200.0, 0.55)
	jackpot_sound.play()
	final_coins_label.text = "Final Score: " + str(Game.coins) + " coins"

	var skill_count = Game.unique_skills.size()
	var level_sum = 0
	for val in Game.skill_levels.values():
		level_sum += val
	stats_label.text = "Spins: " + str(Game.total_spins) + \
		" | Cycles: " + str(Game.cycle_count) + \
		" | Skills: " + str(skill_count) + " unique, " + str(level_sum) + " upgrades"

	var rating = calculate_rating(Game.coins)
	rating_label.text = ""
	for i in range(rating):
		rating_label.text += "⭐"

	restart_button.pressed.connect(_on_restart)

func calculate_rating(coins: int) -> int:
	if coins >= 500: return 5
	if coins >= 200: return 4
	if coins >= 100: return 3
	if coins >= 50: return 2
	return 1

func _on_restart():
	Game.reset_run()
	queue_free()
