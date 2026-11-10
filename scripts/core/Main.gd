extends Node2D
class_name Main

@onready var tower: Tower = %Tower
@onready var enemies_container: Node2D = %Enemies
@onready var projectiles_container: Node2D = %Projectiles
@onready var effects_container: Node2D = %Effects
@onready var hud: CanvasLayer = %HUD
@onready var wave_manager: WaveManager = WaveManager
@onready var save_manager: SaveManager = SaveManager
@onready var game_data: GameData = GameData.new()

# Enemy scene reference
@export var enemy_scene: PackedScene
@export var projectile_scene: PackedScene

func _ready() -> void:
	_connect_signals()

	# Add tower to group for easy access
	tower.add_to_group("tower")

	# Start the run
	wave_manager.start_run()


func _connect_signals() -> void:
	# Wave manager signals
	wave_manager.enemy_spawned.connect(_on_enemy_spawned)
	wave_manager.wave_cleared.connect(_on_wave_cleared)
	wave_manager.boss_spawned.connect(_on_boss_spawned)
	wave_manager.tier_upgraded.connect(_on_tier_upgraded)
	wave_manager.game_over.connect(_on_game_over)

	# Tower signals
	tower.projectile_fired.connect(_on_projectile_fired)
	tower.died.connect(_on_tower_died)
	tower.orb_damage.connect(_on_orb_damage)

	# HUD signals (for speed control)
	if hud and hud.has_method("get_speed_slider"):
		var speed_slider = hud.get_speed_slider()
		if speed_slider:
			speed_slider.value_changed.connect(_on_game_speed_changed)


func _on_enemy_spawned(enemy_data: Dictionary) -> void:
	var enemy_instance = enemy_scene.instantiate()
	enemy_instance.initialize(enemy_data)
	enemies_container.add_child(enemy_instance)

	# Connect enemy signals
	enemy_instance.died.connect(_on_enemy_died.bind(enemy_instance))
	enemy_instance.reached_tower.connect(_on_enemy_reached_tower)
	enemy_instance.health_changed.connect(_on_enemy_health_changed)

	# Set target position (tower at origin)
	enemy_instance.target_position = Vector2.ZERO


func _on_enemy_died(enemy: Node, rewards: Dictionary) -> void:
	# Forward to wave manager for reward processing
	wave_manager.on_enemy_died({
		"type": enemy.enemy_type,
		"coins": rewards.get("coins", 0),
		"cash": rewards.get("cash", 0),
		"cells": rewards.get("cells", 0),
		"is_elite": rewards.get("is_elite", false),
		"is_boss": rewards.get("is_boss", false),
		"is_fleet": rewards.get("is_fleet", false),
		"waves_alive": enemy.waves_alive,
	})

	# Spawn death effect
	_spawn_death_effect(enemy.global_position, enemy.get_rarity_color())


func _on_enemy_reached_tower(damage: float) -> void:
	wave_manager.on_enemy_reached_tower({
		"speed": 1.0,  # Simplified
	})

	# Screen shake / visual feedback
	_spawn_impact_effect(Vector2.ZERO)


func _on_enemy_health_changed(percent: float) -> void:
	# Could update health bar on specific enemy
	pass


func _on_projectile_fired(proj_data: Dictionary) -> void:
	var proj_instance = projectile_scene.instantiate()
	proj_instance.initialize(proj_data)
	projectiles_container.add_child(proj_instance)

	# Connect projectile signals
	proj_instance.hit.connect(_on_projectile_hit)
	proj_instance.expired.connect(_on_projectile_expired)


func _on_projectile_hit(enemy: Node, damage: float, info: Dictionary) -> void:
	# Visual hit effect
	_spawn_hit_effect(enemy.global_position, info.get("crit", false))

	# Audio
	if info.get("crit", false):
		AudioManager.play_crit()
	else:
		AudioManager.play_hit()


func _on_projectile_expired() -> void:
	# Projectile expired without hitting
	pass


func _on_wave_cleared(wave: int, rewards: Dictionary) -> void:
	# HUD updates via signals from currency manager
	pass


func _on_boss_spawned(wave: int) -> void:
	UIManager.show_warning("BOSS WAVE %d!" % wave)
	AudioManager.play_boss_spawn()


func _on_tier_upgraded(new_tier: int) -> void:
	UIManager.show_success("Tier %d Reached!" % new_tier)
	AudioManager.play_level_up()


func _on_game_over() -> void:
	UIManager.show_error("GAME OVER")
	wave_manager.end_run()
	# Could show game over screen


func _on_tower_died() -> void:
	UIManager.show_error("Tower Destroyed!")
	wave_manager.end_run()


func _on_orb_damage(enemy: Node, amount: float) -> void:
	# Visual feedback for orb damage
	_spawn_hit_effect(enemy.global_position, false, Color(0.3, 1, 0.8))
	AudioManager.play_orb_hit()


func _on_game_speed_changed(value: float) -> void:
	wave_manager.set_game_speed(value)


func _spawn_hit_effect(position: Vector2, is_crit: bool = false, color: Color = Color(1, 0.9, 0.3)) -> void:
	var effect = Node2D.new()
	effect.global_position = position
	effects_container.add_child(effect)

	var timer = 0.0
	var duration = 0.2

	func _process(delta: float) -> void:
		timer += delta
		var progress = timer / duration
		if progress >= 1.0:
			effect.queue_free()
			return

		var alpha = 1.0 - progress
		var size = 8.0 + progress * 16.0
		effect.draw_circle(Vector2.ZERO, size, Color(color.r, color.g, color.b, alpha))
		if is_crit:
			# Crit sparkle
			for i in 8:
				var angle = (TAU / 8.0) * i + timer * 20
				var p = Vector2(cos(angle), sin(angle)) * size * 1.5
				effect.draw_circle(p, 2, Color(1, 1, 0.3, alpha))

	effect._process = _process


func _spawn_death_effect(position: Vector2, color: Color) -> void:
	var effect = Node2D.new()
	effect.global_position = position
	effects_container.add_child(effect)

	var timer = 0.0
	var duration = 0.4

	func _process(delta: float) -> void:
		timer += delta
		var progress = timer / duration
		if progress >= 1.0:
			effect.queue_free()
			return

		var alpha = 1.0 - progress
		var size = 16.0 + progress * 32.0
		effect.draw_circle(Vector2.ZERO, size, Color(color.r, color.g, color.b, alpha))
		effect.draw_circle(Vector2.ZERO, size * 0.6, Color(1, 1, 1, alpha * 0.5))

	effect._process = _process


func _spawn_impact_effect(position: Vector2) -> void:
	var effect = Node2D.new()
	effect.global_position = position
	effects_container.add_child(effect)

	var timer = 0.0
	var duration = 0.3

	func _process(delta: float) -> void:
		timer += delta
		var progress = timer / duration
		if progress >= 1.0:
			effect.queue_free()
			return

		var alpha = 1.0 - progress
		var size = 40.0 + progress * 60.0
		effect.draw_circle(Vector2.ZERO, size, Color(1, 0.3, 0.3, alpha), false, 4)

	effect._process = _process