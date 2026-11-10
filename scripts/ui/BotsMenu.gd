extends CanvasLayer
class_name BotsMenu

@onready var save_manager: SaveManager = SaveManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var ui_manager: UIManager = UIManager
@onready var game_data: GameData = GameData.new()

@onready var bots_vbox: VBoxContainer = %BotsVBox
@onready var medal_amount: Label = %MedalAmount
@onready var stone_amount: Label = %StoneAmount
@onready var close_btn: Button = %CloseBtn

func _ready() -> void:
	_connect_signals()
	_build_bots()
	_update_currency_display()
	visible = false


func _connect_signals() -> void:
	close_btn.pressed.connect(_close)
	currency_manager.currency_changed.connect(_on_currency_changed)


func _build_bots() -> void:
	for child in bots_vbox.get_children():
		child.queue_free()

	var bot_names = ["Flame", "Thunder", "Golden", "Amplify", "Bot Bot"]
	var unlocked = save_manager.save_data.get("bots", {}).get("unlocked", [])
	var levels = save_manager.save_data.get("bots", {}).get("levels", {})
	var bot_plus = save_manager.save_data.get("bots", {}).get("bot_plus_levels", {})

	for i in 5:
		var name = bot_names[i]
		var is_unlocked = i in unlocked
		var level = levels.get(str(i), 0)
		var bp_level = bot_plus.get(str(i), 0)

		var widget = _create_bot_widget(i, name, is_unlocked, level, bp_level)
		bots_vbox.add_child(widget)


func _create_bot_widget(bot_idx: int, name: String, unlocked: bool, level: int, bp_level: int) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.custom_minimum_size_y = 120

	var frame = PanelContainer.new()
	frame.add_theme_constant_override("margin_top", 8)
	frame.add_theme_constant_override("margin_bottom", 8)
	frame.add_theme_constant_override("margin_left", 8)
	frame.add_theme_constant_override("margin_right", 8)
	frame.v_size_flags = 2
	container.add_child(frame)

	var hbox = HBoxContainer.new()
	hbox.theme_override_constants["h_separation"] = 15
	frame.add_child(hbox)

	# Icon
	var icon = Label.new()
	icon.text = _get_bot_icon(bot_idx)
	icon.horizontal_alignment = 1
	icon.theme_override_font_sizes["font_size"] = 48
	hbox.add_child(icon)

	# Info
	var info_vbox = VBoxContainer.new()
	info_vbox.h_size_flags = 2
	info_vbox.theme_override_constants["v_separation"] = 4
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = "%s Bot" % name
	name_label.horizontal_alignment = 0
	name_label.theme_override_font_sizes["font_size"] = 20
	info_vbox.add_child(name_label)

	if not unlocked:
		var cost = game_data.bot_unlock_costs[bot_idx]
		var unlock_btn = Button.new()
		unlock_btn.text = "Unlock (%d🏅)" % cost
		unlock_btn.custom_minimum_size_y = 35
		info_vbox.add_child(unlock_btn)
		unlock_btn.pressed.connect(_unlock_bot.bind(bot_idx))
	else:
		var level_label = Label.new()
		level_label.text = "Level: %d" % level
		level_label.horizontal_alignment = 0
		level_label.theme_override_font_sizes["font_size"] = 14
		info_vbox.add_child(level_label)

		# Upgrade tracks
		var tracks_hbox = HBoxContainer.new()
		tracks_hbox.theme_override_constants["h_separation"] = 10
		info_vbox.add_child(tracks_hbox)

		var tracks = _get_bot_tracks(bot_idx)
		for track_name in tracks:
			var track_vbox = VBoxContainer.new()
			track_vbox.custom_minimum_size_x = 100
			tracks_hbox.add_child(track_vbox)

			var t_label = Label.new()
			t_label.text = track_name
			t_label.horizontal_alignment = 1
			t_label.theme_override_font_sizes["font_size"] = 10
			track_vbox.add_child(t_label)

			var upgrade_btn = Button.new()
			upgrade_btn.text = "Upgrade"
			upgrade_btn.custom_minimum_size_y = 30
			track_vbox.add_child(upgrade_btn)
			upgrade_btn.pressed.connect(_upgrade_bot_track.bind(bot_idx, track_name))

		# Bot+
		if bp_level > 0 or (level >= 30 and true):  # Simplified
			var bp_label = Label.new()
			bp_label.text = "Bot+: Level %d" % bp_level
			bp_label.horizontal_alignment = 0
			bp_label.add_theme_color_override("font_color", Color(0.7, 0.4, 1))
			bp_label.theme_override_font_sizes["font_size"] = 12
			info_vbox.add_child(bp_label)

			if bp_level < 20:
				var bp_upgrade = Button.new()
				bp_upgrade.text = "Upgrade Bot+ (1250🔮)"
				bp_upgrade.custom_minimum_size_y = 30
				info_vbox.add_child(bp_upgrade)
				bp_upgrade.pressed.connect(_upgrade_bot_plus.bind(bot_idx))

	# Activate button (during run)
	if unlocked:
		var activate_btn = Button.new()
		activate_btn.text = "Activate"
		activate_btn.custom_minimum_size = Vector2(100, 40)
		hbox.add_child(activate_btn)
		activate_btn.pressed.connect(_activate_bot.bind(bot_idx))


func _get_bot_icon(bot_idx: int) -> String:
	var icons = ["🔥", "⚡", "💰", "📈", "🤖"]
	return icons[bot_idx]


func _get_bot_tracks(bot_idx: int) -> Array[String]:
	match bot_idx:
		0: return ["Duration", "Cooldown", "Burn", "Range"]  # Flame
		1: return ["Stun", "Cooldown", "Linger", "Range"]    # Thunder
		2: return ["Duration", "Cooldown", "Coin Mult", "Range"]  # Golden
		3: return ["Duration", "Cooldown", "Dmg Mult", "Range"]   # Amplify
		4: return ["Duration", "Cooldown", "Bonus", "Range"]      # Bot Bot
	return []


func _unlock_bot(bot_idx: int) -> void:
	var cost = game_data.bot_unlock_costs[bot_idx]
	if currency_manager.spend("medals", cost, "bot_unlock"):
		save_manager.unlock_bot(bot_idx)
		AudioManager.play_level_up()
		_build_bots()
		_update_currency_display()


func _upgrade_bot_track(bot_idx: int, track: String) -> void:
	var level = save_manager.get_bot_level(bot_idx)
	if level >= 30:
		return

	# Simplified cost
	var cost = 100 + level * 50
	if currency_manager.spend("medals", cost, "bot_upgrade"):
		save_manager.set_bot_level(bot_idx, level + 1)
		AudioManager.play_upgrade()
		_build_bots()
		_update_currency_display()


func _upgrade_bot_plus(bot_idx: int) -> void:
	var bp_level = save_manager.save_data.get("bots", {}).get("bot_plus_levels", {}).get(str(bot_idx), 0)
	if bp_level >= 20:
		return

	if currency_manager.spend("power_stones", 1250, "bot_plus"):
		save_manager.save_data["bots"]["bot_plus_levels"][str(bot_idx)] = bp_level + 1
		AudioManager.play_level_up()
		_build_bots()
		_update_currency_display()


func _activate_bot(bot_idx: int) -> void:
	var tower = get_tree().get_first_node_in_group("tower")
	if tower:
		tower.activate_bot(bot_idx)


func _update_currency_display() -> void:
	medal_amount.text = ui_manager.format_number(currency_manager.get_currency("medals"))
	stone_amount.text = ui_manager.format_number(currency_manager.get_currency("power_stones"))


func _on_currency_changed(currency: String, old: int, new: int) -> void:
	if currency in ["medals", "power_stones"]:
		_update_currency_display()
		_build_bots()


func _close() -> void:
	visible = false
	UIManager.menu_closed.emit("Bots")


func popup() -> void:
	visible = true
	_update_currency_display()
	_build_bots()
	UIManager.menu_opened.emit("Bots")