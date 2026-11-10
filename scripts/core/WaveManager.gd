extends Node
class_name WaveManager

signal wave_started(wave: int)
signal wave_cleared(wave: int, rewards: Dictionary)
signal enemy_spawned(enemy_data: Dictionary)
signal enemy_died(enemy_data: Dictionary, rewards: Dictionary)
signal boss_spawned(wave: int)
signal tier_upgraded(new_tier: int)
signal game_over()
signal elite_spawned(enemy_type: int, wave: int)
signal fleet_spawned(fleet_type: int, wave: int)

@onready var save_manager: SaveManager = SaveManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var workshop_manager: WorkshopManager = WorkshopManager
@onready var game_data: GameData = GameData.new()

# State
var current_wave: int = 0
var current_tier: int = 1
var enemies_alive: int = 0
var wave_in_progress: bool = false
var wave_timer: float = 0.0
var time_between_waves: float = 1.5
var heatup_stacks: int = 0
var wave_enemies_killed: int = 0
var wave_cash_earned: int = 0
var wave_coins_earned: int = 0

# Elite tracking
var elite_spawned_this_wave: int = 0
var total_elites_killed: int = 0

# Fleet tracking
var next_fleet_wave: int = 0
var fleet_count_this_wave: int = 0

# Game speed
var game_speed: float = 1.0
var target_game_speed: float = 1.0

# Battle conditions (tier 14+)
var active_battle_conditions: Array[Dictionary] = []

func _ready() -> void:
	_load_state()
	_calculate_next_fleet_wave()


func _load_state() -> void:
	current_wave = save_manager.get("wave", 0)
	current_tier = save_manager.get("tier", 1)
	game_speed = save_manager.get_setting("game_speed", 1.0)
	target_game_speed = game_speed
	_apply_battle_conditions()


func _process(delta: float) -> void:
	if not wave_in_progress:
		return

	# Smooth game speed transition
	game_speed = lerp(game_speed, target_game_speed, delta * 5.0)

	wave_timer -= delta * game_speed
	if wave_timer <= 0.0:
		_start_next_wave()


func _start_next_wave() -> void:
	current_wave += 1
	wave_in_progress = true
	wave_enemies_killed = 0
	wave_cash_earned = 0
	wave_coins_earned = 0
	elite_spawned_this_wave = 0
	fleet_count_this_wave = 0

	# Apply intro sprint if card owned
	var intro_sprint = _get_card_effect("intro_sprint")
	if intro_sprint > 0 and current_wave <= intro_sprint:
		current_wave += 9  # Next wave will be +10

	save_manager.set("wave", current_wave)
	save_manager.increment_stat("total_waves_cleared")

	# Check for tier milestone
	_check_tier_milestone()

	# Check for fleet spawn
	_check_fleet_spawn()

	# Check for boss
	var is_boss_wave = (current_wave % 10 == 0)
	if is_boss_wave:
		boss_spawned.emit(current_wave)

	# Spawn enemies
	_spawn_wave_enemies()

	wave_started.emit(current_wave)

	# Set timer for next wave
	var wave_interval = _calculate_wave_interval()
	wave_timer = wave_interval


func _calculate_wave_interval() -> float:
	var base = game_data.base_wave_interval
	var wave_accel = _get_lab_effect("wave_accelerator") / 100.0
	var workshop_wave_speed = workshop_manager.get_effect_value("enhancements", "wave_speed") / 100.0
	var interval = base * (1.0 - wave_accel) * (1.0 - workshop_wave_speed)
	return max(interval, game_data.min_wave_interval)


func _spawn_wave_enemies() -> void:
	var enemy_count = _calculate_enemy_count()
	var enemy_types = _select_enemy_types(enemy_count)

	for enemy_type in enemy_types:
		_spawn_enemy(enemy_type)

	# Spawn elites if eligible
	_spawn_elites()

	# Spawn fleet units if this is a fleet wave
	if fleet_count_this_wave > 0:
		_spawn_fleet()


func _calculate_enemy_count() -> int:
	var base = 5 + (current_wave / 50).floor()
	var enemy_balance = _get_card_effect("enemy_balance")
	base = int(base * enemy_balance)

	# Battle condition: More Enemies
	for cond in active_battle_conditions:
		if cond.id == "more_enemies":
			base = int(base * (1.0 + cond.value))

	return clamp(base, 1, game_data.max_normal_enemies - enemies_alive)


func _select_enemy_types(count: int) -> Array[int]:
	var types = []
	var weights = _get_enemy_spawn_weights()

	for i in range(count):
		var total_weight = 0.0
		for w in weights:
			total_weight += w.value

		var rand = randf() * total_weight
		var accum = 0.0
		for w in weights:
			accum += w.value
			if rand <= accum:
				types.append(w.type)
				break

	return types


func _get_enemy_spawn_weights() -> Array[Dictionary]:
	# Weights change by tier/wave
	var wave_progress = current_wave / 10000.0

	var weights = [
		{"type": game_data.EnemyType.BASIC, "value": max(10.0 - wave_progress * 5.0, 1.0)},
		{"type": game_data.EnemyType.FAST, "value": 3.0 + wave_progress * 2.0},
		{"type": game_data.EnemyType.TANK, "value": 1.0 + wave_progress * 3.0},
		{"type": game_data.EnemyType.RANGED, "value": 2.0 + wave_progress * 2.0},
		{"type": game_data.EnemyType.PROTECTOR, "value": 0.5 + wave_progress * 1.5},
	]

	# Battle conditions affect spawns
	for cond in active_battle_conditions:
		if cond.id == "more_ranged":
			for w in weights:
				if w.type == game_data.EnemyType.RANGED:
					w.value *= 1.0 + cond.value
		elif cond.id == "more_tanks":
			for w in weights:
				if w.type == game_data.EnemyType.TANK:
					w.value *= 1.0 + cond.value

	return weights


func _spawn_enemy(enemy_type: int) -> void:
	if enemies_alive >= game_data.max_enemies_on_screen:
		return

	var health_mult = _get_enemy_health_multiplier()
	var speed_mult = _get_enemy_speed_multiplier()

	var base_health = game_data.enemy_base_health[enemy_type]
	var base_speed = game_data.enemy_base_speed[enemy_type]
	var base_coins = game_data.enemy_base_coins[enemy_type]

	# Wave scaling
	var wave_health_mult = pow(1.02, current_wave)
	var wave_speed_mult = pow(1.005, min(current_wave, 1000))

	# Mass growth
	var mass_mult = pow(1.0 + game_data.mass_growth_per_wave, current_wave)

	# Battle conditions
	for cond in active_battle_conditions:
		if cond.id == "enemy_health" and cond.affects_type(enemy_type):
			wave_health_mult *= 1.0 + cond.value
		if cond.id == "enemy_speed" and cond.affects_type(enemy_type):
			wave_speed_mult *= 1.0 + cond.value

	var final_health = base_health * health_mult * wave_health_mult * mass_mult
	var final_speed = base_speed * speed_mult * wave_speed_mult
	var final_coins = int(base_coins * health_mult * currency_manager.get_coin_multiplier())

	var enemy_data = {
		"type": enemy_type,
		"health": final_health,
		"max_health": final_health,
		"speed": final_speed,
		"coins": final_coins,
		"cash": int(final_coins * 0.5 * currency_manager.get_cash_multiplier()),
		"wave": current_wave,
		"tier": current_tier,
		"shield": enemy_type == game_data.EnemyType.PROTECTOR ? 0.6 : 0.0,
		"heatup": 0.0,
		"distance_traveled": 0.0,
	}

	enemies_alive += 1
	enemy_spawned.emit(enemy_data)


func _spawn_elites() -> void:
	if current_tier < 1:
		return

	var milestones = game_data.get_elite_spawn_milestones_for_tier(current_tier)
	var spawn_chance = 0.0

	if current_wave >= milestones[0]:
		spawn_chance = 0.01  # 1%
	if current_wave >= milestones[1]:
		spawn_chance = 0.25  # 25%
	if current_wave >= milestones[2]:
		spawn_chance = 1.0   # 1 per wave guaranteed
	if current_wave >= milestones[3]:
		spawn_chance = 2.0   # 2 per wave guaranteed

	var elite_count = 0
	if spawn_chance >= 1.0:
		elite_count = int(spawn_chance)
		spawn_chance -= elite_count

	if randf() < spawn_chance:
		elite_count += 1

	elite_count = min(elite_count, game_data.max_elites_per_type)
	elite_count = min(elite_count, game_data.max_elites - enemies_alive)

	var elite_types = [game_data.EnemyType.VAMPIRE, game_data.EnemyType.RAY, game_data.EnemyType.SCATTER]

	for i in range(elite_count):
		var e_type = elite_types[randi() % elite_types.size()]
		_spawn_elite(e_type)
		elite_spawned.emit(e_type, current_wave)


func _spawn_elite(elite_type: int) -> void:
	if enemies_alive >= game_data.max_enemies_on_screen:
		return

	var health_mult = _get_enemy_health_multiplier()
	var speed_mult = _get_enemy_speed_multiplier()

	var base_health = game_data.enemy_base_health[elite_type]
	var base_speed = game_data.enemy_base_speed[elite_type]
	var base_coins = game_data.enemy_base_coins[elite_type]

	var wave_health_mult = pow(1.02, current_wave)
	var mass_mult = pow(1.0 + game_data.mass_growth_per_wave, current_wave)

	# Elites are immune to orbs, death ray, shockwave, black hole
	var final_health = base_health * health_mult * wave_health_mult * mass_mult
	var final_speed = base_speed * speed_mult
	var final_coins = int(base_coins * health_mult * currency_manager.get_coin_multiplier())

	# Elite cells reward
	var cells = _calculate_elite_cells()

	var enemy_data = {
		"type": elite_type,
		"health": final_health,
		"max_health": final_health,
		"speed": final_speed,
		"coins": final_coins,
		"cash": int(final_coins * 2.0 * currency_manager.get_cash_multiplier()),
		"cells": cells,
		"wave": current_wave,
		"tier": current_tier,
		"is_elite": true,
		"immune_to_orbs": true,
		"immune_to_death_ray": true,
		"immune_to_shockwave": true,
		"immune_to_black_hole": true,
		"heatup": 0.0,
		"distance_traveled": 0.0,
		# Type-specific
		"vampire_drain": 0.02,
		"ray_charge_time": 30.0,
		"ray_charged": false,
		"scatter_splits": 4,
	}

	enemies_alive += 1
	elite_spawned_this_wave += 1
	enemy_spawned.emit(enemy_data)


func _spawn_fleet() -> void:
	var fleet_types = [game_data.EnemyType.SABOTEUR, game_data.EnemyType.COMMANDER, game_data.EnemyType.OVERCHARGE]

	for i in range(fleet_count_this_wave):
		if enemies_alive >= game_data.max_enemies_on_screen:
			break

		var f_type = fleet_types[randi() % fleet_types.size()]
		_spawn_fleet_unit(f_type)
		fleet_spawned.emit(f_type, current_wave)

	next_fleet_wave += _get_fleet_frequency()
	_calculate_next_fleet_wave()


func _spawn_fleet_unit(fleet_type: int) -> void:
	var health_mult = _get_enemy_health_multiplier()

	var base_health = game_data.enemy_base_health[fleet_type]
	var base_speed = game_data.enemy_base_speed[fleet_type]

	var wave_health_mult = pow(1.02, current_wave)
	var mass_mult = pow(1.0 + game_data.mass_growth_per_wave, current_wave)

	# Fleets have 20x base health
	var final_health = base_health * 20.0 * health_mult * wave_health_mult * mass_mult
	var final_speed = base_speed

	var enemy_data = {
		"type": fleet_type,
		"health": final_health,
		"max_health": final_health,
		"speed": final_speed,
		"coins": 0,
		"cash": 0,
		"wave": current_wave,
		"tier": current_tier,
		"is_fleet": true,
		"immune_to_orbs": true,
		"immune_to_death_ray": true,
		"immune_to_shockwave": true,
		"immune_to_knockback": true,
		"immune_to_black_hole": true,
		"chrono_thunder_effectiveness": 0.5,
		"thorns_resistance": 0.85,
		"heatup": 0.0,
		"distance_traveled": 0.0,
		# Type-specific
		"saboteur_uw_reduction": 1,
		"commander_buff_stacks": 0,
		"commander_buff_max": 8,
		"commander_buff_mult": 1.15,
		"overcharge_damage_mult": 1.4,
	}

	enemies_alive += 1
	enemy_spawned.emit(enemy_data)


func _check_fleet_spawn() -> void:
	if current_wave >= next_fleet_wave and current_wave > 0:
		var freq = _get_fleet_frequency()
		fleet_count_this_wave = max(1, (current_tier >= 20) ? randi_range(1, 3) : 1)
		_calculate_next_fleet_wave()


func _get_fleet_frequency() -> int:
	if current_tier >= 20:
		return 10
	elif current_tier >= 18:
		return 100
	elif current_tier >= 14:
		return 1000
	else:
		return 100


func _calculate_next_fleet_wave() -> void:
	if current_tier <= 13:
		next_fleet_wave = 15000 - (current_tier - 1) * 250
	elif current_tier == 14:
		next_fleet_wave = 2495
	elif current_tier >= 18:
		next_fleet_wave = 95
	elif current_tier >= 20:
		next_fleet_wave = 5
	else:
		next_fleet_wave = current_wave + _get_fleet_frequency()


func _calculate_elite_cells() -> int:
	if current_tier <= 13:
		return randi_range(1, current_tier + 1)
	else:
		var min_cells = 7 + (current_tier - 14)
		var max_cells = 14 + (current_tier - 14) * 2
		return randi_range(min_cells, max_cells)


func _get_enemy_health_multiplier() -> float:
	var mult = 1.0
	# Workshop/lab enemy health reduction
	var labs = save_manager.save_data.get("labs", {}).get("research", {})
	mult *= 1.0 - labs.get("enemy_health_reduction", 0) * 0.01
	# Battle condition: enemy health
	for cond in active_battle_conditions:
		if cond.id == "enemy_health":
			mult *= 1.0 + cond.value
	return mult


func _get_enemy_speed_multiplier() -> float:
	var mult = 1.0
	var labs = save_manager.save_data.get("labs", {}).get("research", {})
	mult *= 1.0 - labs.get("enemy_speed_reduction", 0) * 0.01
	for cond in active_battle_conditions:
		if cond.id == "enemy_speed":
			mult *= 1.0 + cond.value
	return mult


func _check_tier_milestone() -> void:
	var required_waves = game_data.get_waves_for_tier_milestone(current_tier)
	if current_wave >= required_waves and current_tier < game_data.tier_count:
		_prestige()


func _prestige() -> void:
	current_tier += 1
	current_wave = 0
	save_manager.set("tier", current_tier)
	save_manager.set("wave", 0)
	save_manager.increment_stat("prestiges")

	# Grant tier rewards
	currency_manager.grant_tier_rewards(current_tier)

	# Unlock new battle conditions
	_apply_battle_conditions()

	# Check for tier milestone relic
	var relic_id = "tier_%d_milestone" % current_tier
	if not save_manager.get_relic_owned(relic_id):
		save_manager.add_relic(relic_id)

	tier_upgraded.emit(current_tier)

	# Reset run state
	enemies_alive = 0
	wave_in_progress = false
	wave_timer = game_data.base_wave_interval
	heatup_stacks = 0


func _apply_battle_conditions() -> void:
	active_battle_conditions.clear()

	if current_tier >= game_data.battle_condition_start_tier:
		# Static battle conditions from tier 14+
		# These are simplified - real game has specific values per tier
		active_battle_conditions.append({"id": "death_ray_resist", "value": 0.1 * (current_tier - 13)})
		active_battle_conditions.append({"id": "thorns_resist", "value": 0.1 * (current_tier - 13)})
		active_battle_conditions.append({"id": "enemy_attack_speed", "value": 0.05 * (current_tier - 13)})
		active_battle_conditions.append({"id": "knockback_resist", "value": 0.1 * (current_tier - 13)})
		active_battle_conditions.append({"id": "plasma_cannon_resist", "value": 0.1 * (current_tier - 13)})
		active_battle_conditions.append({"id": "more_enemies", "value": 0.1 * (current_tier - 13)})
		active_battle_conditions.append({"id": "orb_resist", "value": 0.1 * (current_tier - 13)})
		active_battle_conditions.append({"id": "more_bosses", "value": max(0, 10 - (current_tier - 13))})
		active_battle_conditions.append({"id": "more_fleet", "value": 0.0})
		active_battle_conditions.append({"id": "enemy_speed", "value": 0.05 * (current_tier - 13)})

	# Overheat mode at tier 20+
	if current_tier >= 20:
		active_battle_conditions.append({"id": "overheat", "value": 1.0})


func on_enemy_died(enemy_data: Dictionary) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	wave_enemies_killed += 1

	var coins = enemy_data.get("coins", 0)
	var cash = enemy_data.get("cash", 0)
	var cells = enemy_data.get("cells", 0)
	var is_elite = enemy_data.get("is_elite", false)
	var is_boss = enemy_data.get("type") == game_data.EnemyType.BOSS
	var is_fleet = enemy_data.get("is_fleet", false)

	# Heatup
	heatup_stacks += 1

	# Coin decay
	if enemy_data.get("waves_alive", 0) > game_data.coin_decay_after_waves:
		coins = int(coins * game_data.coin_decay_factor)

	# Apply coin/cash multipliers
	coins = int(coins * currency_manager.get_coin_multiplier())
	cash = int(cash * currency_manager.get_cash_multiplier())

	# Add to wave totals
	wave_coins_earned += coins
	wave_cash_earned += cash

	# Grant currencies
	currency_manager.add("coins", coins, "enemy_kill")
	currency_manager.add("cash", cash, "enemy_kill")
	if cells > 0:
		currency_manager.add("elite_cells", cells, "elite_kill")

	# Fleet rewards
	if is_fleet:
		if randf() < 0.8:
			# Reroll shards
			var shards = _calculate_fleet_reroll_shards()
			currency_manager.add("reroll_shards", shards, "fleet_reward")
		else:
			# Module shards
			var shards = _calculate_fleet_module_shards()
			currency_manager.add("module_shards", shards, "fleet_reward")

	save_manager.increment_stat("total_enemies_killed")
	if is_boss:
		save_manager.increment_stat("total_bosses_killed")

	var rewards = {"coins": coins, "cash": cash, "cells": cells}
	enemy_died.emit(enemy_data, rewards)

	# Check wave clear
	if enemies_alive == 0 and wave_in_progress:
		_on_wave_cleared()


func _on_wave_cleared() -> void:
	wave_in_progress = false

	# Interest on cash
	var cash_on_hand = currency_manager.get_currency("cash")
	var interest_rate = workshop_manager.get_total_interest_rate()
	var max_interest = workshop_manager.get_total_max_interest()
	var interest = min(cash_on_hand * interest_rate, max_interest)
	currency_manager.add("cash", int(interest), "interest")

	# Wave clear rewards
	var rewards = {
		"coins": wave_coins_earned,
		"cash": wave_cash_earned,
		"interest": int(interest),
	}

	wave_cleared.emit(current_wave, rewards)

	# Auto-save
	save_manager.save_game()


func on_enemy_reached_tower(enemy_data: Dictionary) -> void:
	enemies_alive = max(0, enemies_alive - 1)

	# Tower takes damage
	var damage = _calculate_enemy_damage(enemy_data)

	# Check for game over (simplified)
	# In real game, tower has health
	if save_manager.get("tower_health", 100) <= damage:
		game_over.emit()
	else:
		save_manager.save_data["tower_health"] = save_manager.get("tower_health", 100) - damage


func _calculate_enemy_damage(enemy_data: Dictionary) -> float:
	var base_damage = 1.0 * enemy_data.get("speed", 1.0)
	# Apply defense
	var def_abs = workshop_manager.get_total_defense_absolute()
	var def_pct = workshop_manager.get_total_defense_percent()
	var damage = max(base_damage - def_abs, base_damage * (1.0 - def_pct))
	return damage


func set_game_speed(speed: float) -> void:
	target_game_speed = clamp(speed, 1.0, game_data.max_game_speed)
	save_manager.set_setting("game_speed", target_game_speed)


func get_game_speed() -> float:
	return game_speed


func get_current_wave() -> int:
	return current_wave


func get_current_tier() -> int:
	return current_tier


func get_heatup_mult() -> float:
	return 1.0 + heatup_stacks * game_data.heatup_per_hit


func _get_card_effect(card_id: String) -> float:
	var cards = save_manager.save_data.get("cards", {}).get("owned", {})
	var stars = cards.get(card_id, 0)
	if stars == 0:
		return 0.0

	# Find card definition
	for cat in [game_data.common_cards, game_data.rare_cards, game_data.epic_cards]:
		for c in cat:
			if c.id == card_id:
				var lv1 = c.lv1
				var lv7 = c.lv7
				return lerp(lv1, lv7, (stars - 1) / 6.0)
	return 0.0


func _get_lab_effect(lab_id: String) -> float:
	var labs = save_manager.save_data.get("labs", {}).get("research", {})
	return labs.get(lab_id, 0)


func force_next_wave() -> void:
	if not wave_in_progress:
		wave_timer = 0.01


func start_run() -> void:
	wave_in_progress = true
	wave_timer = 0.1
	heatup_stacks = 0
	enemies_alive = 0


func end_run() -> void:
	wave_in_progress = false
	enemies_alive = 0
	heatup_stacks = 0
	save_manager.save_game()


func get_wave_progress() -> float:
	if wave_timer <= 0:
		return 1.0
	return 1.0 - (wave_timer / _calculate_wave_interval())


func get_enemies_remaining() -> int:
	return enemies_alive


func get_active_battle_conditions() -> Array[Dictionary]:
	return active_battle_conditions.duplicate()