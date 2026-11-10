extends Node
class_name SaveManager

signal save_completed(success: bool)
signal load_completed(success: bool)

@onready var game_data: GameData = GameData.new()

const SAVE_PATH = "user://save.dat"
const SETTINGS_PATH = "user://settings.dat"

var save_data: Dictionary = {}
var settings_data: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.7,
	"sfx_volume": 0.8,
	"show_fps": false,
	"auto_save": true,
	"game_speed": 1.0,
	"notifications": true,
	"reduced_motion": false,
	"high_contrast": false,
}

func _ready() -> void:
	load_settings()
	load_game()


func load_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		load_completed.emit(false)
		return

	var json_str = file.get_as_text()
	file.close()

	var parse_result = JSON.parse_string(json_str)
	if parse_result.error != OK:
		push_error("Save parse error: " + parse_result.error_string)
		load_completed.emit(false)
		return

	save_data = parse_result
	_load_version_migration()
	load_completed.emit(true)


func _load_version_migration() -> void:
	var version = save_data.get("version", 0)
	if version < game_data.save_version:
		# Migration logic here for future versions
		save_data["version"] = game_data.save_version
		save_game()


func save_game() -> void:
	save_data["version"] = game_data.save_version
	save_data["timestamp"] = Time.get_unix_time_from_datetime(Time.get_datetime_now())

	var json_str = JSON.stringify(save_data)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("Failed to open save file for writing")
		save_completed.emit(false)
		return

	file.store_string(json_str)
	file.close()
	save_completed.emit(true)


func save_settings() -> void:
	var json_str = JSON.stringify(settings_data)
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if not file:
		push_error("Failed to open settings file for writing")
		return
	file.store_string(json_str)
	file.close()


func load_settings() -> void:
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		return
	var json_str = file.get_as_text()
	file.close()

	var parse_result = JSON.parse_string(json_str)
	if parse_result.error == OK:
		settings_data = parse_result


# --- Data Access Helpers ---

func get(key: String, default=null) -> Variant:
	return save_data.get(key, default)


func set(key: String, value: Variant) -> void:
	save_data[key] = value


func has(key: String) -> bool:
	return save_data.has(key)


func delete(key: String) -> void:
	save_data.erase(key)


func get_setting(key: String, default=null) -> Variant:
	return settings_data.get(key, default)


func set_setting(key: String, value: Variant) -> void:
	settings_data[key] = value
	save_settings()


# --- High-level Game State ---

func new_game() -> void:
	save_data = {
		"version": game_data.save_version,
		"tier": 1,
		"wave": 0,
		"highest_wave": 0,
		"currencies": {
			"cash": 0,
			"coins": 0,
			"gems": 500,  # Starting gems
			"power_stones": 0,
			"medals": 0,
			"elite_cells": 0,
			"keys": 0,
			"bits": 0,
			"tokens": 0,
			"module_shards": 0,
			"reroll_shards": 0,
		},
		"workshop": {
			"attack": {},
			"defense": {},
			"utility": {},
			"enhancements": {},
		},
		"labs": {
			"slots_unlocked": 1,
			"research": {},
			"active_lab": "",
			"lab_progress": 0.0,
		},
		"cards": {
			"owned": {},
			"slots": [],
			"slot_count": 22,
		},
		"modules": {
			"cannon": {},
			"armor": {},
			"generator": {},
			"core": {},
			"assist_slots": 0,
		},
		"ultimate_weapons": {
			"owned": [],
			"levels": {},
			"uw_plus_levels": {},
			"active_uw": -1,
		},
		"bots": {
			"unlocked": [],
			"levels": {},
			"bot_plus_levels": {},
		},
		"perks": {
			"current_run": [],
			"banned": [],
		},
		"relics": {
			"owned": [],
		},
		"vault": {
			"harmony_power": {},
			"harmony_enemy": {},
			"keys_spent": 0,
		},
		"guardian": {
			"chips": {},
			"slots_unlocked": 1,
		},
		"guild": {
			"joined": false,
			"tokens": 0,
			"bits": 0,
		},
		"tournaments": {
			"league": 0,
			"rank": 0,
			"tickets": 0,
		},
		"statistics": {
			"total_waves_cleared": 0,
			"total_enemies_killed": 0,
			"total_bosses_killed": 0,
			"total_playtime": 0.0,
			"prestiges": 0,
		},
		"settings": {
			"auto_battle": false,
			"show_damage_numbers": true,
			"show_health_bars": true,
		},
	}
	save_game()


func get_currency(currency: String) -> int:
	return save_data.get("currencies", {}).get(currency, 0)


func add_currency(currency: String, amount: int) -> void:
	if not save_data.has("currencies"):
		save_data["currencies"] = {}
	save_data["currencies"][currency] = save_data["currencies"].get(currency, 0) + amount


func spend_currency(currency: String, amount: int) -> bool:
	var current = get_currency(currency)
	if current >= amount:
		save_data["currencies"][currency] = current - amount
		return true
	return false


func get_workshop_level(category: String, upgrade_id: String) -> int:
	return save_data.get("workshop", {}).get(category, {}).get(upgrade_id, 0)


func set_workshop_level(category: String, upgrade_id: String, level: int) -> void:
	if not save_data.has("workshop"):
		save_data["workshop"] = {"attack": {}, "defense": {}, "utility": {}, "enhancements": {}}
	save_data["workshop"][category][upgrade_id] = level


func get_lab_level(lab_id: String) -> int:
	return save_data.get("labs", {}).get("research", {}).get(lab_id, 0)


func set_lab_level(lab_id: String, level: int) -> void:
	if not save_data.has("labs"):
		save_data["labs"] = {"slots_unlocked": 1, "research": {}, "active_lab": "", "lab_progress": 0.0}
	save_data["labs"]["research"][lab_id] = level


func get_card_stars(card_id: String) -> int:
	return save_data.get("cards", {}).get("owned", {}).get(card_id, 0)


func set_card_stars(card_id: String, stars: int) -> void:
	if not save_data.has("cards"):
		save_data["cards"] = {"owned": {}, "slots": [], "slot_count": 22}
	save_data["cards"]["owned"][card_id] = stars


func get_uw_level(uw_index: int) -> int:
	return save_data.get("ultimate_weapons", {}).get("levels", {}).get(str(uw_index), 0)


func set_uw_level(uw_index: int, level: int) -> void:
	if not save_data.has("ultimate_weapons"):
		save_data["ultimate_weapons"] = {"owned": [], "levels": {}, "uw_plus_levels": {}, "active_uw": -1}
	save_data["ultimate_weapons"]["levels"][str(uw_index)] = level
	if uw_index not in save_data["ultimate_weapons"]["owned"]:
		save_data["ultimate_weapons"]["owned"].append(uw_index)


func get_bot_level(bot_index: int) -> int:
	return save_data.get("bots", {}).get("levels", {}).get(str(bot_index), 0)


func set_bot_level(bot_index: int, level: int) -> void:
	if not save_data.has("bots"):
		save_data["bots"] = {"unlocked": [], "levels": {}, "bot_plus_levels": {}}
	save_data["bots"]["levels"][str(bot_index)] = level
	if bot_index not in save_data["bots"]["unlocked"]:
		save_data["bots"]["unlocked"].append(bot_index)


func unlock_bot(bot_index: int) -> void:
	if not save_data.has("bots"):
		save_data["bots"] = {"unlocked": [], "levels": {}, "bot_plus_levels": {}}
	if bot_index not in save_data["bots"]["unlocked"]:
		save_data["bots"]["unlocked"].append(bot_index)


func get_relic_owned(relic_id: String) -> bool:
	return relic_id in save_data.get("relics", {}).get("owned", [])


func add_relic(relic_id: String) -> void:
	if not save_data.has("relics"):
		save_data["relics"] = {"owned": []}
	if relic_id not in save_data["relics"]["owned"]:
		save_data["relics"]["owned"].append(relic_id)


func increment_stat(stat: String, amount: int = 1) -> void:
	if not save_data.has("statistics"):
		save_data["statistics"] = {}
	save_data["statistics"][stat] = save_data["statistics"].get(stat, 0) + amount