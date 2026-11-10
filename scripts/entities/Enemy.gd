extends CharacterBody2D
class_name Enemy

signal died(rewards: Dictionary)
signal reached_tower(damage: float)
signal health_changed(percent: float)

@onready var wave_manager: WaveManager = WaveManager
@onready var game_data: GameData = GameData.new()

# Enemy data (set on spawn)
var enemy_type: int = 0
var max_health: float = 100.0
var current_health: float = 100.0
var speed: float = 50.0
var coins: int = 1
var cash: int = 1
var cells: int = 0
var wave: int = 1
var tier: int = 1
var shield: float = 0.0
var is_elite: bool = false
var is_boss: bool = false
var is_fleet: bool = false
var immune_to_orbs: bool = false
var immune_to_death_ray: bool = false
var immune_to_shockwave: bool = false
var immune_to_knockback: bool = false
var immune_to_black_hole: bool = false

# Type-specific properties
var vampire_drain: float = 0.02
var ray_charge_time: float = 30.0
var ray_charged: bool = false
var ray_charge_timer: float = 0.0
var scatter_splits: int = 4
var scatter_split_count: int = 0

# Fleet-specific
var saboteur_uw_reduction: int = 1
var commander_buff_stacks: int = 0
var commander_buff_max: int = 8
var commander_buff_mult: float = 1.15
var overcharge_damage_mult: float = 1.4

# State
var distance_traveled: float = 0.0
var heatup: float = 0.0
var waves_alive: int = 0
var target_position: Vector2 = Vector2.ZERO
var is_stunned: bool = false
var stun_timer: float = 0.0
var is_slowed: bool = false
var slow_timer: float = 0.0
var slow_mult: float = 1.0
var poison_stacks: int = 0
var poison_timer: float = 0.0
var poison_dps: float = 0.0
var knockback_resistance: float = 0.0
var mass: float = 1.0
var commander_buff: float = 1.0
var enflamed: bool = false
var enflame_timer: float = 0.0
var enflame_damage_mult: float = 1.0

# Visual
var sprite_color: Color = Color.WHITE
var hit_flash_timer: float = 0.0
var death_anim_timer: float = 0.0
var is_dying: bool = false
var scale_mult: float = 1.0

func _ready() -> void:
	_setup_visuals()


func _setup_visuals() -> void:
	# Set color based on type
	match enemy_type:
		game_data.EnemyType.BASIC: sprite_color = game_data.color_enemy_basic
		game_data.EnemyType.FAST: sprite_color = game_data.color_enemy_fast
		game_data.EnemyType.TANK: sprite_color = game_data.color_enemy_tank
		game_data.EnemyType.RANGED: sprite_color = game_data.color_enemy_ranged
		game_data.EnemyType.PROTECTOR: sprite_color = game_data.color_enemy_protector
		game_data.EnemyType.BOSS: sprite_color = game_data.color_enemy_boss
		game_data.EnemyType.VAMPIRE: sprite_color = game_data.color_enemy_elite
		game_data.EnemyType.RAY: sprite_color = game_data.color_enemy_elite
		game_data.EnemyType.SCATTER: sprite_color = game_data.color_enemy_elite
		game_data.EnemyType.SABOTEUR: sprite_color = Color(0.9, 0.5, 0.2)
		game_data.EnemyType.COMMANDER: sprite_color = Color(0.6, 0.3, 0.9)
		game_data.EnemyType.OVERCHARGE: sprite_color = Color(0.2, 0.8, 1.0)

	# Scale based on health
	scale_mult = clamp(sqrt(max_health / 100.0) * 0.8, 0.5, 3.0)
	scale = Vector2.ONE * scale_mult


func initialize(data: Dictionary) -> void:
	enemy_type = data.get("type", 0)
	max_health = data.get("health", 100.0)
	current_health = max_health
	speed = data.get("speed", 50.0)
	coins = data.get("coins", 1)
	cash = data.get("cash", 1)
	cells = data.get("cells", 0)
	wave = data.get("wave", 1)
	tier = data.get("tier", 1)
	shield = data.get("shield", 0.0)
	is_elite = data.get("is_elite", false)
	is_boss = data.get("type") == game_data.EnemyType.BOSS
	is_fleet = data.get("is_fleet", false)
	immune_to_orbs = data.get("immune_to_orbs", false)
	immune_to_death_ray = data.get("immune_to_death_ray", false)
	immune_to_shockwave = data.get("immune_to_shockwave", false)
	immune_to_knockback = data.get("immune_to_knockback", false)
	immune_to_black_hole = data.get("immune_to_black_hole", false)

	# Type-specific
	vampire_drain = data.get("vampire_drain", 0.02)
	ray_charge_time = data.get("ray_charge_time", 30.0)
	scatter_splits = data.get("scatter_splits", 4)
	saboteur_uw_reduction = data.get("saboteur_uw_reduction", 1)
	commander_buff_max = data.get("commander_buff_max", 8)
	commander_buff_mult = data.get("commander_buff_mult", 1.15)
	overcharge_damage_mult = data.get("overcharge_damage_mult", 1.4)

	distance_traveled = 0.0
	heatup = 0.0
	waves_alive = 0
	target_position = Vector2.ZERO

	_setup_visuals()


func _process(delta: float) -> void:
	if is_dying:
		_update_death_anim(delta)
		return

	_update_timers(delta)
	_update_movement(delta)
	_update_effects(delta)
	_update_visuals(delta)


func _update_timers(delta: float) -> void:
	if stun_timer > 0:
		stun_timer -= delta
		is_stunned = stun_timer > 0

	if slow_timer > 0:
		slow_timer -= delta
		is_slowed = slow_timer > 0

	if hit_flash_timer > 0:
		hit_flash_timer -= delta

	if ray_charge_timer > 0:
		ray_charge_timer -= delta
		if ray_charge_timer <= 0 and not ray_charged:
			ray_charged = true
			# Visual change when charged

	if enflame_timer > 0:
		enflame_timer -= delta
		enflamed = enflame_timer > 0

	if poison_timer > 0:
		poison_timer -= delta
		if poison_timer <= 0:
			poison_stacks = 0


func _update_movement(delta: float) -> void:
	if is_stunned:
		velocity = Vector2.ZERO
		return

	# Move toward tower (at origin)
	var direction = (target_position - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = -global_position.normalized()

	var current_speed = speed * slow_mult
	velocity = direction * current_speed
	move_and_slide()

	distance_traveled += current_speed * delta


func _update_effects(delta: float) -> void:
	# Poison damage
	if poison_stacks > 0:
		take_damage(poison_dps * delta, {"source": "poison"})

	# Enflame damage (Flame bot)
	if enflamed:
		take_damage(poison_dps * delta * enflame_damage_mult, {"source": "enflame"})

	# Vampire drain (if this is a vampire)
	if enemy_type == game_data.EnemyType.VAMPIRE and target_position != Vector2.ZERO:
		# Would need reference to tower to drain
		pass

	# Ray charge
	if enemy_type == game_data.EnemyType.RAY and not ray_charged:
		ray_charge_timer += delta
		if ray_charge_timer >= ray_charge_time:
			ray_charged = true

	# Commander buff aura
	if enemy_type == game_data.EnemyType.COMMANDER:
		# Would apply to nearby fleet units
		pass


func _update_visuals(delta: float) -> void:
	# Scale pulse when hit
	if hit_flash_timer > 0:
		var pulse = 1.0 + sin(hit_flash_timer * 50) * 0.1
		scale = Vector2.ONE * scale_mult * pulse
	else:
		scale = Vector2.ONE * scale_mult


func _update_death_anim(delta: float) -> void:
	death_anim_timer += delta
	var progress = death_anim_timer / 0.5
	scale = Vector2.ONE * scale_mult * (1.0 - progress)
	modulate = Color(1, 1, 1, 1.0 - progress)

	if progress >= 1.0:
		queue_free()


func take_damage(amount: float, info: Dictionary = {}) -> float:
	if is_dying:
		return 0.0

	var source = info.get("source", "")
	var is_crit = info.get("crit", false)
	var pierce = info.get("pierce", 0)
	var bounce = info.get("bounce", 0)
	var splash = info.get("splash", false)
	var knockback = info.get("knockback", 0.0)
	var damage_per_meter = info.get("damage_per_meter", 0.0)

	# Heatup bonus
	heatup += game_data.heatup_per_hit

	# Damage per meter
	if damage_per_meter > 0:
		amount += distance_traveled * damage_per_meter

	# Shield (protector)
	if shield > 0:
		var shield_absorb = min(shield, amount * 0.6)  # 60% reduction
		amount -= shield_absorb
		shield -= shield_absorb * 0.1

	# Defense would be applied by tower before calling this

	# Minimum damage
	amount = max(amount, 1.0)

	# Apply damage
	current_health -= amount

	# Hit flash
	hit_flash_timer = 0.1

	# Lifesteal would be handled by tower

	# Check death
	if current_health <= 0:
		_die(info)
		return amount

	# Knockback
	if knockback > 0 and not immune_to_knockback:
		var kb_dir = (global_position - info.get("source_pos", global_position)).normalized()
		if kb_dir != Vector2.ZERO:
			velocity = kb_dir * knockback * (1.0 - knockback_resistance)
			move_and_slide()

	health_changed.emit(current_health / max_health)
	return amount


func _die(info: Dictionary) -> void:
	is_dying = true
	death_anim_timer = 0.0

	# Scatter split
	if enemy_type == game_data.EnemyType.SCATTER and scatter_split_count < scatter_splits:
		_split_scatter()

	# Rewards
	var rewards = {
		"coins": coins,
		"cash": cash,
		"cells": cells,
		"type": enemy_type,
		"is_elite": is_elite,
		"is_boss": is_boss,
		"is_fleet": is_fleet,
	}

	died.emit(rewards)

	# Saboteur effect
	if enemy_type == game_data.EnemyType.SABOTEUR:
		# Reduce UW level - would need tower reference
		pass

	# Commander death - buff nearby
	if enemy_type == game_data.EnemyType.COMMANDER:
		# Would apply final buff
		pass

	# Overcharge death shot
	if enemy_type == game_data.EnemyType.OVERCHARGE:
		# Final projectile
		pass


func _split_scatter() -> void:
	scatter_split_count += 1
	if scatter_split_count >= scatter_splits:
		return

	# Create 4 smaller scatter enemies
	for i in 4:
		var angle = (TAU / 4.0) * i
		var offset = Vector2(cos(angle), sin(angle)) * 30.0
		# Would spawn new enemy via wave manager
		pass


func apply_stun(duration: float) -> void:
	if is_boss or is_elite:
		duration *= 0.5  # Reduced effectiveness
		if is_fleet:
			duration *= 0.5  # Fleet further reduced

	stun_timer = max(stun_timer, duration)
	is_stunned = true


func apply_slow(percent: float, duration: float) -> void:
	slow_mult = 1.0 - percent
	slow_timer = max(slow_timer, duration)
	is_slowed = true


func apply_poison(dps: float, duration: float, stacks: int = 1) -> void:
	poison_dps = max(poison_dps, dps)
	poison_stacks += stacks
	poison_timer = max(poison_timer, duration)


func apply_enflame(dps: float, duration: float, damage_mult: float = 1.0) -> void:
	enflamed = true
	enflame_timer = max(enflame_timer, duration)
	enflame_damage_mult = max(enflame_damage_mult, damage_mult)
	poison_dps = max(poison_dps, dps)
	poison_timer = max(poison_timer, duration)


func apply_knockback(force: float, source_pos: Vector2) -> void:
	if immune_to_knockback:
		return

	var kb_dir = (global_position - source_pos).normalized()
	if kb_dir != Vector2.ZERO:
		velocity = kb_dir * force * (1.0 - knockback_resistance)
		move_and_slide()


func apply_commander_buff() -> void:
	if enemy_type != game_data.EnemyType.COMMANDER:
		commander_buff_stacks = min(commander_buff_stacks + 1, commander_buff_max)
		commander_buff = pow(commander_buff_mult, commander_buff_stacks)
		# Apply to health/speed/damage
		max_health *= commander_buff_mult
		current_health *= commander_buff_mult
		speed *= commander_buff_mult


func on_wave_end() -> void:
	waves_alive += 1
	# Mass growth
	mass *= 1.0 + game_data.mass_growth_per_wave
	max_health *= 1.0 + game_data.mass_growth_per_wave
	current_health = min(max_health, current_health * (1.0 + game_data.mass_growth_per_wave))

	# Coin decay
	if waves_alive > game_data.coin_decay_after_waves:
		coins = int(coins * game_data.coin_decay_factor)


func get_health_percent() -> float:
	return current_health / max_health if max_health > 0 else 0.0


func get_type_name() -> String:
	match enemy_type:
		game_data.EnemyType.BASIC: return "Basic"
		game_data.EnemyType.FAST: return "Fast"
		game_data.EnemyType.TANK: return "Tank"
		game_data.EnemyType.RANGED: return "Ranged"
		game_data.EnemyType.PROTECTOR: return "Protector"
		game_data.EnemyType.BOSS: return "Boss"
		game_data.EnemyType.VAMPIRE: return "Vampire"
		game_data.EnemyType.RAY: return "Ray"
		game_data.EnemyType.SCATTER: return "Scatter"
		game_data.EnemyType.SABOTEUR: return "Saboteur"
		game_data.EnemyType.COMMANDER: return "Commander"
		game_data.EnemyType.OVERCHARGE: return "Overcharge"
	return "Unknown"


func get_rarity_color() -> Color:
	if is_boss:
		return Color(1, 0.2, 0.2)
	if is_elite:
		return Color(0.8, 0.2, 0.8)
	if is_fleet:
		return Color(0.9, 0.5, 0.2)
	return sprite_color


func _draw() -> void:
	# Body
	var body_color = sprite_color
	if hit_flash_timer > 0:
		body_color = body_color.lerp(Color(1, 1, 1), hit_flash_timer / 0.1)

	if is_dying:
		body_color.a = 1.0 - (death_anim_timer / 0.5)

	# Base shape based on type
	var radius = 16.0 * scale_mult

	if is_boss:
		# Boss - larger, multi-layered
		draw_circle(Vector2(0, 0), radius * 1.5, body_color)
		draw_circle(Vector2(0, 0), radius * 1.5, body_color.darkened(0.3), false, 3)
		# Core
		draw_circle(Vector2(0, 0), radius * 0.8, body_color.lightened(0.3))
		# Spikes
		for i in 8:
			var angle = (TAU / 8.0) * i
			var p1 = Vector2(cos(angle), sin(angle)) * radius * 1.5
			var p2 = Vector2(cos(angle), sin(angle)) * radius * 2.0
			draw_line(p1, p2, body_color, 3)
	elif is_fleet:
		# Fleet - hexagonal
		draw_polygon(_get_hexagon_points(radius), [body_color])
		draw_polygon(_get_hexagon_points(radius), [], [body_color.darkened(0.3)], 3)
		# Center mark
		draw_circle(Vector2(0, 0), radius * 0.4, body_color.lightened(0.3))
	elif is_elite:
		# Elite - diamond shape
		draw_polygon(_get_diamond_points(radius), [body_color])
		draw_polygon(_get_diamond_points(radius), [], [body_color.darkened(0.3)], 2)
		# Elite marker
		draw_circle(Vector2(0, -radius - 5), 4, Color(1, 1, 0))
	else:
		# Normal - circle
		draw_circle(Vector2(0, 0), radius, body_color)
		draw_circle(Vector2(0, 0), radius, body_color.darkened(0.3), false, 1.5)
		# Type indicator
		_draw_type_indicator(radius)

	# Shield visual
	if shield > 0:
		var shield_pct = shield / 100.0  # Normalized
		draw_arc(Vector2(0, 0), radius + 5, -PI/2, -PI/2 + TAU * shield_pct, 4, Color(0.3, 0.7, 1, 0.7))

	# Status effects
	_draw_status_effects(radius)

	# Health bar (small, above enemy)
	if current_health < max_health:
		var bar_w = 30 * scale_mult
		var bar_h = 4
		var bar_pos = Vector2(-bar_w/2, -radius - 12)
		draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.2, 0.2, 0.2))
		draw_rect(Rect2(bar_pos, Vector2(bar_w * get_health_percent(), bar_h)), Color(0.3, 1, 0.3))

	# Ray charge indicator
	if enemy_type == game_data.EnemyType.RAY and not ray_charged:
		var charge_pct = ray_charge_timer / ray_charge_time
		draw_arc(Vector2(0, 0), radius + 8, -PI/2, -PI/2 + TAU * charge_pct, 3, Color(1, 0.5, 0, 0.8))

	# Commander buff stacks
	if commander_buff_stacks > 0:
		for i in commander_buff_stacks:
			var angle = (TAU / commander_buff_max) * i
			var pos = Vector2(cos(angle), sin(angle)) * (radius + 10)
			draw_circle(pos, 3, Color(0.6, 0.3, 0.9))


func _get_hexagon_points(radius: float) -> Array[Vector2]:
	var points = []
	for i in 6:
		var angle = -PI/2 + (TAU / 6.0) * i
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _get_diamond_points(radius: float) -> Array[Vector2]:
	return [
		Vector2(0, -radius),
		Vector2(radius, 0),
		Vector2(0, radius),
		Vector2(-radius, 0),
	]


func _draw_type_indicator(radius: float) -> void:
	# Small indicator for enemy type
	match enemy_type:
		game_data.EnemyType.FAST:
			# Double arrow
			draw_line(Vector2(-4, -2), Vector2(0, 2), Color(1,1,1), 1.5)
			draw_line(Vector2(0, 2), Vector2(4, -2), Color(1,1,1), 1.5)
			draw_line(Vector2(-4, 2), Vector2(0, -2), Color(1,1,1), 1.5)
			draw_line(Vector2(0, -2), Vector2(4, 2), Color(1,1,1), 1.5)
		game_data.EnemyType.TANK:
			# Shield shape
			draw_polygon([Vector2(-5, -3), Vector2(5, -3), Vector2(5, 5), Vector2(0, 8), Vector2(-5, 5)], [Color(1,1,1,0.8)])
		game_data.EnemyType.RANGED:
			# Bow shape
			draw_arc(Vector2(0, 0), 6, PI*0.2, PI*0.8, 1.5, Color(1,1,1,0.8))
		game_data.EnemyType.PROTECTOR:
			# Shield icon
			draw_polygon([Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(0, 7), Vector2(-4, 4)], [Color(0.5,0.5,0.5,0.8)])
		game_data.EnemyType.VAMPIRE:
			# Bat wings
			draw_line(Vector2(-6, -2), Vector2(0, 0), Color(1,0.2,0.2), 2)
			draw_line(Vector2(0, 0), Vector2(6, -2), Color(1,0.2,0.2), 2)
			draw_line(Vector2(-6, 2), Vector2(0, 0), Color(1,0.2,0.2), 2)
			draw_line(Vector2(0, 0), Vector2(6, 2), Color(1,0.2,0.2), 2)
		game_data.EnemyType.RAY:
			# Lightning bolt
			draw_polyline([Vector2(-3, -6), Vector2(0, 0), Vector2(-3, 0), Vector2(3, 6)], Color(1,0.8,0.2), 2)
		game_data.EnemyType.SCATTER:
			# Split icon
			draw_line(Vector2(0, 0), Vector2(-5, -5), Color(1,1,1,0.8), 1.5)
			draw_line(Vector2(0, 0), Vector2(5, -5), Color(1,1,1,0.8), 1.5)
			draw_line(Vector2(0, 0), Vector2(-5, 5), Color(1,1,1,0.8), 1.5)
			draw_line(Vector2(0, 0), Vector2(5, 5), Color(1,1,1,0.8), 1.5)


func _draw_status_effects(radius: float) -> void:
	var y_offset = -radius - 20
	var icon_size = 8

	if is_stunned:
		draw_circle(Vector2(0, y_offset), icon_size, Color(1, 0.8, 0.2))
		draw_line(Vector2(-4, y_offset), Vector2(4, y_offset), Color(0,0,0), 2)
		draw_line(Vector2(0, y_offset-4), Vector2(0, y_offset+4), Color(0,0,0), 2)
		y_offset -= icon_size * 2 + 2

	if is_slowed:
		draw_circle(Vector2(0, y_offset), icon_size, Color(0.3, 0.7, 1))
		draw_line(Vector2(-4, y_offset), Vector2(4, y_offset), Color(0,0,0), 2)
		y_offset -= icon_size * 2 + 2

	if poison_stacks > 0:
		draw_circle(Vector2(0, y_offset), icon_size, Color(0.3, 1, 0.3))
		# Poison bubbles
		draw_circle(Vector2(-2, y_offset-2), 2, Color(0.3, 1, 0.3, 0.6))
		draw_circle(Vector2(2, y_offset-2), 2, Color(0.3, 1, 0.3, 0.6))
		y_offset -= icon_size * 2 + 2

	if enflamed:
		draw_circle(Vector2(0, y_offset), icon_size, Color(1, 0.4, 0.1))
		# Flame
		draw_polygon([Vector2(-3, y_offset+3), Vector2(0, y_offset-3), Vector2(3, y_offset+3)], [Color(1, 0.4, 0.1, 0.8)])
		y_offset -= icon_size * 2 + 2