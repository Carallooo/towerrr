extends Node
class_name WorkshopManager

signal upgrade_purchased(category: String, upgrade_id: String, new_level: int, permanent: bool)
signal workshop_changed()

@onready var save_manager: SaveManager = SaveManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var game_data: GameData = GameData.new()

# Workshop upgrade definitions
# Format: {id, name, description, max_level, base_cost, cost_exponent, effect_per_level, effect_type}
# effect_type: "mult" (multiplicative), "flat" (additive), "percent" (percentage)

const ATTACK_UPGRADES = [
	{"id": "damage", "name": "Damage", "desc": "Increases tower damage", "max": 6000, "base": 10, "exp": 1.15, "effect": 0.005, "type": "mult"},
	{"id": "attack_speed", "name": "Attack Speed", "desc": "Increases tower attack speed", "max": 6000, "base": 10, "exp": 1.15, "effect": 0.003, "type": "mult"},
	{"id": "crit_factor", "name": "Critical Factor", "desc": "Increases critical damage multiplier", "max": 6000, "base": 20, "exp": 1.18, "effect": 0.004, "type": "mult"},
	{"id": "range", "name": "Range", "desc": "Increases tower range", "max": 6000, "base": 15, "exp": 1.16, "effect": 0.002, "type": "mult"},
	{"id": "damage_per_meter", "name": "Damage per Meter", "desc": "Increases damage based on projectile travel distance", "max": 6000, "base": 25, "exp": 1.17, "effect": 0.003, "type": "mult"},
	{"id": "super_crit_chance", "name": "Super Crit Chance", "desc": "Chance for super critical hit", "max": 6000, "base": 50, "exp": 1.20, "effect": 0.0001, "type": "flat"},
	{"id": "super_crit_mult", "name": "Super Crit Multiplier", "desc": "Super critical damage multiplier", "max": 6000, "base": 100, "exp": 1.22, "effect": 0.001, "type": "mult"},
	{"id": "rend_armor", "name": "Rend Armor", "desc": "Reduces enemy defense", "max": 6000, "base": 200, "exp": 1.25, "effect": 0.002, "type": "mult"},
	{"id": "light_speed_shots", "name": "Light Speed Shots", "desc": "Projectiles travel instantly", "max": 1, "base": 10000, "exp": 1.0, "effect": 1, "type": "flat"},
	{"id": "bounce_shot", "name": "Bounce Shot", "desc": "Projectiles bounce to additional enemies", "max": 10, "base": 500, "exp": 1.5, "effect": 1, "type": "flat"},
	{"id": "pierce", "name": "Pierce", "desc": "Projectiles pierce through enemies", "max": 10, "base": 800, "exp": 1.6, "effect": 1, "type": "flat"},
	{"id": "splash_damage", "name": "Splash Damage", "desc": "Attacks deal area damage", "max": 6000, "base": 300, "exp": 1.2, "effect": 0.001, "type": "mult"},
	{"id": "poison", "name": "Poison", "desc": "Attacks apply poison DoT", "max": 6000, "base": 400, "exp": 1.2, "effect": 0.001, "type": "mult"},
	{"id": "slow", "name": "Slow", "desc": "Attacks slow enemies", "max": 6000, "base": 300, "exp": 1.2, "effect": 0.001, "type": "mult"},
	{"id": "stun_chance", "name": "Stun Chance", "desc": "Attacks can stun enemies", "max": 6000, "base": 500, "exp": 1.25, "effect": 0.0001, "type": "flat"},
	{"id": "lifesteal", "name": "Lifesteal", "desc": "Heal on damage dealt", "max": 6000, "base": 600, "exp": 1.2, "effect": 0.0005, "type": "mult"},
	{"id": "orb_damage", "name": "Orb Damage", "desc": "Increases orb damage", "max": 6000, "base": 200, "exp": 1.18, "effect": 0.005, "type": "mult"},
]

const DEFENSE_UPGRADES = [
	{"id": "health", "name": "Health", "desc": "Increases tower max health", "max": 6000, "base": 10, "exp": 1.15, "effect": 0.005, "type": "mult"},
	{"id": "health_regen", "name": "Health Regen", "desc": "Increases health regeneration per second", "max": 6000, "base": 15, "exp": 1.16, "effect": 0.004, "type": "mult"},
	{"id": "defense_absolute", "name": "Defense Absolute", "desc": "Flat damage reduction", "max": 6000, "base": 20, "exp": 1.18, "effect": 0.5, "type": "flat"},
	{"id": "defense_percent", "name": "Defense Percent", "desc": "Percentage damage reduction (caps at 98%)", "max": 6000, "base": 25, "exp": 1.18, "effect": 0.0000825, "type": "flat"},  # 49.5% at max
	{"id": "orb_speed", "name": "Orb Speed", "desc": "Increases orb rotation speed", "max": 6000, "base": 30, "exp": 1.17, "effect": 0.001, "type": "mult"},
	{"id": "land_mine_damage", "name": "Land Mine Damage", "desc": "Increases land mine damage", "max": 6000, "base": 40, "exp": 1.18, "effect": 0.005, "type": "mult"},
	{"id": "land_mine_decay", "name": "Land Mine Decay", "desc": "Reduces land mine damage decay over time", "max": 6000, "base": 50, "exp": 1.19, "effect": 0.005, "type": "flat"},
	{"id": "shockwave_size", "name": "Shockwave Size", "desc": "Increases shockwave radius", "max": 6000, "base": 60, "exp": 1.2, "effect": 0.001, "type": "mult"},
	{"id": "orb_boss_hit", "name": "Orb Boss Hit", "desc": "Orbs can damage bosses", "max": 6000, "base": 100, "exp": 1.25, "effect": 0.0001, "type": "flat"},
	{"id": "wall_health", "name": "Wall Health", "desc": "Increases wall health", "max": 6000, "base": 20, "exp": 1.18, "effect": 0.02, "type": "mult"},
	{"id": "wall_rebuild", "name": "Wall Rebuild", "desc": "Reduces wall rebuild time", "max": 6000, "base": 30, "exp": 1.2, "effect": 0.05, "type": "flat"},
	{"id": "wall_regen", "name": "Wall Regen", "desc": "Increases wall health regeneration", "max": 6000, "base": 40, "exp": 1.18, "effect": 0.02, "type": "mult"},
	{"id": "thorns", "name": "Thorns", "desc": "Reflects damage to attackers", "max": 6000, "base": 50, "exp": 1.2, "effect": 0.001, "type": "mult"},
	{"id": "invincibility", "name": "Invincibility", "desc": "Grants brief invincibility on wall break", "max": 6000, "base": 100, "exp": 1.25, "effect": 0.001, "type": "flat"},
	{"id": "fortification", "name": "Fortification", "desc": "Increases wall defense", "max": 6000, "base": 80, "exp": 1.22, "effect": 0.02, "type": "mult"},
	{"id": "garlic", "name": "Garlic", "desc": "Enemies take damage over time near tower", "max": 6000, "base": 200, "exp": 1.2, "effect": 0.001, "type": "mult"},
	{"id": "damage_reflection", "name": "Damage Reflection", "desc": "Reflects portion of damage taken", "max": 6000, "base": 300, "exp": 1.22, "effect": 0.0005, "type": "mult"},
	{"id": "shield_recharge", "name": "Shield Recharge", "desc": "Energy shield recharges faster", "max": 6000, "base": 400, "exp": 1.25, "effect": 0.01, "type": "flat"},
]

const UTILITY_UPGRADES = [
	{"id": "cash_bonus", "name": "Cash Bonus", "desc": "Increases cash earned from kills", "max": 6000, "base": 10, "exp": 1.15, "effect": 0.005, "type": "mult"},
	{"id": "cash_wave", "name": "Cash per Wave", "desc": "Increases base cash per wave", "max": 6000, "base": 10, "exp": 1.15, "effect": 1.0, "type": "flat"},
	{"id": "coins", "name": "Coins per Kill", "desc": "Increases coins earned per kill", "max": 6000, "base": 15, "exp": 1.16, "effect": 0.005, "type": "mult"},
	{"id": "coins_wave", "name": "Coins per Wave", "desc": "Increases base coins per wave", "max": 6000, "base": 20, "exp": 1.17, "effect": 0.5, "type": "flat"},
	{"id": "interest", "name": "Interest Rate", "desc": "Increases interest on held cash", "max": 6000, "base": 25, "exp": 1.18, "effect": 0.001, "type": "flat"},
	{"id": "max_interest", "name": "Max Interest", "desc": "Increases maximum interest earnable", "max": 6000, "base": 50, "exp": 1.2, "effect": 1000.0, "type": "flat"},
	{"id": "package_after_boss", "name": "Package After Boss", "desc": "Guaranteed recovery package after boss", "max": 1, "base": 5000, "exp": 1.0, "effect": 1, "type": "flat"},
	{"id": "recovery_amount", "name": "Recovery Amount", "desc": "Increases recovery package healing", "max": 6000, "base": 100, "exp": 1.2, "effect": 0.002, "type": "mult"},
	{"id": "recovery_max", "name": "Recovery Max", "desc": "Increases max recovery package healing", "max": 6000, "base": 150, "exp": 1.22, "effect": 0.002, "type": "mult"},
	{"id": "recovery_chance", "name": "Recovery Chance", "desc": "Increases recovery package spawn chance", "max": 6000, "base": 200, "exp": 1.25, "effect": 0.0002, "type": "flat"},
	{"id": "enemy_attack_skip", "name": "Enemy Attack Skip", "desc": "Skips enemy attack levels", "max": 6000, "base": 300, "exp": 1.25, "effect": 0.001, "type": "flat"},
	{"id": "enemy_health_skip", "name": "Enemy Health Skip", "desc": "Skips enemy health levels", "max": 6000, "base": 300, "exp": 1.25, "effect": 0.001, "type": "flat"},
	{"id": "kill_bonus", "name": "Kill Bonus", "desc": "Bonus coins on enemy kill", "max": 6000, "base": 50, "exp": 1.18, "effect": 0.01, "type": "flat"},
]

const ENHANCEMENT_UPGRADES = [
	{"id": "free_attack_upgrade", "name": "Free Attack Upgrade", "desc": "Chance for free attack upgrade per wave", "max": 100, "base": 1000000, "exp": 1.1, "effect": 0.01, "type": "flat"},
	{"id": "free_defense_upgrade", "name": "Free Defense Upgrade", "desc": "Chance for free defense upgrade per wave", "max": 100, "base": 1000000, "exp": 1.1, "effect": 0.01, "type": "flat"},
	{"id": "free_utility_upgrade", "name": "Free Utility Upgrade", "desc": "Chance for free utility upgrade per wave", "max": 100, "base": 1000000, "exp": 1.1, "effect": 0.01, "type": "flat"},
	{"id": "enemy_gold", "name": "Enemy Gold", "desc": "Enemies drop more gold", "max": 100, "base": 2000000, "exp": 1.12, "effect": 0.02, "type": "mult"},
	{"id": "enemy_cells", "name": "Enemy Cells", "desc": "Enemies drop more cells", "max": 100, "base": 2000000, "exp": 1.12, "effect": 0.02, "type": "mult"},
	{"id": "boss_loot", "name": "Boss Loot", "desc": "Bosses drop better rewards", "max": 100, "base": 5000000, "exp": 1.15, "effect": 0.05, "type": "mult"},
	{"id": "wave_speed", "name": "Wave Speed", "desc": "Reduces time between waves", "max": 100, "base": 1000000, "exp": 1.1, "effect": 0.005, "type": "mult"},
	{"id": "projectile_speed", "name": "Projectile Speed", "desc": "Increases projectile speed", "max": 100, "base": 1000000, "exp": 1.1, "effect": 0.01, "type": "mult"},
	{"id": "crit_chance", "name": "Critical Chance", "desc": "Increases critical hit chance", "max": 100, "base": 2000000, "exp": 1.12, "effect": 0.005, "type": "flat"},
	{"id": "crit_damage", "name": "Critical Damage", "desc": "Increases critical hit damage", "max": 100, "base": 2000000, "exp": 1.12, "effect": 0.02, "type": "mult"},
	{"id": "attack_range", "name": "Attack Range", "desc": "Increases tower attack range", "max": 100, "base": 1000000, "exp": 1.1, "effect": 0.01, "type": "mult"},
	{"id": "multi_shot", "name": "Multi Shot", "desc": "Chance to fire additional projectiles", "max": 100, "base": 5000000, "exp": 1.15, "effect": 0.01, "type": "flat"},
	{"id": "orb_count", "name": "Orb Count", "desc": "Increases number of orbs", "max": 10, "base": 10000000, "exp": 1.2, "effect": 1, "type": "flat"},
	{"id": "orb_damage_mult", "name": "Orb Damage", "desc": "Increases orb damage", "max": 100, "base": 5000000, "exp": 1.15, "effect": 0.02, "type": "mult"},
	{"id": "wall_damage", "name": "Wall Damage", "desc": "Wall damages enemies on contact", "max": 100, "base": 3000000, "exp": 1.12, "effect": 0.01, "type": "mult"},
	{"id": "uw_cooldown", "name": "UW Cooldown", "desc": "Reduces Ultimate Weapon cooldowns", "max": 100, "base": 5000000, "exp": 1.15, "effect": 0.005, "type": "mult"},
	{"id": "uw_duration", "name": "UW Duration", "desc": "Increases Ultimate Weapon duration", "max": 100, "base": 5000000, "exp": 1.15, "effect": 0.005, "type": "mult"},
	{"id": "bot_power", "name": "Bot Power", "desc": "Increases bot effectiveness", "max": 100, "base": 10000000, "exp": 1.18, "effect": 0.01, "type": "mult"},
]


func get_upgrades(category: String) -> Array[Dictionary]:
	match category:
		"attack": return ATTACK_UPGRADES
		"defense": return DEFENSE_UPGRADES
		"utility": return UTILITY_UPGRADES
		"enhancements": return ENHANCEMENT_UPGRADES
	return []


func get_upgrade(category: String, upgrade_id: String) -> Dictionary:
	for u in get_upgrades(category):
		if u.id == upgrade_id:
			return u
	return {}


func get_level(category: String, upgrade_id: String) -> int:
	return save_manager.get_workshop_level(category, upgrade_id)


func get_max_level(category: String, upgrade_id: String) -> int:
	var upgrade = get_upgrade(category, upgrade_id)
	return upgrade.get("max", 6000)


func get_cost(category: String, upgrade_id: String, level: int, permanent: bool = true) -> int:
	var upgrade = get_upgrade(category, upgrade_id)
	if not upgrade:
		return 0
	var base = upgrade.base
	var exp = upgrade.exp
	if not permanent:
		# Cash cost during run - much cheaper
		base = int(base * 0.01)
		exp = 1.05
	return int(base * pow(exp, level))


func can_afford(category: String, upgrade_id: String, permanent: bool = true) -> bool:
	var level = get_level(category, upgrade_id)
	if level >= get_max_level(category, upgrade_id):
		return false
	var cost = get_cost(category, upgrade_id, level, permanent)
	var currency = "coins" if permanent else "cash"
	return currency_manager.can_afford(currency, cost)


func purchase(category: String, upgrade_id: String, permanent: bool = true) -> bool:
	var level = get_level(category, upgrade_id)
	var max_level = get_max_level(category, upgrade_id)
	if level >= max_level:
		return false

	var cost = get_cost(category, upgrade_id, level, permanent)
	var currency = "coins" if permanent else "cash"

	if not currency_manager.spend(currency, cost, "workshop_%s_%s" % [category, upgrade_id]):
		return false

	var new_level = level + 1
	save_manager.set_workshop_level(category, upgrade_id, new_level)
	upgrade_purchased.emit(category, upgrade_id, new_level, permanent)
	workshop_changed.emit()
	return true


func get_effect_value(category: String, upgrade_id: String) -> float:
	var level = get_level(category, upgrade_id)
	if level == 0:
		return 0.0
	var upgrade = get_upgrade(category, upgrade_id)
	var effect = upgrade.effect
	var eff_type = upgrade.type

	match eff_type:
		"mult": return 1.0 + effect * level
		"flat": return effect * level
		"percent": return effect * level
	return effect * level


# --- Total Stat Calculations ---

func get_total_damage_mult() -> float:
	var mult = 1.0
	mult *= 1.0 + get_effect_value("attack", "damage")
	mult *= 1.0 + get_effect_value("enhancements", "enemy_gold") * 0.5  # Partial
	return mult


func get_total_attack_speed_mult() -> float:
	return 1.0 + get_effect_value("attack", "attack_speed")


func get_total_crit_factor_mult() -> float:
	return 1.0 + get_effect_value("attack", "crit_factor")


func get_total_range_mult() -> float:
	return 1.0 + get_effect_value("attack", "range") + get_effect_value("enhancements", "attack_range")


func get_total_health_mult() -> float:
	return 1.0 + get_effect_value("defense", "health")


func get_total_health_regen_mult() -> float:
	return 1.0 + get_effect_value("defense", "health_regen")


func get_total_defense_absolute() -> float:
	return get_effect_value("defense", "defense_absolute")


func get_total_defense_percent() -> float:
	var pct = get_effect_value("defense", "defense_percent")
	return min(pct, game_data.workshop_defense_percent_cap)


func get_total_cash_mult() -> float:
	return 1.0 + get_effect_value("utility", "cash_bonus")


func get_total_cash_wave() -> float:
	return get_effect_value("utility", "cash_wave")


func get_total_coin_mult() -> float:
	return 1.0 + get_effect_value("utility", "coins")


func get_total_coin_wave() -> float:
	return get_effect_value("utility", "coins_wave")


func get_total_interest_rate() -> float:
	return get_effect_value("utility", "interest")


func get_total_max_interest() -> float:
	return get_effect_value("utility", "max_interest")


func get_total_lifesteal() -> float:
	return get_effect_value("attack", "lifesteal")


func get_free_upgrade_chance(category: String) -> float:
	match category:
		"attack": return get_effect_value("enhancements", "free_attack_upgrade")
		"defense": return get_effect_value("enhancements", "free_defense_upgrade")
		"utility": return get_effect_value("enhancements", "free_utility_upgrade")
	return 0.0


func get_all_levels() -> Dictionary:
	var result = {}
	for cat in ["attack", "defense", "utility", "enhancements"]:
		result[cat] = {}
		for u in get_upgrades(cat):
			result[cat][u.id] = get_level(cat, u.id)
	return result


func reset_run_upgrades() -> void:
	# Temporary cash upgrades reset each run
	# Permanent coin upgrades persist
	workshop_changed.emit()