extends CanvasLayer
class_name WorkshopMenu

@onready var workshop_manager: WorkshopManager = WorkshopManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var ui_manager: UIManager = UIManager

# UI References
@onready var tab_bar: TabBar = %TabBar
@onready var attack_container: VBoxContainer = %AttackContainer
@onready var defense_container: VBoxContainer = %DefenseContainer
@onready var utility_container: VBoxContainer = %UtilityContainer
@onready var enhancements_container: VBoxContainer = %EnhancementsContainer
@onready var coin_amount: Label = %CoinAmount
@onready var cash_amount: Label = %CashAmount
@onready var permanent_btn: Button = %PermanentBtn
@onready var temporary_btn: Button = %TemporaryBtn
@onready var close_btn: Button = %CloseBtn

var current_category: String = "attack"
var is_permanent: bool = true
var upgrade_widgets: Dictionary = {}

func _ready() -> void:
	_connect_signals()
	_build_all_tabs()
	_update_currency_display()
	visible = false


func _connect_signals() -> void:
	tab_bar.tab_changed.connect(_on_tab_changed)
	close_btn.pressed.connect(_close)
	permanent_btn.toggled.connect(_on_mode_changed)
	temporary_btn.toggled.connect(_on_mode_changed)

	workshop_manager.workshop_changed.connect(_on_workshop_changed)
	currency_manager.currency_changed.connect(_on_currency_changed)


func _build_all_tabs() -> void:
	_build_tab("attack", attack_container)
	_build_tab("defense", defense_container)
	_build_tab("utility", utility_container)
	_build_tab("enhancements", enhancements_container)


func _build_tab(category: String, container: VBoxContainer) -> void:
	var upgrades = workshop_manager.get_upgrades(category)

	for upgrade in upgrades:
		var widget = _create_upgrade_widget(category, upgrade)
		container.add_child(widget)
		upgrade_widgets["%s_%s" % [category, upgrade.id]] = widget


func _create_upgrade_widget(category: String, upgrade: Dictionary) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("h_separation", 10)
	container.custom_minimum_size_y = 50

	# Icon/Name
	var name_label = Label.new()
	name_label.text = upgrade.name
	name_label.custom_minimum_size_x = 180
	name_label.theme_override_font_sizes["font_size"] = 16
	name_label.tooltip_text = upgrade.desc
	container.add_child(name_label)

	# Level
	var level_label = Label.new()
	level_label.custom_minimum_size_x = 80
	level_label.horizontal_alignment = 1
	level_label.theme_override_font_sizes["font_size"] = 16
	container.add_child(level_label)

	# Effect
	var effect_label = Label.new()
	effect_label.custom_minimum_size_x = 120
	effect_label.horizontal_alignment = 1
	effect_label.theme_override_font_sizes["font_size"] = 14
	container.add_child(effect_label)

	# Cost
	var cost_label = Label.new()
	cost_label.custom_minimum_size_x = 100
	cost_label.horizontal_alignment = 1
	cost_label.theme_override_font_sizes["font_size"] = 14
	container.add_child(cost_label)

	# Buy button
	var buy_btn = Button.new()
	buy_btn.text = "Buy"
	buy_btn.custom_minimum_size = Vector2(80, 40)
	buy_btn.disabled = true
	container.add_child(buy_btn)

	# Max level indicator
	var max_label = Label.new()
	max_label.text = "MAX"
	max_label.custom_minimum_size_x = 80
	max_label.horizontal_alignment = 1
	max_label.theme_override_font_sizes["font_size"] = 16
	max_label.visible = false
	container.add_child(max_label)

	# Store references
	widget_data = {
		"upgrade": upgrade,
		"category": category,
		"level_label": level_label,
		"effect_label": effect_label,
		"cost_label": cost_label,
		"buy_btn": buy_btn,
		"max_label": max_label,
	}
	container.set_meta("widget_data", widget_data)

	# Connect button
	buy_btn.pressed.connect(_on_buy_pressed.bind(category, upgrade.id))

	# Initial update
	_update_widget(container)

	return container


func _update_widget(widget: HBoxContainer) -> void:
	var data = widget.get_meta("widget_data")
	var upgrade = data.upgrade
	var category = data.category

	var level = workshop_manager.get_level(category, upgrade.id)
	var max_level = workshop_manager.get_max_level(category, upgrade.id)
	var cost = workshop_manager.get_cost(category, upgrade.id, level, is_permanent)
	var effect = workshop_manager.get_effect_value(category, upgrade.id)

	data.level_label.text = "%d / %d" % [level, max_level]

	# Format effect
	if upgrade.type == "mult":
		data.effect_label.text = "×%.3f" % (1.0 + effect)
	elif upgrade.type == "flat":
		data.effect_label.text = "+%.2f" % effect
	else:
		data.effect_label.text = "+%.2f%%" % (effect * 100)

	if level >= max_level:
		data.cost_label.text = "—"
		data.buy_btn.visible = false
		data.max_label.visible = true
	else:
		var currency_name = "Coins" if is_permanent else "Cash"
		data.cost_label.text = "%s %s" % [ui_manager.format_number(cost), currency_name]
		data.buy_btn.visible = true
		data.max_label.visible = false

		var can_afford = workshop_manager.can_afford(category, upgrade.id, is_permanent)
		data.buy_btn.disabled = not can_afford
		data.buy_btn.text = "Buy" if can_afford else "Can't Afford"


func _update_all_widgets() -> void:
	for container in [attack_container, defense_container, utility_container, enhancements_container]:
		for child in container.get_children():
			if child.has_meta("widget_data"):
				_update_widget(child)


func _update_currency_display() -> void:
	coin_amount.text = ui_manager.format_number(currency_manager.get_currency("coins"))
	cash_amount.text = ui_manager.format_number(currency_manager.get_currency("cash"))


func _on_tab_changed(tab_idx: int) -> void:
	var tabs = ["attack", "defense", "utility", "enhancements"]
	current_category = tabs[tab_idx]


func _on_mode_changed(pressed: bool) -> void:
	if pressed:
		is_permanent = permanent_btn.pressed
		_update_all_widgets()
		_update_currency_display()


func _on_buy_pressed(category: String, upgrade_id: String) -> void:
	if workshop_manager.purchase(category, upgrade_id, is_permanent):
		AudioManager.play_upgrade()
		_update_all_widgets()
		_update_currency_display()


func _on_workshop_changed() -> void:
	_update_all_widgets()


func _on_currency_changed(currency: String, old: int, new: int) -> void:
	if currency in ["coins", "cash"]:
		_update_currency_display()
		_update_all_widgets()


func _close() -> void:
	visible = false
	UIManager.menu_closed.emit("Workshop")


func popup() -> void:
	visible = true
	_update_currency_display()
	_update_all_widgets()
	UIManager.menu_opened.emit("Workshop")