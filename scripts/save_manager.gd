# scripts/save_manager.gd
extends Node

const SAVE_PATH = "user://wheelylucky_save.cfg"
var config: ConfigFile

func _ready():
	config = ConfigFile.new()
	_load()

func _save():
	if config != null:
		config.save(SAVE_PATH)

func _load():
	if config == null:
		config = ConfigFile.new()
	config.load(SAVE_PATH)

func get_best_score() -> int:
	return config.get_value("game", "best_score", 0)

func set_best_score(score: int):
	var current = get_best_score()
	if score > current:
		config.set_value("game", "best_score", score)
		_save()

func get_games_played() -> int:
	return config.get_value("game", "games_played", 0)

func increment_games_played():
	config.set_value("game", "games_played", get_games_played() + 1)
	_save()
