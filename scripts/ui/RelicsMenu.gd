extends CanvasLayer
class_name RelicsMenu

@onready var save_manager: SaveManager = SaveManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var ui_manager: UIManager = UIManager

@onready var relics_grid: GridContainer = %RelicsGrid
@onready var category_tabs: TabBar = %CategoryTabs
@onready var medal_amount: Label = %MedalAmount
@onready var close_btn: Button = %CloseBtn

func _ready() -> void:
	_connect_signals()
	_build_relics()
	_update_currency_display()
	visible = false


func _connect_signals() -> void:
	close_btn.pressed.connect(_close)
	category_tabs.tab_changed.connect(_on_category_changed)
	currency_manager.currency_changed.connect(_on_currency_changed)


func _build_relics() -> void:
	for child in relics_grid.get_children():
		child.queue_free()

	var owned = save_manager.save_data.get("relics", {}).get("owned", [])

	# Simplified - show tier milestone relics
	for tier in range(1, 25):
		var relic_id = "tier_%d_milestone" % tier
		var is_owned = relic_id in owned

		var widget = _create_relic_widget(relic_id, "T:%d" % tier, is_owned, "Legendary")
		relics_grid.add_child(widget)

	# Add some event relics
	var event_relics = [
		{"id": "no_spoon", "name": "No Spoon", "rarity": "Rare", "bonus": "+2% Defense"},
		{"id": "red_pill", "name": "Red Pill", "rarity": "Epic", "bonus": "+5% Health"},
		{"id": "dreamcatcher", "name": "Dreamcatcher", "rarity": "Rare", "bonus": "+2% Coins"},
		{"id": "spirit_wolf", "name": "Spirit Wolf", "rarity": "Epic", "bonus": "+5% Crit"},
	]

	for relic in event_relics:
		var is_owned = relic.id in owned
		var widget = _create_relic_widget(relic.id, relic.name, is_owned, relic.rarity, relic.bonus)
		relics_grid.add_child(widget)


func _create_relic_widget(relic_id: String, name: String, owned: bool, rarity: String, bonus: String = "") -> VBoxContainer:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(120, 100)

	var frame = PanelContainer.new()
	frame.add_theme_constant_override("margin_top", 4)
	frame.add_theme_constant_override("margin_bottom", 4)
	frame.add_theme_constant_override("margin_left", 4)
	frame.add_theme_constant_override("margin_right", 4)
	if not owned:
		frame.modulate = Color(0.5, 0.5, 0.5, 0.5)
	frame.v_size_flags = 2
	container.add_child(frame)

	var vbox = VBoxContainer.new()
	vbox.theme_override_constants["v_separation"] = 2
	frame.add_child(vbox)

	# Rarity border
	var border_color = ui_manager.get_rarity_color(rarity)

	var name_label = Label.new()
	name_label.text = name
	name_label.horizontal_alignment = 1
	name_label.theme_override_font_sizes["font_size"] = 10
	name_label.autowrap_mode = 1
	vbox.add_child(name_label)

	var rarity_label = Label.new()
	rarity_label.text = rarity
	rarity_label.horizontal_alignment = 1
	rarity_label.add_theme_color_override("font_color", border_color)
	rarity_label.theme_override_font_sizes["font_size"] = 8
	vbox.add_child(rarity_label)

	if bonus != "":
		var bonus_label = Label.new()
		bonus_label.text = bonus
		bonus_label.horizontal_alignment = 1
		bonus_label.theme_override_font_sizes["font_size"] = 8
		bonus_label.autowrap_mode = 1
		vbox.add_child(bonus_label)

	if owned:
		var owned_label = Label.new()
		owned_label.text = "✓ OWNED"
		owned_label.horizontal_alignment = 1
		owned_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
		owned_label.theme_override_font_sizes["font_size"] = 8
		vbox.add_child(owned_label)
	else:
		var locked_label = Label.new()
		locked_label.text = "🔒 LOCKED"
		locked_label.horizontal_alignment = 1
		locked_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		locked_label.theme_override_font_sizes["font_size"] = 8
		vbox.add_child(locked_label)

	return container


func _on_category_changed(tab_idx: int) -> void:
	_build_relics()


func _update_currency_display() -> void:
	medal_amount.text = ui_manager.format_number(currency_manager.get_currency("medals"))


func _on_currency_changed(currency: String, old: int, new: int) -> void:
	if currency == "medals":
		_update_currency_display()


func _close() -> void:
	visible = false
	UIManager.menu_closed.emit("Relics")


func popup() -> void:
	visible = true
	_update_currency_display()
	_build_relics()
	UIManager.menu_opened.emit("Relics")