extends CanvasLayer
class_name HUD

@onready var wave_manager: WaveManager = WaveManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var workshop_manager: WorkshopManager = WorkshopManager
@onready var save_manager: SaveManager = SaveManager
@onready var ui_manager: UIManager = UIManager
@onready var tower: Tower = get_tree().get_first_node_in_group("tower") or get_parent().get_node_or_null("Tower")

# UI References
@onready var tier_label: Label = %TierLabel
@onready var wave_label: Label = %WaveLabel
@onready var cash_amount: Label = %CashAmount
@onready var coins_amount: Label = %CoinsAmount
@onready var gems_amount: Label = %GemsAmount
@onready var speed_label: Label = %SpeedLabel
@onready var speed_slider: HSlider = %SpeedSlider
@onready var wave_timer_bar: ProgressBar = %WaveTimer
@onready var enemy_count_label: Label = %EnemyCount
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_text: Label = %HealthText
@onready var shield_bar: ProgressBar = %ShieldBar
@onready var damage_text: Label = %DamageText
@onready var uw_indicators: HBoxContainer = %UWIndicators
@onready var bot_indicators: HBoxContainer = %BotIndicators
@onready var notifications: VBoxContainer = %Notifications

# Menu buttons
@onready var btn_workshop: Button = %BtnWorkshop
@onready var btn_labs: Button = %BtnLabs
@onready var btn_cards: Button = %BtnCards
@onready var btn_modules: Button = %BtnModules
@onready var btn_bots: Button = %BtnBots
@onready var btn_uw: Button = %BtnUW
@onready var btn_relics: Button = %BtnRelics
@onready var btn_vault: Button = %BtnVault
@onready var btn_guardian: Button = %BtnGuardian
@onready var btn_tournament: Button = %BtnTournament
@onready var btn_guild: Button = %BtnGuild
@onready var btn_events: Button = %BtnEvents
@onready var btn_settings: Button = %BtnSettings

func _ready() -> void:
	_connect_signals()
	_connect_buttons()
	_update_all()

	# Get tower reference
	if not tower:
		tower = get_parent().get_node_or_null("Tower")


func _connect_signals() -> void:
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_cleared.connect(_on_wave_cleared)
	wave_manager.tier_upgraded.connect(_on_tier_upgraded)
	wave_manager.enemy_spawned.connect(_on_enemy_spawned)
	wave_manager.enemy_died.connect(_on_enemy_died)

	currency_manager.currency_changed.connect(_on_currency_changed)

	ui_manager.notification_show.connect(_show_notification)

	if tower:
		tower.damaged.connect(_on_tower_damaged)
		tower.healed.connect(_on_tower_healed)
		tower.uw_activated.connect(_on_uw_activated)
		tower.uw_deactivated.connect(_on_uw_deactivated)
		tower.bot_activated.connect(_on_bot_activated)
		tower.bot_deactivated.connect(_on_bot_deactivated)


func _connect_buttons() -> void:
	btn_workshop.pressed.connect(_open_workshop)
	btn_labs.pressed.connect(_open_labs)
	btn_cards.pressed.connect(_open_cards)
	btn_modules.pressed.connect(_open_modules)
	btn_bots.pressed.connect(_open_bots)
	btn_uw.pressed.connect(_open_uw)
	btn_relics.pressed.connect(_open_relics)
	btn_vault.pressed.connect(_open_vault)
	btn_guardian.pressed.connect(_open_guardian)
	btn_tournament.pressed.connect(_open_tournament)
	btn_guild.pressed.connect(_open_guild)
	btn_events.pressed.connect(_open_events)
	btn_settings.pressed.connect(_open_settings)

	speed_slider.value_changed.connect(_on_speed_changed)


func get_speed_slider() -> HSlider:
	return speed_slider


func _process(delta: float) -> void:
	_update_wave_timer()
	_update_enemy_count()
	_update_tower_stats()
	_update_uw_indicators()
	_update_bot_indicators()
	_update_notifications(delta)


func _update_all() -> void:
	_update_tier_wave()
	_update_currencies()
	_update_game_speed()


func _update_tier_wave() -> void:
	tier_label.text = "Tier %d" % wave_manager.get_current_tier()
	wave_label.text = "Wave %d" % wave_manager.get_current_wave()


func _update_currencies() -> void:
	cash_amount.text = ui_manager.format_number(currency_manager.get_currency("cash"))
	coins_amount.text = ui_manager.format_number(currency_manager.get_currency("coins"))
	gems_amount.text = ui_manager.format_number(currency_manager.get_currency("gems"))


func _update_game_speed() -> void:
	var speed = wave_manager.get_game_speed()
	speed_label.text = "Speed: %.1fx" % speed
	speed_slider.value = speed


func _update_wave_timer() -> void:
	wave_timer_bar.value = wave_manager.get_wave_progress()


func _update_enemy_count() -> void:
	enemy_count_label.text = "Enemies: %d" % wave_manager.get_enemies_remaining()


func _update_tower_stats() -> void:
	if not tower:
		return

	health_bar.value = tower.get_health_percent()
	health_text.text = "%d / %d" % [int(tower.current_health), int(tower.max_health)]

	shield_bar.value = tower.get_shield_percent()
	shield_bar.visible = tower.shield_max > 0

	damage_text.text = "DMG: %.1f | AS: %.1f/s | Range: %.0f" % [tower.damage, tower.attack_speed, tower.range]


func _update_uw_indicators() -> void:
	if not tower:
		return

	# Clear old indicators
	for child in uw_indicators.get_children():
		child.queue_free()

	# Show active UWs
	for i in 9:
		if tower.uw_timers[i] > 0:
			var indicator = _create_uw_indicator(i, tower.get_uw_active_percent(i))
			uw_indicators.add_child(indicator)


func _update_bot_indicators() -> void:
	if not tower:
		return

	for child in bot_indicators.get_children():
		child.queue_free()

	for i in 5:
		if tower.bot_timers[i] > 0:
			var indicator = _create_bot_indicator(i, tower.get_bot_active_percent(i))
			bot_indicators.add_child(indicator)
		elif tower.bot_cooldowns[i] > 0:
			var indicator = _create_bot_indicator(i, -tower.get_bot_cooldown_percent(i))
			bot_indicators.add_child(indicator)


func _create_uw_indicator(index: int, progress: float) -> Control:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("h_separation", 2)

	var icon = Label.new()
	icon.text = _get_uw_icon(index)
	icon.theme_override_font_sizes["font_size"] = 16
	container.add_child(icon)

	var bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 1
	bar.value = progress
	bar.custom_minimum_size = Vector2(40, 6)
	container.add_child(bar)

	return container


func _create_bot_indicator(index: int, progress: float) -> Control:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("h_separation", 2)

	var icon = Label.new()
	icon.text = _get_bot_icon(index)
	icon.theme_override_font_sizes["font_size"] = 14
	container.add_child(icon)

	var bar = ProgressBar.new()
	bar.min_value = -1
	bar.max_value = 1
	bar.value = progress
	bar.custom_minimum_size = Vector2(35, 5)
	container.add_child(bar)

	return container


func _get_uw_icon(index: int) -> String:
	var icons = ["🏛️", "🕳️", "🌊", "🔦", "⏳", "⚡", "🚀", "💣", "☠️"]
	return icons[index]


func _get_bot_icon(index: int) -> String:
	var icons = ["🔥", "⚡", "💰", "📈", "🤖"]
	return icons[index]


func _update_notifications(delta: float) -> void:
	for child in notifications.get_children():
		if child.has_method("update"):
			child.update(delta)


# --- Signal Handlers ---

func _on_wave_started(wave: int) -> void:
	_update_tier_wave()


func _on_wave_cleared(wave: int, rewards: Dictionary) -> void:
	_update_tier_wave()
	_update_currencies()

	# Show reward notification
	var msg = "Wave %d cleared! Coins: %s | Cash: %s" % [
		wave,
		ui_manager.format_number(rewards.get("coins", 0)),
		ui_manager.format_number(rewards.get("cash", 0)),
	]
	_show_notification(msg, "success")


func _on_tier_upgraded(new_tier: int) -> void:
	_update_tier_wave()
	_show_notification("Tier %d reached! Prestige bonuses unlocked!" % new_tier, "success", 5.0)
	AudioManager.play_prestige()


func _on_enemy_spawned(enemy_data: Dictionary) -> void:
	_update_enemy_count()


func _on_enemy_died(enemy_data: Dictionary, rewards: Dictionary) -> void:
	_update_enemy_count()


func _on_currency_changed(currency: String, old: int, new: int) -> void:
	_update_currencies()


func _on_tower_damaged(amount: float) -> void:
	_update_tower_stats()
	_show_notification("Tower hit for %.0f!" % amount, "warning", 1.5)


func _on_tower_healed(amount: float) -> void:
	_update_tower_stats()
	_show_notification("Healed %.0f" % amount, "success", 1.0)


func _on_uw_activated(index: int) -> void:
	var names = ["Golden Tower", "Black Hole", "Death Wave", "Spotlight", "Chrono Field", "Chain Lightning", "Smart Missiles", "Inner Mines", "Poison Swamp"]
	_show_notification("%s ACTIVATED!" % names[index], "info", 3.0)


func _on_uw_deactivated(index: int) -> void:
	pass


func _on_bot_activated(index: int) -> void:
	var names = ["Flame Bot", "Thunder Bot", "Golden Bot", "Amplify Bot", "Bot Bot"]
	_show_notification("%s deployed!" % names[index], "info", 2.0)


func _on_bot_deactivated(index: int) -> void:
	pass


func _on_speed_changed(value: float) -> void:
	wave_manager.set_game_speed(value)
	speed_label.text = "Speed: %.1fx" % value


func _show_notification(message: String, type: String = "info", duration: float = 3.0) -> void:
	var notif = Notification.new()
	notif.initialize(message, type, duration)
	notifications.add_child(notif)
	notif.move_child(notif, 0)  # Top


# --- Menu Openers ---

func _open_workshop() -> void:
	ui_manager.open_menu("Workshop")
	get_parent().get_node("Menus/WorkshopMenu").visible = true


func _open_labs() -> void:
	ui_manager.open_menu("Labs")
	get_parent().get_node("Menus/LabsMenu").visible = true


func _open_cards() -> void:
	ui_manager.open_menu("Cards")
	get_parent().get_node("Menus/CardsMenu").visible = true


func _open_modules() -> void:
	ui_manager.open_menu("Modules")
	get_parent().get_node("Menus/ModulesMenu").visible = true


func _open_bots() -> void:
	ui_manager.open_menu("Bots")
	get_parent().get_node("Menus/BotsMenu").visible = true


func _open_uw() -> void:
	ui_manager.open_menu("UltimateWeapons")
	get_parent().get_node("Menus/UltimateWeaponsMenu").visible = true


func _open_relics() -> void:
	ui_manager.open_menu("Relics")
	get_parent().get_node("Menus/RelicsMenu").visible = true


func _open_vault() -> void:
	ui_manager.open_menu("Vault")
	get_parent().get_node("Menus/VaultMenu").visible = true


func _open_guardian() -> void:
	ui_manager.open_menu("Guardian")
	get_parent().get_node("Menus/GuardianMenu").visible = true


func _open_tournament() -> void:
	ui_manager.open_menu("Tournament")
	get_parent().get_node("Menus/TournamentMenu").visible = true


func _open_guild() -> void:
	ui_manager.open_menu("Guild")
	get_parent().get_node("Menus/GuildMenu").visible = true


func _open_events() -> void:
	ui_manager.open_menu("Events")
	get_parent().get_node("Menus/EventsMenu").visible = true


func _open_settings() -> void:
	ui_manager.open_menu("Settings")
	get_parent().get_node("Menus/SettingsMenu").visible = true