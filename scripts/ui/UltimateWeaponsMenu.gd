extends CanvasLayer
class_name UltimateWeaponsMenu

@onready var save_manager: SaveManager = SaveManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var ui_manager: UIManager = UIManager
@onready var game_data: GameData = GameData.new()

@onready var uw_grid: GridContainer = %UWGrid
@onready var stone_amount: Label = %StoneAmount
@onready var close_btn: Button = %CloseBtn

func _ready() -> void:
	_connect_signals()
	_build_uws()
	_update_currency_display()
	visible = false


func _connect_signals() -> void:
	close_btn.pressed.connect(_close)
	currency_manager.currency_changed.connect(_on_currency_changed)


func _build_uws() -> void:
	for child in uw_grid.get_children():
		child.queue_free()

	var owned = save_manager.save_data.get("ultimate_weapons", {}).get("owned", [])
	var levels = save_manager.save_data.get("ultimate_weapons", {}).get("levels", {})
	var uw_plus = save_manager.save_data.get("ultimate_weapons", {}).get("uw_plus_levels", {})
	var active = save_manager.save_data.get("ultimate_weapons", {}).get("active_uw", -1)

	for i in 9:
		var name = game_data.uw_names[i]
		var is_owned = i in owned
		var level = levels.get(str(i), 0)
		var plus_level = uw_plus.get(str(i), 0)
		var is_active = (i == active)

		var widget = _create_uw_widget(i, name, is_owned, level, plus_level, is_active)
		uw_grid.add_child(widget)


func _create_uw_widget(uw_idx: int, name: String, owned: bool, level: int, plus_level: int, active: bool) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(200, 180)

	var frame = PanelContainer.new()
	if active:
		frame.add_theme_constant_override("border_color", Color(0.2, 0.8, 1))
		frame.add_theme_constant_override("border_width", 3)
	frame.add_theme_constant_override("margin_top", 8)
	frame.add_theme_constant_override("margin_bottom", 8)
	frame.add_theme_constant_override("margin_left", 8)
	frame.add_theme_constant_override("margin_right", 8)
	frame.v_size_flags = 2
	container.add_child(frame)

	var vbox = VBoxContainer.new()
	vbox.theme_override_constants["v_separation"] = 6
	frame.add_child(vbox)

	# Icon
	var icon = Label.new()
	icon.text = _get_uw_icon(uw_idx)
	icon.horizontal_alignment = 1
	icon.theme_override_font_sizes["font_size"] = 32
	vbox.add_child(icon)

	# Name
	var name_label = Label.new()
	name_label.text = name
	name_label.horizontal_alignment = 1
	name_label.theme_override_font_sizes["font_size"] = 16
	vbox.add_child(name_label)

	if not owned:
		var cost = game_data.uw_unlock_costs[uw_idx]
		var unlock_btn = Button.new()
		unlock_btn.text = "Unlock (%d🔮)" % cost
		unlock_btn.custom_minimum_size_y = 35
		vbox.add_child(unlock_btn)
		unlock_btn.pressed.connect(_unlock_uw.bind(uw_idx))
	else:
		var level_label = Label.new()
		level_label.text = "Level %d" % level
		level_label.horizontal_alignment = 1
		level_label.theme_override_font_sizes["font_size"] = 14
		vbox.add_child(level_label)

		if plus_level > 0:
			var plus_label = Label.new()
			plus_label.text = "UW+: Level %d" % plus_level
			plus_label.horizontal_alignment = 1
			plus_label.add_theme_color_override("font_color", Color(0.7, 0.4, 1))
			plus_label.theme_override_font_sizes["font_size"] = 12
			vbox.add_child(plus_label)

		# Upgrade button
		var upgrade_btn = Button.new()
		upgrade_btn.text = "Upgrade"
		upgrade_btn.custom_minimum_size_y = 30
		vbox.add_child(upgrade_btn)
		upgrade_btn.pressed.connect(_upgrade_uw.bind(uw_idx))

		# UW+ upgrade
		if plus_level < 14:
			var plus_btn = Button.new()
			plus_btn.text = "UW+ Upgrade"
			plus_btn.custom_minimum_size_y = 25
			vbox.add_child(plus_btn)
			plus_btn.pressed.connect(_upgrade_uw_plus.bind(uw_idx))

		# Activate/Deactivate
		var act_btn = Button.new()
		act_btn.text = active ? "Active" : "Activate"
		act_btn.custom_minimum_size_y = 30
		act_btn.disabled = active
		vbox.add_child(act_btn)
		act_btn.pressed.connect(_activate_uw.bind(uw_idx))

	if active:
		var active_label = Label.new()
		active_label.text = "⚡ ACTIVE ⚡"
		active_label.horizontal_alignment = 1
		active_label.add_theme_color_override("font_color", Color(0.2, 1, 0.5))
		active_label.theme_override_font_sizes["font_size"] = 12
		vbox.add_child(active_label)


func _get_uw_icon(uw_idx: int) -> String:
	var icons = ["🏛️", "🕳️", "🌊", "🔦", "⏳", "⚡", "🚀", "💣", "☠️"]
	return icons[uw_idx]


func _unlock_uw(uw_idx: int) -> void:
	var cost = game_data.uw_unlock_costs[uw_idx]
	if currency_manager.spend("power_stones", cost, "uw_unlock"):
		var owned = save_manager.save_data["ultimate_weapons"]["owned"]
		owned.append(uw_idx)
		AudioManager.play_level_up()
		_build_uws()
		_update_currency_display()


func _upgrade_uw(uw_idx: int) -> void:
	# Simplified cost calculation
	var level = save_manager.get_uw_level(uw_idx)
	var cost = game_data.uw_unlock_costs[uw_idx] * (level + 1) * 2
	if currency_manager.spend("power_stones", cost, "uw_upgrade"):
		save_manager.set_uw_level(uw_idx, level + 1)
		AudioManager.play_upgrade()
		_build_uws()
		_update_currency_display()


func _upgrade_uw_plus(uw_idx: int) -> void:
	var plus_level = save_manager.save_data.get("ultimate_weapons", {}).get("uw_plus_levels", {}).get(str(uw_idx), 0)
	if plus_level >= 14:
		return

	var costs = [500, 625, 750, 975, 1250, 1650, 2200, 2900, 3800]
	if currency_manager.spend("power_stones", costs[plus_level], "uw_plus"):
		save_manager.save_data["ultimate_weapons"]["uw_plus_levels"][str(uw_idx)] = plus_level + 1
		AudioManager.play_level_up()
		_build_uws()
		_update_currency_display()


func _activate_uw(uw_idx: int) -> void:
	save_manager.save_data["ultimate_weapons"]["active_uw"] = uw_idx

	var tower = get_tree().get_first_node_in_group("tower")
	if tower:
		tower.activate_uw(uw_idx)

	_build_uws()


func _update_currency_display() -> void:
	stone_amount.text = ui_manager.format_number(currency_manager.get_currency("power_stones"))


func _on_currency_changed(currency: String, old: int, new: int) -> void:
	if currency == "power_stones":
		_update_currency_display()
		_build_uws()


func _close() -> void:
	visible = false
	UIManager.menu_closed.emit("UltimateWeapons")


func popup() -> void:
	visible = true
	_update_currency_display()
	_build_uws()
	UIManager.menu_opened.emit("UltimateWeapons")