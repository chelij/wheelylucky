# scripts/save_manager.gd
extends Node

const SAVE_PATH = "user://wheelylucky_save.cfg"
var config: ConfigFile

const DEFAULT_SETTINGS := {
	"window_mode": "windowed",
	"resolution": "1280x720",
	"music_volume": 0.65,
	"sfx_volume": 0.8,
	"reduced_motion": false,
	"muted_flashes": false,
	"large_ui_text": false,
	"tutorial_sign_seen": false,
}

const COLOR_KEYS := ["green", "red", "gold", "purple", "grey", "jackpot"]
const MAX_RUN_HISTORY := 12

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

func get_games_started() -> int:
	return config.get_value("stats", "games_started", 0)

func increment_games_started() -> void:
	config.set_value("stats", "games_started", get_games_started() + 1)
	_save()

func get_games_won() -> int:
	return config.get_value("stats", "games_won", 0)

func increment_games_won() -> void:
	config.set_value("stats", "games_won", get_games_won() + 1)
	config.set_value("game", "games_played", get_games_won())
	_save()

func get_total_spins() -> int:
	return config.get_value("stats", "total_spins", 0)

func add_spin(color_key: String) -> void:
	config.set_value("stats", "total_spins", get_total_spins() + 1)
	var counts := get_color_counts()
	counts[color_key] = int(counts.get(color_key, 0)) + 1
	config.set_value("stats", "color_counts", counts)
	_save()

func get_color_counts() -> Dictionary:
	var counts: Dictionary = config.get_value("stats", "color_counts", {})
	for color_key in COLOR_KEYS:
		if not counts.has(color_key):
			counts[color_key] = 0
	return counts

func add_skill_level(skill_id: String) -> void:
	var levels := get_skill_level_totals()
	levels[skill_id] = int(levels.get(skill_id, 0)) + 1
	config.set_value("stats", "skill_level_totals", levels)
	_save()

func get_skill_level_totals() -> Dictionary:
	return config.get_value("stats", "skill_level_totals", {})

func get_setting(key: String):
	return config.get_value("settings", key, DEFAULT_SETTINGS.get(key))

func set_setting(key: String, value) -> void:
	config.set_value("settings", key, value)
	_save()

func get_all_settings() -> Dictionary:
	var settings := {}
	for key in DEFAULT_SETTINGS.keys():
		settings[key] = get_setting(key)
	return settings

func add_run_history(entry: Dictionary) -> void:
	var history := get_run_history()
	history.push_front(entry)
	while history.size() > MAX_RUN_HISTORY:
		history.pop_back()
	config.set_value("history", "runs", history)
	_save()

func get_run_history() -> Array:
	var raw = config.get_value("history", "runs", [])
	var history: Array = []
	for item in raw:
		if item is Dictionary:
			history.append(item)
	return history

func has_saved_run() -> bool:
	return config.get_value("run", "active", false)

func save_run(state: Dictionary) -> void:
	config.set_value("run", "active", true)
	for key in state.keys():
		config.set_value("run", key, state[key])
	_save()

func load_run() -> Dictionary:
	if not has_saved_run():
		return {}
	var state := {}
	for key in config.get_section_keys("run"):
		if key != "active":
			state[key] = config.get_value("run", key)
	return state

func clear_saved_run() -> void:
	if not config.has_section("run"):
		return
	config.erase_section("run")
	_save()
