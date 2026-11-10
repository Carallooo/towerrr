extends Resource
class_name GameData

## =============================================================================
# GAME DATA - Central configuration for all game constants and balance
## =============================================================================

# --- TIER CONFIGURATION ---
@export var tier_count: int = 24
@export var waves_per_tier_milestone: int = 4500
@export var tier_16_plus_waves: int = 300

# Tier coin multipliers (index 0 = Tier 1)
@export var tier_coin_multipliers: Array[float] = [
	1.0, 1.2, 1.5, 1.9, 2.4, 3.0, 3.8, 4.7, 5.8, 7.2,
	8.9, 11.0, 13.5, 16.7, 20.6, 25.4, 31.3, 38.6, 47.5, 58.5,
	72.0, 88.6, 109.1, 134.3
]

# Battle conditions unlock at tier 14
@export var battle_condition_start_tier: int = 14

# --- ENEMY CONFIGURATION ---
@export var max_enemies_on_screen: int = 150
@export var max_normal_enemies: int = 120
@export var max_elites: int = 20
@export var max_bosses: int = 10
@export var max_elites_per_type: int = 8

# Enemy types (matching original)
enum EnemyType { BASIC, FAST, TANK, RANGED, PROTECTOR, BOSS, VAMPIRE, RAY, SCATTER, SABOTEUR, COMMANDER, OVERCHARGE }

# Base stats per enemy type
@export var enemy_base_health: Dictionary = {
	EnemyType.BASIC: 1.0,
	EnemyType.FAST: 1.0,
	EnemyType.TANK: 5.0,
	EnemyType.RANGED: 1.0,
	EnemyType.PROTECTOR: 1.0,
	EnemyType.BOSS: 20.0,
	EnemyType.VAMPIRE: 2.0,
	EnemyType.RAY: 1.0,
	EnemyType.SCATTER: 2.0,
	EnemyType.SABOTEUR: 20.0,
	EnemyType.COMMANDER: 20.0,
	EnemyType.OVERCHARGE: 20.0,
}

@export var enemy_base_speed: Dictionary = {
	EnemyType.BASIC: 1.0,
	EnemyType.FAST: 2.0,
	EnemyType.TANK: 0.5,
	EnemyType.RANGED: 1.0,
	EnemyType.PROTECTOR: 1.0,
	EnemyType.BOSS: 0.3,
	EnemyType.VAMPIRE: 1.0,
	EnemyType.RAY: 1.0,
	EnemyType.SCATTER: 1.0,
	EnemyType.SABOTEUR: 2.0,
	EnemyType.COMMANDER: 0.5,
	EnemyType.OVERCHARGE: 1.0,
}

@export var enemy_base_coins: Dictionary = {
	EnemyType.BASIC: 1,
	EnemyType.FAST: 2,
	EnemyType.TANK: 4,
	EnemyType.RANGED: 2,
	EnemyType.PROTECTOR: 3,
	EnemyType.BOSS: 5,
	EnemyType.VAMPIRE: 4,
	EnemyType.RAY: 4,
	EnemyType.SCATTER: 4,
	EnemyType.SABOTEUR: 0,
	EnemyType.COMMANDER: 0,
	EnemyType.OVERCHARGE: 0,
}

# Elite spawn milestones (tier -> {1%, 25%, 1/wave, 2/wave})
@export var elite_spawn_milestones: Dictionary = {
	1: {500, 3000, 8000, 17000},
	16: {41, 411, 1441, 3294},
	24: {17, 177, 620, 1418},
}

# Fleet spawn schedule
@export var fleet_first_wave: Dictionary = {
	1: 15000, 14: 2495, 18: 95, 20: 5
}
@export var fleet_frequency: Dictionary = {
	1: 100, 14: 1000, 18: 100, 20: 10
}

# --- WORKSHOP CONFIGURATION ---
@export var workshop_max_level: int = 6000
@export var workshop_defense_percent_cap: float = 0.495 # 49.5% from workshop

# --- LAB CONFIGURATION ---
@export var lab_slot_count: int = 5
@export var lab_slot_gem_costs: Array[int] = [200, 400, 800, 1600, 3200] # Total 4900
@export var max_lab_level: int = 99

# --- CARD CONFIGURATION ---
@export var max_card_stars: int = 7
@export var card_slot_count: int = 22
@export var max_card_slots: int = 28
@export var card_gem_cost_per_star: Dictionary = {
	1: 20, 2: 60, 3: 160, 4: 320, 5: 560, 6: 960, 7: 1600
}

# Card definitions
@export var common_cards: Array[Dictionary] = [
	{"id": "damage", "name": "Damage", "effect": "tower_damage_mult", "lv1": 1.5, "lv7": 4.0},
	{"id": "attack_speed", "name": "Attack Speed", "effect": "attack_speed_mult", "lv1": 1.25, "lv7": 2.15},
	{"id": "health", "name": "Health", "effect": "tower_health_mult", "lv1": 1.5, "lv7": 4.0},
	{"id": "health_regen", "name": "Health Regen", "effect": "health_regen_mult", "lv1": 1.4, "lv7": 2.6},
	{"id": "range", "name": "Range", "effect": "range_mult", "lv1": 1.15, "lv7": 1.45},
	{"id": "cash", "name": "Cash", "effect": "cash_mult", "lv1": 1.2, "lv7": 2.4},
	{"id": "coins", "name": "Coins", "effect": "coin_mult", "lv1": 1.15, "lv7": 1.45},
	{"id": "slow_aura", "name": "Slow Aura", "effect": "slow_percent", "lv1": 0.13, "lv7": 0.31},
	{"id": "crit_chance", "name": "Critical Chance", "effect": "crit_chance", "lv1": 0.05, "lv7": 0.11},
	{"id": "enemy_balance", "name": "Enemy Balance", "effect": "enemy_spawn_mult", "lv1": 1.3, "lv7": 1.9},
	{"id": "extra_defense", "name": "Extra Defense", "effect": "defense_percent", "lv1": 0.05, "lv7": 0.11},
	{"id": "fortress", "name": "Fortress", "effect": "defense_absolute", "lv1": 1.3, "lv7": 2.2},
]

@export var rare_cards: Array[Dictionary] = [
	{"id": "free_upgrades", "name": "Free Upgrades", "effect": "free_upgrade_chance", "lv1": 0.04, "lv7": 0.10},
	{"id": "extra_orb", "name": "Extra Orb", "effect": "extra_orb_speed", "lv1": 0.3, "lv7": 0.9},
	{"id": "plasma_cannon", "name": "Plasma Cannon", "effect": "plasma_boss_damage", "lv1": 0.30, "lv7": 0.54},
	{"id": "critical_coin", "name": "Critical Coin", "effect": "crit_coin_chance", "lv1": 0.15, "lv7": 0.33},
	{"id": "wave_skip", "name": "Wave Skip", "effect": "wave_skip_chance", "lv1": 0.09, "lv7": 0.19},
	{"id": "intro_sprint", "name": "Intro Sprint", "effect": "intro_sprint_waves", "lv1": 20, "lv7": 100},
	{"id": "land_mine_stun", "name": "Land Mine Stun", "effect": "mine_stun_duration", "lv1": 1.4, "lv7": 3.8},
	{"id": "recovery_chance", "name": "Recovery Package", "effect": "recovery_spawn_chance", "lv1": 0.15, "lv7": 0.33},
	{"id": "cells", "name": "Cells", "effect": "cells_bonus", "lv1": 2, "lv7": 14},
]

@export var epic_cards: Array[Dictionary] = [
	{"id": "death_ray", "name": "Death Ray", "effect": "death_ray_duration", "lv1": 2.3, "lv7": 4.9},
	{"id": "energy_net", "name": "Energy Net", "effect": "energy_net_duration", "lv1": 2.5, "lv7": 4.3},
	{"id": "super_tower", "name": "Super Tower", "effect": "super_tower_damage_mult", "lv1": 2.5, "lv7": 5.0},
	{"id": "second_wind", "name": "Second Wind", "effect": "second_wind_shield", "lv1": 10, "lv7": 40},
	{"id": "demon_mode", "name": "Demon Mode", "effect": "demon_mode_duration", "lv1": 180, "lv7": 300},
	{"id": "energy_shield", "name": "Energy Shield", "effect": "energy_shield_recharge", "lv1": 20, "lv7": 8},
	{"id": "wave_accelerator", "name": "Wave Accelerator", "effect": "wave_cd_reduction", "lv1": 0.30, "lv7": 0.54},
	{"id": "berserker", "name": "Berserker", "effect": "berserker_damage_per_absorbed", "lv1": 0.008, "lv7": 0.014},
	{"id": "ultimate_crit", "name": "Ultimate Crit", "effect": "uw_crit_chance", "lv1": 0.01, "lv7": 0.03},
	{"id": "nuke", "name": "Nuke", "effect": "nuke_percent", "lv1": 0.25, "lv7": 1.0},
	{"id": "aoe", "name": "Area of Effect", "effect": "aoe_damage_mult", "lv1": 0.05, "lv7": 0.25},
]

# --- ULTIMATE WEAPONS ---
@export var uw_unlock_costs: Array[int] = [5, 50, 150, 300, 800, 1250, 1750, 2400, 3000]
@export var uw_names: Array[String] = [
	"Golden Tower", "Black Hole", "Death Wave", "Spotlight",
	"Chrono Field", "Chain Lightning", "Smart Missiles", "Inner Land Mines", "Poison Swamp"
]

# --- BOTS ---
@export var bot_unlock_costs: Array[int] = [150, 300, 600, 900, 1200]
@export var bot_names: Array[String] = ["Flame", "Thunder", "Golden", "Amplify", "Bot Bot"]

# --- CURRENCIES ---
enum Currency { CASH, COINS, GEMS, POWER_STONES, MEDALS, ELITE_CELLS, KEYS, BITS, TOKENS, MODULE_SHARDS, REROLL_SHARDS }

# --- PERKS ---
@export var standard_perks: Array[Dictionary] = [
	{"id": "max_health", "name": "Max Health", "mult": 1.2, "max_picks": 5},
	{"id": "damage", "name": "Damage", "mult": 1.15, "max_picks": 5},
	{"id": "coin_bonus", "name": "All Coin Bonuses", "mult": 1.15, "max_picks": 5},
	{"id": "defense_abs", "name": "Defense Absolute", "mult": 1.15, "max_picks": 5},
	{"id": "cash_bonus", "name": "Cash Bonus", "mult": 1.15, "max_picks": 5},
	{"id": "health_regen", "name": "Health Regen", "mult": 1.75, "max_picks": 5},
	{"id": "interest", "name": "Interest", "mult": 1.5, "max_picks": 5},
	{"id": "mine_damage", "name": "Land Mine Damage", "mult": 3.5, "max_picks": 5},
	{"id": "free_upgrade", "name": "Free Upgrade Chance", "flat": 0.05, "max_picks": 5},
	{"id": "defense_pct", "name": "Defense Percent", "flat": 0.04, "max_picks": 5},
	{"id": "bounce_shot", "name": "Bounce Shot", "flat": 2, "max_picks": 3},
	{"id": "wave_req", "name": "Perk Wave Requirement", "flat": -0.20, "max_picks": 5},
	{"id": "orbs", "name": "Orbs", "flat": 1, "max_picks": 2},
	{"id": "random_uw", "name": "Random UW Unlock", "flat": 1, "max_picks": 1},
	{"id": "game_speed", "name": "Max Game Speed", "flat": 1.0, "max_picks": 1},
]

@export var uw_perks: Array[Dictionary] = [
	{"id": "smart_missiles", "name": "Smart Missiles +4", "uw": "Smart Missiles", "flat": 4, "max_picks": 1},
	{"id": "poison_swamp", "name": "Poison Swamp Radius", "uw": "Poison Swamp", "mult": 1.5, "max_picks": 1},
	{"id": "death_wave", "name": "Death Wave +1", "uw": "Death Wave", "flat": 1, "max_picks": 1},
	{"id": "inner_mines", "name": "Inner Land Mines +1 Set", "uw": "Inner Land Mines", "flat": 1, "max_picks": 1},
	{"id": "golden_tower", "name": "Golden Tower Bonus", "uw": "Golden Tower", "mult": 1.5, "max_picks": 1},
	{"id": "chain_lightning", "name": "Chain Lightning Damage", "uw": "Chain Lightning", "mult": 2.0, "max_picks": 1},
	{"id": "chrono_field", "name": "Chrono Field Duration", "uw": "Chrono Field", "flat": 5, "max_picks": 1},
	{"id": "black_hole", "name": "Black Hole Duration", "uw": "Black Hole", "flat": 12, "max_picks": 1},
	{"id": "spotlight", "name": "Spotlight Damage", "uw": "Spotlight", "mult": 1.5, "max_picks": 1},
]

@export var tradeoff_perks: Array[Dictionary] = [
	{"id": "to_damage", "name": "Damage ×1.5 / Bosses 8× HP", "positive": {"damage": 1.5}, "negative": {"boss_health": 8.0}},
	{"id": "to_coins", "name": "Coins ×1.8 / Max Health -70%", "positive": {"coins": 1.8}, "negative": {"max_health": 0.3}},
	{"id": "to_enemy_health", "name": "Enemy Health -50% / Regen & Lifesteal -90%", "positive": {"enemy_health": 0.5}, "negative": {"regen_lifesteal": 0.1}},
	{"id": "to_enemy_damage", "name": "Enemy Damage -50% / Tower Damage -50%", "positive": {"enemy_damage": 0.5}, "negative": {"damage": 0.5}},
	{"id": "to_ranged_close", "name": "Ranged Closer / Ranged Damage ×3", "positive": {"ranged_distance": 0.5}, "negative": {"ranged_damage": 3.0}},
	{"id": "to_enemy_speed", "name": "Enemy Speed -40% / Enemy Damage ×2.5", "positive": {"enemy_speed": 0.6}, "negative": {"enemy_damage": 2.5}},
	{"id": "to_cash_wave", "name": "Cash/Wave ×12 / Kills No Cash", "positive": {"cash_wave": 12.0}, "negative": {"kill_cash": 0.0}},
	{"id": "to_regen", "name": "Regen ×8 / Max Health -60%", "positive": {"regen": 8.0}, "negative": {"max_health": 0.4}},
	{"id": "to_boss_health", "name": "Boss Health -70% / Boss Speed +50%", "positive": {"boss_health": 0.3}, "negative": {"boss_speed": 1.5}},
	{"id": "to_lifesteal", "name": "Lifesteal ×2.5 / Knockback -70%", "positive": {"lifesteal": 2.5}, "negative": {"knockback": 0.3}},
]

# --- RELICS ---
@export var relic_rarities: Array[String] = ["Common", "Rare", "Epic", "Legendary"]

# --- COLORS (procedural rendering) ---
@export var color_tower: Color = Color(0.2, 0.8, 0.4)
@export var color_tower_core: Color = Color(0.1, 0.6, 0.3)
@export var color_enemy_basic: Color = Color(0.9, 0.3, 0.3)
@export var color_enemy_fast: Color = Color(0.3, 0.9, 0.3)
@export var color_enemy_tank: Color = Color(0.6, 0.6, 0.9)
@export var color_enemy_ranged: Color = Color(0.9, 0.6, 0.3)
@export var color_enemy_protector: Color = Color(0.5, 0.5, 0.5)
@export var color_enemy_boss: Color = Color(0.9, 0.1, 0.1)
@export var color_enemy_elite: Color = Color(0.8, 0.2, 0.8)
@export var color_projectile: Color = Color(1.0, 0.9, 0.3)
@export var color_ui_bg: Color = Color(0.08, 0.08, 0.12)
@export var color_ui_panel: Color = Color(0.12, 0.12, 0.18)
@export var color_ui_accent: Color = Color(0.2, 0.7, 0.9)
@export var color_ui_gold: Color = Color(1.0, 0.8, 0.2)
@export var color_ui_gem: Color = Color(0.3, 0.9, 0.7)
@export var color_ui_text: Color = Color(0.95, 0.95, 0.98)

# --- GAMEPLAY CONSTANTS ---
@export var base_wave_interval: float = 1.5
@export var min_wave_interval: float = 0.1
@export var heatup_per_hit: float = 0.04
@export var coin_decay_after_waves: int = 3
@export var coin_decay_factor: float = 0.5
@export var mass_growth_per_wave: float = 0.04
@export var max_game_speed: float = 5.0
@export var defense_percent_cap: float = 0.98

# --- SAVE ---
@export var save_version: int = 1
@export var auto_save_interval: float = 30.0


func get_tier_coin_multiplier(tier: int) -> float:
	if tier < 1: return 1.0
	if tier > tier_coin_multipliers.size(): return tier_coin_multipliers[-1]
	return tier_coin_multipliers[tier - 1]


func get_waves_for_tier_milestone(tier: int) -> int:
	if tier <= 15: return waves_per_tier_milestone
	return tier_16_plus_waves


func get_elite_spawn_milestones_for_tier(tier: int) -> Array[int]:
	if tier <= 1: return elite_spawn_milestones[1]
	if tier >= 24: return elite_spawn_milestones[24]
	if tier >= 16: return elite_spawn_milestones[16]
	# Interpolate between tier 1 and 16
	var t = (tier - 1) / 15.0
	var result = []
	for i in 4:
		var v1 = elite_spawn_milestones[1][i]
		var v16 = elite_spawn_milestones[16][i]
		result.append(int(lerp(v1, v16, t)))
	return result


func lerp(a: float, b: float, t: float) -> float:
	return a + (b - a) * t