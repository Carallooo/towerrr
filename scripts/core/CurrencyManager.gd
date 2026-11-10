extends Node
class_name CurrencyManager

signal currency_changed(currency: String, old_value: int, new_value: int)
signal currency_gained(currency: String, amount: int, source: String)
signal currency_spent(currency: String, amount: int, purpose: String)
signal not_enough_currency(currency: String, required: int, have: int)

@onready var save_manager: SaveManager = SaveManager
@onready var game_data: GameData = GameData.new()

# Currency display names
const CURRENCY_NAMES = {
	"cash": "Cash",
	"coins": "Coins",
	"gems": "Gems",
	"power_stones": "Power Stones",
	"medals": "Medals",
	"elite_cells": "Elite Cells",
	"keys": "Keys",
	"bits": "Bits",
	"tokens": "Tokens",
	"module_shards": "Module Shards",
	"reroll_shards": "Reroll Shards",
}

const CURRENCY_ICONS = {
	"cash": "💵",
	"coins": "🪙",
	"gems": "💎",
	"power_stones": "🔮",
	"medals": "🏅",
	"elite_cells": "🧬",
	"keys": "🔑",
	"bits": "⚙️",
	"tokens": "🎫",
	"module_shards": "✨",
	"reroll_shards": "🔄",
}

const CURRENCY_COLORS = {
	"cash": Color(0.2, 0.8, 0.3),
	"coins": Color(1.0, 0.8, 0.2),
	"gems": Color(0.3, 0.9, 0.7),
	"power_stones": Color(0.7, 0.4, 1.0),
	"medals": Color(1.0, 0.6, 0.1),
	"elite_cells": Color(0.9, 0.3, 0.9),
	"keys": Color(0.9, 0.7, 0.2),
	"bits": Color(0.5, 0.7, 1.0),
	"tokens": Color(0.2, 0.9, 0.9),
	"module_shards": Color(1.0, 0.5, 0.8),
	"reroll_shards": Color(0.8, 0.8, 0.3),
}

func get_currency(currency: String) -> int:
	return save_manager.get_currency(currency)


func get_all_currencies() -> Dictionary:
	return save_manager.save_data.get("currencies", {})


func add(currency: String, amount: int, source: String = "") -> void:
	if amount <= 0:
		return
	var old = get_currency(currency)
	var new = old + amount
	save_manager.add_currency(currency, amount)
	currency_changed.emit(currency, old, new)
	if source != "":
		currency_gained.emit(currency, amount, source)


func spend(currency: String, amount: int, purpose: String = "") -> bool:
	if amount <= 0:
		return true
	var current = get_currency(currency)
	if current >= amount:
		var new = current - amount
		save_manager.save_data["currencies"][currency] = new
		currency_changed.emit(currency, current, new)
		if purpose != "":
			currency_spent.emit(currency, amount, purpose)
		return true
	else:
		not_enough_currency.emit(currency, amount, current)
		return false


func can_afford(currency: String, amount: int) -> bool:
	return get_currency(currency) >= amount


func get_name(currency: String) -> String:
	return CURRENCY_NAMES.get(currency, currency.capitalize())


func get_icon(currency: String) -> String:
	return CURRENCY_ICONS.get(currency, "?")


func get_color(currency: String) -> Color:
	return CURRENCY_COLORS.get(currency, Color.WHITE)


# --- Formatting ---

func format_amount(amount: int) -> String:
	if amount >= 1_000_000_000_000:
		return "%.2fT" % (amount / 1_000_000_000_000.0)
	elif amount >= 1_000_000_000:
		return "%.2fB" % (amount / 1_000_000_000.0)
	elif amount >= 1_000_000:
		return "%.2fM" % (amount / 1_000_000.0)
	elif amount >= 1_000:
		return "%.2fK" % (amount / 1_000.0)
	return str(amount)


func format_with_icon(currency: String, amount: int) -> String:
	return "%s %s" % [get_icon(currency), format_amount(amount)]


# --- Earning Calculations ---

func calculate_wave_coins(wave: int, tier: int, coins_per_kill: float, kills: int) -> int:
	var tier_mult = game_data.get_tier_coin_multiplier(tier)
	var base = coins_per_kill * kills * tier_mult
	# Interest bonus from workshop/labs
	var interest_mult = 1.0 + get_workshop_interest_bonus()
	return int(base * interest_mult)


func calculate_wave_cash(wave: int, cash_per_wave: float, cash_per_kill: float, kills: int) -> int:
	var base = cash_per_wave + cash_per_kill * kills
	return int(base)


func get_workshop_interest_bonus() -> float:
	var workshop = save_manager.save_data.get("workshop", {})
	var utility = workshop.get("utility", {})
	var interest_level = utility.get("interest", 0)
	var max_interest_level = utility.get("max_interest", 0)
	# Each level gives ~1% interest, max interest caps the total
	var bonus = interest_level * 0.01
	var cap = max_interest_level * 1000.0
	return min(bonus, cap / 10000.0)  # Simplified


func get_coin_multiplier() -> float:
	var mult = 1.0
	# Workshop coins bonus
	var workshop = save_manager.save_data.get("workshop", {})
	var utility = workshop.get("utility", {})
	mult *= 1.0 + utility.get("coins", 0) * 0.01
	mult *= 1.0 + utility.get("coins_wave", 0) * 0.01
	# Lab coins bonus
	var labs = save_manager.save_data.get("labs", {}).get("research", {})
	mult *= 1.0 + labs.get("coins_kill_bonus", 0) * 0.01
	mult *= 1.0 + labs.get("coins_wave", 0) * 0.01
	# Card coins bonus
	var cards = save_manager.save_data.get("cards", {}).get("owned", {})
	mult *= 1.0 + cards.get("coins", 0) * 0.01
	# Relic coins bonus
	for relic_id in save_manager.save_data.get("relics", {}).get("owned", []):
		# Would need relic definitions
		pass
	return mult


func get_cash_multiplier() -> float:
	var mult = 1.0
	var workshop = save_manager.save_data.get("workshop", {})
	var utility = workshop.get("utility", {})
	mult *= 1.0 + utility.get("cash_bonus", 0) * 0.01
	mult *= 1.0 + utility.get("cash_wave", 0) * 0.01
	var labs = save_manager.save_data.get("labs", {}).get("research", {})
	mult *= 1.0 + labs.get("cash_bonus", 0) * 0.01
	mult *= 1.0 + labs.get("cash_wave", 0) * 0.01
	var cards = save_manager.save_data.get("cards", {}).get("owned", {})
	mult *= 1.0 + cards.get("cash", 0) * 0.01
	return mult


# --- Prestige/Tier Rewards ---

func grant_tier_rewards(tier: int) -> void:
	# Gems for reaching new tier
	var gem_reward = tier * 50
	add("gems", gem_reward, "tier_reward")

	# Power stones at higher tiers
	if tier >= 10:
		add("power_stones", (tier - 9) * 10, "tier_reward")

	# Keys for vault at tier 3+
	if tier >= 3:
		add("keys", tier * 5, "tier_reward")


func grant_daily_rewards() -> void:
	# Daily login rewards
	var tier = save_manager.get("tier", 1)
	add("gems", 10 + tier * 2, "daily")
	add("coins", 1000 * tier, "daily")
	if tier >= 10:
		add("power_stones", 5, "daily")


func grant_tournament_rewards(league: int, rank: int) -> void:
	# League: 0=Copper, 1=Silver, 2=Gold, 3=Platinum, 4=Champion, 5=Legend, 6=Mythic
	var gem_rewards = [50, 100, 200, 400, 800, 1500, 3000]
	var stone_rewards = [0, 5, 15, 30, 60, 125, 250]
	var key_rewards = [0, 0, 0, 0, 0, 25, 50]

	var rank_mult = max(1.0, 1.5 - (rank - 1) * 0.1)

	add("gems", int(gem_rewards[league] * rank_mult), "tournament")
	add("power_stones", int(stone_rewards[league] * rank_mult), "tournament")
	if league >= 5:
		add("keys", key_rewards[league], "tournament")