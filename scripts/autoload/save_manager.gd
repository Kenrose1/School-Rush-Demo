## Persists settings and best-run records to user://save.cfg (GDD Section X: Test Plan).
extends Node

signal settings_changed

var music_volume: float = 0.8
var sfx_volume: float = 0.9
var screen_shake: bool = true
var fullscreen: bool = false
var tutorial_seen: bool = false

var best_score_standard: int = 0
var best_score_continuous: int = 0
var best_score_training: int = 0
var best_distance_continuous: float = 0.0
var runs_played: int = 0
var shop_points: int = 0
var shop_levels: Dictionary = {
	"speed": 0,
	"recovery": 0,
	"dash": 0,
	"score": 0,
}


func _ready() -> void:
	load_config()
	apply_window_mode()


func load_config() -> void:
	var config := ConfigFile.new()
	if config.load(GameConfig.SAVE_PATH) != OK:
		return
	music_volume = clampf(float(config.get_value("audio", "music", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx", sfx_volume)), 0.0, 1.0)
	screen_shake = bool(config.get_value("video", "screen_shake", screen_shake))
	fullscreen = bool(config.get_value("video", "fullscreen", fullscreen))
	tutorial_seen = bool(config.get_value("progress", "tutorial_seen", tutorial_seen))
	best_score_standard = int(config.get_value("records", "standard", best_score_standard))
	best_score_continuous = int(config.get_value("records", "continuous", best_score_continuous))
	best_score_training = int(config.get_value("records", "training", best_score_training))
	best_distance_continuous = float(config.get_value("records", "continuous_distance", best_distance_continuous))
	runs_played = int(config.get_value("records", "runs", runs_played))
	shop_points = maxi(0, int(config.get_value("shop", "points", shop_points)))
	for upgrade in GameConfig.SHOP_UPGRADES:
		shop_levels[upgrade] = clampi(int(config.get_value("shop", upgrade, shop_levels.get(upgrade, 0))), 0, GameConfig.SHOP_MAX_LEVEL)


func save_config() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("video", "screen_shake", screen_shake)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("progress", "tutorial_seen", tutorial_seen)
	config.set_value("records", "standard", best_score_standard)
	config.set_value("records", "continuous", best_score_continuous)
	config.set_value("records", "training", best_score_training)
	config.set_value("records", "continuous_distance", best_distance_continuous)
	config.set_value("records", "runs", runs_played)
	config.set_value("shop", "points", shop_points)
	for upgrade in GameConfig.SHOP_UPGRADES:
		config.set_value("shop", upgrade, get_shop_level(upgrade))
	var err := config.save(GameConfig.SAVE_PATH)
	if err != OK:
		push_warning("Could not write %s (error %d)" % [GameConfig.SAVE_PATH, err])
	settings_changed.emit()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	AudioDirector.apply_volumes()
	save_config()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	AudioDirector.apply_volumes()
	save_config()


func set_screen_shake(enabled: bool) -> void:
	screen_shake = enabled
	save_config()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	apply_window_mode()
	save_config()


func apply_window_mode() -> void:
	if not DisplayServer.get_name() == "headless":
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		)


func best_score_for(mode: int) -> int:
	match mode:
		GameConfig.Mode.STANDARD:
			return best_score_standard
		GameConfig.Mode.CONTINUOUS:
			return best_score_continuous
		_:
			return best_score_training


func get_shop_level(upgrade: String) -> int:
	return clampi(int(shop_levels.get(upgrade, 0)), 0, GameConfig.SHOP_MAX_LEVEL)


func get_shop_cost(upgrade: String) -> int:
	return GameConfig.shop_cost(get_shop_level(upgrade))


func purchase_upgrade(upgrade: String) -> bool:
	if not GameConfig.SHOP_UPGRADES.has(upgrade):
		return false
	var level := get_shop_level(upgrade)
	var cost := GameConfig.shop_cost(level)
	if level >= GameConfig.SHOP_MAX_LEVEL or shop_points < cost:
		return false
	shop_points -= cost
	shop_levels[upgrade] = level + 1
	save_config()
	return true


func add_shop_points(amount: int) -> void:
	shop_points = maxi(0, shop_points + maxi(0, amount))
	save_config()


func shop_speed_bonus() -> float:
	return float(get_shop_level("speed")) * 25.0


func shop_hit_speed_multiplier() -> float:
	return minf(0.9, GameConfig.HIT_SPEED_MULT + float(get_shop_level("recovery")) * 0.05)


func shop_dash_cooldown() -> float:
	return maxf(4.0, GameConfig.DASH_COOLDOWN - float(get_shop_level("dash")) * 0.6)


func shop_score_multiplier() -> float:
	return 1.0 + float(get_shop_level("score")) * 0.1


## Returns true when this run set a new personal record.
func record_run(mode: int, score: int, distance_m: float) -> bool:
	runs_played += 1
	var is_best := false
	match mode:
		GameConfig.Mode.STANDARD:
			if score > best_score_standard:
				best_score_standard = score
				is_best = true
		GameConfig.Mode.CONTINUOUS:
			if score > best_score_continuous:
				best_score_continuous = score
				is_best = true
			best_distance_continuous = maxf(best_distance_continuous, distance_m)
		GameConfig.Mode.TRAINING:
			if score > best_score_training:
				best_score_training = score
				is_best = true
	save_config()
	return is_best


func reset_records() -> void:
	best_score_standard = 0
	best_score_continuous = 0
	best_score_training = 0
	best_distance_continuous = 0.0
	shop_points = 0
	for upgrade in GameConfig.SHOP_UPGRADES:
		shop_levels[upgrade] = 0
	tutorial_seen = false
	save_config()
