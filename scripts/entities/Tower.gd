extends CharacterBody2D
class_name Tower

signal damaged(amount: float)
signal healed(amount: float)
signal died()
signal level_up()
signal uw_activated(uw_index: int)
signal uw_deactivated(uw_index: int)
signal bot_activated(bot_index: int)
signal bot_deactivated(bot_index: int)
signal projectile_fired(projectile_data: Dictionary)
signal orb_damage(enemy: Node, amount: float)

@onready var wave_manager: WaveManager = WaveManager
@onready var workshop_manager: WorkshopManager = WorkshopManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var save_manager: SaveManager = SaveManager
@onready var game_data: GameData = GameData.new()

# Components
var sprite: Node2D = null
var health_bar: Node = null
var range_indicator: Node = null
var orb_container: Node2D = null
var projectile_spawn: Marker2D = null

# Stats
var max_health: float = 1000.0
var current_health: float = 1000.0
var health_regen: float = 5.0
var damage: float = 10.0
var attack_speed: float = 1.0
var attack_cooldown: float = 1.0
var range: float = 300.0
var crit_chance: float = 0.05
var crit_factor: float = 1.5
var damage_per_meter: float = 0.0
var bounce_count: int = 0
var pierce_count: int = 0
var splash_radius: float = 0.0
var splash_damage_mult: float = 0.5
var poison_dps: float = 0.0
var slow_percent: float = 0.0
var stun_chance: float = 0.0
var lifesteal: float = 0.0
var orb_damage_mult: float = 1.0
var orb_speed: float = 1.0
var orb_count: int = 1

# Defense
var defense_absolute: float = 0.0
var defense_percent: float = 0.0
var thorns_damage: float = 0.0
var invincibility_duration: float = 0.0
var invincibility_timer: float = 0.0
var shield_recharge: float = 0.0
var shield_max: float = 0.0
var shield_current: float = 0.0

# Heatup
var heatup_stacks: int = 0
var heatup_mult: float = 1.0

# State
var target: Node = null
var attack_timer: float = 0.0
var is_invincible: bool = false
var second_wind_active: bool = false
var demon_mode_active: bool = false
var demon_mode_timer: float = 0.0
var energy_shield_charges: int = 0
var energy_shield_recharge_timer: float = 0.0

# Orbs
var active_orbs: Array[Dictionary] = []

# UWs
var active_uw: int = -1
var uw_timers: Array[float] = []
var uw_cooldowns: Array[float] = []

# Bots
var active_bots: Array[int] = []
var bot_timers: Array[float] = []
var bot_cooldowns: Array[float] = []

# Perks (current run)
var current_perks: Array[Dictionary] = []

# Visual
var damage_numbers: Array[Dictionary] = []
var hit_flash_timer: float = 0.0
var heal_flash_timer: float = 0.0

func _ready() -> void:
	_init_components()
	_calculate_stats()
	_connect_signals()

	# Start with full health
	current_health = max_health
	shield_current = shield_max

	# Initialize UW cooldowns
	uw_timers.resize(9)
	uw_cooldowns.resize(9)
	for i in 9:
		uw_cooldowns[i] = _get_uw_base_cooldown(i)

	# Initialize bot cooldowns
	bot_timers.resize(5)
	bot_cooldowns.resize(5)
	for i in 5:
		bot_cooldowns[i] = _get_bot_base_cooldown(i)


func _init_components() -> void:
	# Create visual components procedurally
	_create_sprite()
	_create_health_bar()
	_create_range_indicator()
	_create_orb_container()
	_create_projectile_spawn()


func _create_sprite() -> void:
	sprite = Node2D.new()
	sprite.name = "TowerSprite"
	add_child(sprite)
	# Tower body will be drawn in _draw()


func _create_health_bar() -> void:
	health_bar = Node.new()
	health_bar.name = "HealthBar"
	add_child(health_bar)


func _create_range_indicator() -> void:
	range_indicator = Node.new()
	range_indicator.name = "RangeIndicator"
	add_child(range_indicator)


func _create_orb_container() -> void:
	orb_container = Node2D.new()
	orb_container.name = "Orbs"
	add_child(orb_container)


func _create_projectile_spawn() -> void:
	projectile_spawn = Marker2D.new()
	projectile_spawn.name = "ProjectileSpawn"
	projectile_spawn.position = Vector2(0, -40)
	add_child(projectile_spawn)


func _connect_signals() -> void:
	wave_manager.connect("wave_started", _on_wave_started.bind())
	wave_manager.connect("enemy_spawned", _on_enemy_spawned.bind())


func _calculate_stats() -> void:
	# Base stats
	max_health = 1000.0
	health_regen = 5.0
	damage = 10.0
	attack_speed = 1.0
	range = 300.0
	crit_chance = 0.05
	crit_factor = 1.5

	# Workshop multipliers
	max_health *= workshop_manager.get_total_health_mult()
	health_regen *= workshop_manager.get_total_health_regen_mult()
	damage *= workshop_manager.get_total_damage_mult()
	attack_speed *= workshop_manager.get_total_attack_speed_mult()
	crit_factor *= workshop_manager.get_total_crit_factor_mult()
	range *= workshop_manager.get_total_range_mult()

	defense_absolute = workshop_manager.get_total_defense_absolute()
	defense_percent = workshop_manager.get_total_defense_percent()

	# Cards
	_apply_card_effects()

	# Lab effects
	_apply_lab_effects()

	# Module effects
	_apply_module_effects()

	# Relic effects
	_apply_relic_effects()

	# Perk effects
	_apply_perk_effects()

	# Heatup
	heatup_mult = 1.0 + heatup_stacks * game_data.heatup_per_hit
	damage *= heatup_mult

	# Derived
	attack_cooldown = 1.0 / attack_speed

	# Clamp defense percent
	defense_percent = min(defense_percent, game_data.defense_percent_cap)


func _apply_card_effects() -> void:
	var cards = save_manager.save_data.get("cards", {}).get("owned", {})
	var slots = save_manager.save_data.get("cards", {}).get("slots", [])

	for slot_id in slots:
		var stars = cards.get(slot_id, 0)
		if stars == 0:
			continue

		# Find card definition
		var card_def = _find_card_def(slot_id)
		if not card_def:
			continue

		var lv1 = card_def.lv1
		var lv7 = card_def.lv7
		var value = lerp(lv1, lv7, (stars - 1) / 6.0)
		var effect = card_def.effect

		match effect:
			"tower_damage_mult": damage *= value
			"attack_speed_mult": attack_speed *= value
			"tower_health_mult": max_health *= value
			"health_regen_mult": health_regen *= value
			"range_mult": range *= value
			"cash_mult": pass  # Handled in currency manager
			"coin_mult": pass
			"slow_percent": slow_percent += value
			"crit_chance": crit_chance += value
			"enemy_spawn_mult": pass  # Handled in wave manager
			"defense_percent": defense_percent += value
			"defense_absolute": defense_absolute += value
			"free_upgrade_chance": pass
			"extra_orb_speed": orb_speed = value
			"plasma_boss_damage": pass
			"crit_coin_chance": pass
			"wave_skip_chance": pass
			"intro_sprint_waves": pass
			"mine_stun_duration": pass
			"recovery_spawn_chance": pass
			"cells_bonus": pass
			"death_ray_duration": pass
			"energy_net_duration": pass
			"super_tower_damage_mult": pass
			"second_wind_shield": pass
			"demon_mode_duration": pass
			"energy_shield_recharge": pass
			"wave_cd_reduction": pass
			"berserker_damage_per_absorbed": pass
			"uw_crit_chance": pass
			"nuke_percent": pass
			"aoe_damage_mult": splash_damage_mult *= value


func _apply_lab_effects() -> void:
	var labs = save_manager.save_data.get("labs", {}).get("research", {})

	# Attack labs
	damage *= 1.0 + labs.get("damage", 0) * 0.02  # x3 at max
	attack_speed *= 1.0 + labs.get("attack_speed", 0) * 0.02
	crit_factor *= 1.0 + labs.get("crit_factor", 0) * 0.03
	range *= 1.0 + labs.get("range", 0) * 0.016
	damage_per_meter = labs.get("damage_per_meter", 0) * 0.03

	# Defense labs
	max_health *= 1.0 + labs.get("health", 0) * 0.03
	health_regen *= 1.0 + labs.get("health_regen", 0) * 0.03
	defense_absolute += labs.get("defense_absolute", 0) * 10.0
	defense_percent += labs.get("defense_percent", 0) * 0.002
	orb_speed += labs.get("orb_speed", 0) * 0.1

	# Utility labs
	# ... cash/coin multipliers handled elsewhere


func _apply_module_effects() -> void:
	# Module effects would be applied here
	pass


func _apply_relic_effects() -> void:
	# Relic effects would be applied here
	pass


func _apply_perk_effects() -> void:
	for perk in current_perks:
		# Apply perk effects
		pass


func _find_card_def(card_id: String) -> Dictionary:
	for cat in [game_data.common_cards, game_data.rare_cards, game_data.epic_cards]:
		for c in cat:
			if c.id == card_id:
				return c
	return null


func _process(delta: float) -> void:
	_update_timers(delta)
	_update_orbs(delta)
	_update_uws(delta)
	_update_bots(delta)
	_update_regen(delta)
	_update_targeting()
	_update_attack(delta)
	_update_visuals(delta)


func _update_timers(delta: float) -> void:
	if invincibility_timer > 0:
		invincibility_timer -= delta
		is_invincible = invincibility_timer > 0

	if demon_mode_timer > 0:
		demon_mode_timer -= delta
		if demon_mode_timer <= 0:
			demon_mode_active = false

	if hit_flash_timer > 0:
		hit_flash_timer -= delta

	if heal_flash_timer > 0:
		heal_flash_timer -= delta

	if energy_shield_recharge_timer > 0:
		energy_shield_recharge_timer -= delta
		elif shield_current < shield_max:
			shield_current = min(shield_max, shield_current + shield_recharge * delta)


func _update_orbs(delta: float) -> void:
	var target_orb_count = orb_count + (1 if _has_card("extra_orb") else 0)

	# Add/remove orbs
	while active_orbs.size() < target_orb_count:
		active_orbs.append({
			"angle": randf() * TAU,
			"speed": orb_speed * 2.0,
			"radius": range * 0.8,
			"damage": damage * 0.3 * orb_damage_mult,
		})

	while active_orbs.size() > target_orb_count:
		active_orbs.pop_back()

	# Update orb positions
	for orb in active_orbs:
		orb.angle += orb.speed * delta
		if orb.angle >= TAU:
			orb.angle -= TAU


func _update_uws(delta: float) -> void:
	for i in 9:
		if uw_timers[i] > 0:
			uw_timers[i] -= delta
			if uw_timers[i] <= 0:
				_deactivate_uw(i)

		if uw_cooldowns[i] > 0:
			uw_cooldowns[i] -= delta


func _update_bots(delta: float) -> void:
	for i in 5:
		if bot_timers[i] > 0:
			bot_timers[i] -= delta
			if bot_timers[i] <= 0:
				_deactivate_bot(i)

		if bot_cooldowns[i] > 0:
			bot_cooldowns[i] -= delta


func _update_regen(delta: float) -> void:
	if current_health < max_health:
		var regen = health_regen * delta
		current_health = min(max_health, current_health + regen)


func _update_targeting() -> void:
	# Find nearest enemy in range
	# This would query the wave manager for enemies
	# For now, simplified
	if target and not _is_valid_target(target):
		target = null

	if not target:
		target = _find_nearest_enemy()


func _is_valid_target(enemy: Node) -> bool:
	if not enemy or not enemy.is_inside_tree():
		return false
	var dist = global_position.distance_to(enemy.global_position)
	return dist <= range


func _find_nearest_enemy() -> Node:
	# Would query wave manager for enemies
	# Placeholder
	return null


func _update_attack(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta
		return

	if not target:
		return

	# Fire projectile
	_fire_projectile()
	attack_timer = attack_cooldown


func _fire_projectile() -> void:
	var proj_data = {
		"damage": damage,
		"crit_chance": crit_chance,
		"crit_factor": crit_factor,
		"pierce": pierce_count,
		"bounce": bounce_count,
		"splash_radius": splash_radius,
		"splash_damage_mult": splash_damage_mult,
		"poison_dps": poison_dps,
		"slow_percent": slow_percent,
		"stun_chance": stun_chance,
		"lifesteal": lifesteal,
		"damage_per_meter": damage_per_meter,
		"speed": 800.0,
		"target": target,
		"start_pos": projectile_spawn.global_position,
		"owner": self,
	}

	projectile_fired.emit(proj_data)

	# Visual feedback
	hit_flash_timer = 0.1


func take_damage(amount: float) -> float:
	if is_invincible:
		return 0.0

	# Apply defense
	var final_damage = max(amount - defense_absolute, amount * (1.0 - defense_percent))
	final_damage = max(final_damage, 1.0)  # Minimum 1 damage

	# Energy shield
	if shield_current > 0:
		var absorbed = min(shield_current, final_damage)
		shield_current -= absorbed
		final_damage -= absorbed
		energy_shield_recharge_timer = 5.0  # Recharge delay

	if final_damage <= 0:
		return 0.0

	current_health -= final_damage
	damaged.emit(final_damage)
	hit_flash_timer = 0.2

	# Thorns
	if thorns_damage > 0 and target:
		target.call_deferred("take_damage", thorns_damage)

	# Check death
	if current_health <= 0:
		current_health = 0
		died.emit()

	return final_damage


func heal(amount: float) -> void:
	var old = current_health
	current_health = min(max_health, current_health + amount)
	var actual = current_health - old
	if actual > 0:
		healed.emit(actual)
		heal_flash_timer = 0.3


func add_heatup() -> void:
	heatup_stacks += 1
	heatup_mult = 1.0 + heatup_stacks * game_data.heatup_per_hit
	damage *= (1.0 + game_data.heatup_per_hit)


func activate_uw(uw_index: int) -> bool:
	if uw_index < 0 or uw_index >= 9:
		return false
	if uw_timers[uw_index] > 0 or uw_cooldowns[uw_index] > 0:
		return false
	if not save_manager.save_data.get("ultimate_weapons", {}).get("owned", []).has(uw_index):
		return false

	uw_timers[uw_index] = _get_uw_duration(uw_index)
	uw_cooldowns[uw_index] = _get_uw_cooldown(uw_index)
	active_uw = uw_index
	uw_activated.emit(uw_index)

	# Visual/audio
	AudioManager.play_uw_activate()
	return true


func _deactivate_uw(uw_index: int) -> void:
	if active_uw == uw_index:
		active_uw = -1
	uw_deactivated.emit(uw_index)


func _get_uw_duration(index: int) -> float:
	var base_durations = [15, 15, 10, 20, 10, 15, 15, 20, 30]
	var level = save_manager.get_uw_level(index)
	# Duration increases with level
	return base_durations[index] * (1.0 + level * 0.05)


func _get_uw_cooldown(index: int) -> float:
	var base_cds = [300, 200, 300, 120, 180, 180, 180, 200, 125]
	var level = save_manager.get_uw_level(index)
	return base_cds[index] * (1.0 - level * 0.02)


func _get_uw_base_cooldown(index: int) -> float:
	var base_cds = [300, 200, 300, 120, 180, 180, 180, 200, 125]
	return base_cds[index]


func activate_bot(bot_index: int) -> bool:
	if bot_index < 0 or bot_index >= 5:
		return false
	if bot_timers[bot_index] > 0 or bot_cooldowns[bot_index] > 0:
		return false
	if bot_index not in save_manager.save_data.get("bots", {}).get("unlocked", []):
		return false

	bot_timers[bot_index] = _get_bot_duration(bot_index)
	bot_cooldowns[bot_index] = _get_bot_cooldown(bot_index)
	active_bots.append(bot_index)
	bot_activated.emit(bot_index)

	AudioManager.play_bot_activate()
	return true


func _deactivate_bot(bot_index: int) -> void:
	active_bots.erase(bot_index)
	bot_deactivated.emit(bot_index)


func _get_bot_duration(index: int) -> float:
	var base = [20, 20, 20, 20, 20]
	var level = save_manager.get_bot_level(index)
	return base[index] + level * 0.75


func _get_bot_cooldown(index: int) -> float:
	var base = [75, 120, 120, 120, 120]
	var level = save_manager.get_bot_level(index)
	return max(base[index] - level * 1.8, 30)


func _get_bot_base_cooldown(index: int) -> float:
	var base = [75, 120, 120, 120, 120]
	return base[index]


func _has_card(card_id: String) -> bool:
	var cards = save_manager.save_data.get("cards", {}).get("owned", {})
	return cards.get(card_id, 0) > 0


func get_health_percent() -> float:
	return current_health / max_health if max_health > 0 else 0.0


func get_shield_percent() -> float:
	return shield_current / shield_max if shield_max > 0 else 0.0


func get_uw_cooldown_percent(uw_index: int) -> float:
	if uw_index < 0 or uw_index >= 9:
		return 1.0
	var base = _get_uw_base_cooldown(uw_index)
	if base <= 0:
		return 1.0
	return 1.0 - (uw_cooldowns[uw_index] / base)


func get_uw_active_percent(uw_index: int) -> float:
	if uw_index < 0 or uw_index >= 9:
		return 0.0
	var base = _get_uw_duration(uw_index)
	if base <= 0:
		return 0.0
	return uw_timers[uw_index] / base


func get_bot_cooldown_percent(bot_index: int) -> float:
	if bot_index < 0 or bot_index >= 5:
		return 1.0
	var base = _get_bot_base_cooldown(bot_index)
	if base <= 0:
		return 1.0
	return 1.0 - (bot_cooldowns[bot_index] / base)


func get_bot_active_percent(bot_index: int) -> float:
	if bot_index < 0 or bot_index >= 5:
		return 0.0
	var base = _get_bot_duration(bot_index)
	if base <= 0:
		return 0.0
	return bot_timers[bot_index] / base


func _on_wave_started(wave: int) -> void:
	# Reset heatup at wave start? No, heatup persists
	pass


func _on_enemy_spawned(enemy_data: Dictionary) -> void:
	# Could track for targeting
	pass


func _draw() -> void:
	# Draw tower body
	var game_data = GameData.new()

	# Base
	draw_circle(Vector2(0, 0), 35, game_data.color_tower)
	draw_circle(Vector2(0, 0), 35, game_data.color_ui_border, false, 3)

	# Core
	draw_circle(Vector2(0, 0), 20, game_data.color_tower_core)
	draw_circle(Vector2(0, 0), 20, game_data.color_ui_accent, false, 2)

	# Health indicator ring
	var hp_pct = get_health_percent()
	if hp_pct < 1.0:
		draw_arc(Vector2(0, 0), 42, -PI/2, -PI/2 + TAU * hp_pct, 10, game_data.color_ui_green)

	# Shield indicator
	var shield_pct = get_shield_percent()
	if shield_pct > 0:
		draw_arc(Vector2(0, 0), 48, -PI/2, -PI/2 + TAU * shield_pct, 6, game_data.color_ui_accent)

	# Active UW indicator
	if active_uw >= 0:
		var uw_color = _get_uw_color(active_uw)
		draw_circle(Vector2(0, 0), 55, uw_color, false, 3)

	# Active bot indicators
	for i, bot in enumerate(active_bots):
		var angle = -PI/2 + (TAU / active_bots.size()) * i
		var pos = Vector2(cos(angle), sin(angle)) * 60
		var bot_color = _get_bot_color(bot)
		draw_circle(pos, 8, bot_color)
		draw_circle(pos, 8, bot_color.darkened(0.3), false, 2)

	# Orbs
	for orb in active_orbs:
		var pos = Vector2(cos(orb.angle), sin(orb.angle)) * orb.radius
		draw_circle(pos, 6, game_data.color_ui_accent)
		draw_circle(pos, 6, game_data.color_ui_accent.darkened(0.3), false, 1.5)

	# Hit flash
	if hit_flash_timer > 0:
		var alpha = hit_flash_timer / 0.2
		draw_circle(Vector2(0, 0), 40, Color(1, 0.3, 0.3, alpha))

	# Heal flash
	if heal_flash_timer > 0:
		var alpha = heal_flash_timer / 0.3
		draw_circle(Vector2(0, 0), 40, Color(0.3, 1, 0.3, alpha))

	# Demon mode visual
	if demon_mode_active:
		var t = (sin(Time.get_ticks_msec() * 0.01) + 1) * 0.5
		draw_circle(Vector2(0, 0), 50 + t * 10, Color(1, 0.2, 0.2, 0.3 * t), false, 4)

	# Energy shield visual
	if shield_current > 0:
		var pct = get_shield_percent()
		draw_arc(Vector2(0, 0), 52, -PI/2, -PI/2 + TAU * pct, 8, Color(0.3, 0.7, 1, 0.6))


func _get_uw_color(index: int) -> Color:
	var colors = [
		Color(1, 0.8, 0.2),   # Golden Tower
		Color(0.3, 0.2, 0.6), # Black Hole
		Color(0.8, 0.2, 0.2), # Death Wave
		Color(1, 1, 0.5),     # Spotlight
		Color(0.2, 0.6, 1),   # Chrono Field
		Color(0.3, 1, 0.8),   # Chain Lightning
		Color(0.8, 0.4, 1),   # Smart Missiles
		Color(0.6, 0.2, 0.8), # Inner Land Mines
		Color(0.2, 0.8, 0.4), # Poison Swamp
	]
	return colors[index]


func _get_bot_color(index: int) -> Color:
	var colors = [
		Color(1, 0.4, 0.1),   # Flame
		Color(0.3, 0.8, 1),   # Thunder
		Color(1, 0.8, 0.2),   # Golden
		Color(0.8, 0.3, 1),   # Amplify
		Color(0.5, 0.5, 0.5), # Bot Bot
	]
	return colors[index]


# --- Public API ---

func set_perks(perks: Array[Dictionary]) -> void:
	current_perks = perks.duplicate()
	_calculate_stats()


func force_recalculate_stats() -> void:
	_calculate_stats()