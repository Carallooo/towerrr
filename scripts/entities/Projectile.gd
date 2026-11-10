extends Node2D
class_name Projectile

signal hit(enemy: Node, damage: float, info: Dictionary)
signal expired()

@onready var game_data: GameData = GameData.new()

# Projectile properties
var damage: float = 10.0
var speed: float = 800.0
var pierce: int = 0
var bounce: int = 0
var splash_radius: float = 0.0
var splash_damage_mult: float = 0.5
var poison_dps: float = 0.0
var poison_duration: float = 5.0
var slow_percent: float = 0.0
var slow_duration: float = 3.0
var stun_chance: float = 0.0
var stun_duration: float = 1.0
var lifesteal: float = 0.0
var damage_per_meter: float = 0.0
var crit_chance: float = 0.05
var crit_factor: float = 1.5
var is_crit: bool = false

# Targeting
var target: Node = null
var start_pos: Vector2 = Vector2.ZERO
var owner: Node = null
var homing: bool = false
var homing_strength: float = 5.0

# Visual
var color: Color = Color(1, 0.9, 0.3)
var trail_color: Color = Color(1, 0.9, 0.3, 0.5)
var size: float = 4.0
var trail_length: float = 20.0
var is_laser: bool = false
var laser_duration: float = 0.1
var laser_timer: float = 0.0

# State
var distance_traveled: float = 0.0
var hit_enemies: Array[Node] = []
var bounce_count: int = 0
var pierce_count: int = 0
var is_exploding: bool = false
var explode_timer: float = 0.0
var angle: float = 0.0

func _ready() -> void:
	_setup_visuals()
	angle = velocity.angle() if velocity.length() > 0 else 0


func initialize(data: Dictionary) -> void:
	damage = data.get("damage", 10.0)
	speed = data.get("speed", 800.0)
	pierce = data.get("pierce", 0)
	bounce = data.get("bounce", 0)
	splash_radius = data.get("splash_radius", 0.0)
	splash_damage_mult = data.get("splash_damage_mult", 0.5)
	poison_dps = data.get("poison_dps", 0.0)
	slow_percent = data.get("slow_percent", 0.0)
	stun_chance = data.get("stun_chance", 0.0)
	lifesteal = data.get("lifesteal", 0.0)
	damage_per_meter = data.get("damage_per_meter", 0.0)
	crit_chance = data.get("crit_chance", 0.05)
	crit_factor = data.get("crit_factor", 1.5)

	target = data.get("target")
	start_pos = data.get("start_pos", global_position)
	owner = data.get("owner")

	# Determine if crit
	is_crit = randf() < crit_chance
	if is_crit:
		damage *= crit_factor
		color = Color(1, 1, 0.3)
		trail_color = Color(1, 1, 0.3, 0.6)
		size *= 1.5

	# Set velocity toward target
	if target and target.is_inside_tree():
		var dir = (target.global_position - global_position).normalized()
		velocity = dir * speed
		angle = velocity.angle()
	else:
		velocity = Vector2(0, -speed)  # Default upward
		angle = -PI/2

	_setup_visuals()


func _setup_visuals() -> void:
	# Visual setup based on type
	if is_laser:
		# Laser visual
		pass


func _process(delta: float) -> void:
	if is_exploding:
		_update_explosion(delta)
		return

	_move(delta)
	_check_collision()
	_check_bounds()


func _move(delta: float) -> void:
	if is_laser:
		laser_timer += delta
		if laser_timer >= laser_duration:
			queue_free()
		return

	# Homing
	if homing and target and target.is_inside_tree():
		var target_dir = (target.global_position - global_position).normalized()
		var current_dir = velocity.normalized()
		var new_dir = current_dir.lerp(target_dir, homing_strength * delta)
		velocity = new_dir * speed
		angle = velocity.angle()

	move_and_slide()
	distance_traveled += velocity.length() * delta


func _check_collision() -> void:
	# Check collision with enemies
	# This would use Area2D or direct collision detection
	# For now, simplified - would need enemy group/query
	pass


func _on_body_entered(body: Node) -> void:
	if body == owner or body in hit_enemies:
		return

	if body.has_method("take_damage"):
		_on_hit_enemy(body)


func _on_hit_enemy(enemy: Node) -> void:
	var info = {
		"crit": is_crit,
		"pierce": pierce - pierce_count,
		"bounce": bounce - bounce_count,
		"splash": splash_radius > 0,
		"knockback": 0.0,
		"damage_per_meter": damage_per_meter,
		"source_pos": global_position,
	}

	# Lifesteal
	if lifesteal > 0 and owner and owner.has_method("heal"):
		owner.heal(damage * lifesteal)

	# Apply damage
	var actual_damage = enemy.take_damage(damage, info)

	hit.emit(enemy, actual_damage, info)
	hit_enemies.append(enemy)

	# Pierce
	if pierce_count < pierce:
		pierce_count += 1
		return

	# Bounce
	if bounce_count < bounce:
		_try_bounce()
		return

	# Splash
	if splash_radius > 0:
		_explode()
		return

	# Poison/slow/stun would be applied by enemy.take_damage

	# Destroy projectile
	queue_free()


func _try_bounce() -> void:
	# Find nearest enemy not yet hit
	# Simplified - would query enemy group
	bounce_count += 1

	# Redirect toward new target
	if target and target.is_inside_tree():
		var dir = (target.global_position - global_position).normalized()
		velocity = dir * speed
		angle = velocity.angle()


func _explode() -> void:
	is_exploding = true
	explode_timer = 0.0
	velocity = Vector2.ZERO

	# Damage enemies in radius
	# Would query enemies in radius

	# Visual explosion
	AudioManager.play_hit(0.8)


func _update_explosion(delta: float) -> void:
	explode_timer += delta
	if explode_timer >= 0.3:
		queue_free()


func _check_bounds() -> void:
	# Destroy if too far from origin
	if global_position.distance_to(Vector2.ZERO) > 2000:
		queue_free()


func _draw() -> void:
	if is_laser:
		_draw_laser()
	elif is_exploding:
		_draw_explosion()
	else:
		_draw_projectile()


func _draw_projectile() -> void:
	# Trail
	if trail_length > 0:
		var trail_end = -velocity.normalized() * trail_length
		draw_line(Vector2.ZERO, trail_end, trail_color, size * 0.5)

	# Main projectile
	if is_crit:
		# Crit - star shape
		draw_polygon(_get_star_points(size), [color])
		draw_polygon(_get_star_points(size), [], [color.darkened(0.3)], 1.5)
	else:
		# Normal - circle with glow
		draw_circle(Vector2.ZERO, size, color)
		draw_circle(Vector2.ZERO, size, color.darkened(0.3), false, 1)

	# Damage per meter indicator
	if damage_per_meter > 0:
		draw_line(Vector2(-size, size), Vector2(size, -size), Color(1, 0.5, 0, 0.8), 2)


func _draw_laser() -> void:
	if not target or not target.is_inside_tree():
		return

	var target_pos = to_local(target.global_position)
	var dist = target_pos.length()

	# Laser beam
	draw_line(Vector2.ZERO, target_pos, color, size * 2)
	draw_line(Vector2.ZERO, target_pos, color.lightened(0.5), size)

	# End point
	draw_circle(target_pos, size * 2, color)


func _draw_explosion() -> void:
	var progress = explode_timer / 0.3
	var radius = splash_radius * progress
	var alpha = 1.0 - progress

	draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, alpha))
	draw_circle(Vector2.ZERO, radius * 0.7, Color(1, 1, 1, alpha * 0.5))

	# Particles
	for i in 12:
		var angle = (TAU / 12.0) * i + progress * TAU * 2
		var p = Vector2(cos(angle), sin(angle)) * radius * (0.5 + randf() * 0.5)
		draw_circle(p, size * (1.0 - progress), Color(color.r, color.g, color.b, alpha))


func _get_star_points(radius: float) -> Array[Vector2]:
	var points = []
	for i in 10:
		var angle = -PI/2 + (TAU / 10.0) * i
		var r = radius if i % 2 == 0 else radius * 0.5
		points.append(Vector2(cos(angle), sin(angle)) * r)
	return points


# --- Special Projectile Types ---

func make_orbiting(duration: float, radius: float, damage: float) -> void:
	# For orbs
	is_laser = false
	# Would implement orbiting logic
	pass


func make_homing(strength: float = 5.0) -> void:
	homing = true
	homing_strength = strength


func make_piercing(pierce_count: int) -> void:
	pierce = pierce_count


func make_bouncing(bounce_count: int) -> void:
	bounce = bounce_count


func make_splash(radius: float, damage_mult: float = 0.5) -> void:
	splash_radius = radius
	splash_damage_mult = damage_mult


func make_poison(dps: float, duration: float = 5.0) -> void:
	poison_dps = dps
	poison_duration = duration


func make_slow(percent: float, duration: float = 3.0) -> void:
	slow_percent = percent
	slow_duration = duration


func make_stun(chance: float, duration: float = 1.0) -> void:
	stun_chance = chance
	stun_duration = duration