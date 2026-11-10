extends CanvasLayer
class_name GuardianMenu

@onready var save_manager: SaveManager = SaveManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var ui_manager: UIManager = UIManager

@onready var chip_slots: HBoxContainer = %ChipSlots
@onready var chip_container: VBoxContainer = %ChipContainer
@onready var bit_amount: Label = %BitAmount
@onready var close_btn: Button = %CloseBtn

func _ready() -> void:
	_connect_signals()
	_build_chips()
	_update_currency_display()
	visible = false


func _connect_signals() -> void:
	close_btn.pressed.connect(_close)
	currency_manager.currency_changed.connect(_on_currency_changed)


func _build_chips() -> void:
	for child in chip_slots.get_children():
		child.queue_free()

	var slots_unlocked = save_manager.get("guardian/slots_unlocked", 1)
	var chips = save_manager.save_data.get("guardian", {}).get("chips", {})

	for i in 6:
		var chip_data = chips.get(str(i), {})
		var widget = _create_chip_widget(i, chip_data, i < slots_unlocked)
		chip_slots.add_child(widget)

	# Unlock buttons
	for i in range(slots_unlocked, 3):
		var unlock_btn = Button.new()
		unlock_btn.text = "Unlock Slot %d (%d⚙️)" % [i + 1, 100 * (i + 1)]
		unlock_btn.custom_minimum_size = Vector2(150, 100)
		chip_slots.add_child(unlock_btn)
		unlock_btn.pressed.connect(_unlock_slot.bind(i))


func _create_chip_widget(chip_idx: int, data: Dictionary, unlocked: bool) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(120, 180)

	var frame = PanelContainer.new()
	frame.add_theme_constant_override("margin_top", 8)
	frame.add_theme_constant_override("margin_bottom", 8)
	frame.add_theme_constant_override("margin_left", 8)
	frame.add_theme_constant_override("margin_right", 8)
	frame.v_size_flags = 2
	container.add_child(frame)

	var vbox = VBoxContainer.new()
	vbox.theme_override_constants["v_separation"] = 6
	frame.add_child(vbox)

	var icons = ["⚡", "🛡️", "❤️", "💰", "🔮", "🎯"]
	var names = ["Lightning", "Shield", "Life", "Wealth", "Magic", "Precision"]

	var icon = Label.new()
	icon.text = icons[chip_idx]
	icon.horizontal_alignment = 1
	icon.theme_override_font_sizes["font_size"] = 32
	vbox.add_child(icon)

	var name_label = Label.new()
	name_label.text = names[chip_idx]
	name_label.horizontal_alignment = 1
	name_label.theme_override_font_sizes["font_size"] = 14
	vbox.add_child(name_label)

	if data:
		var level = data.get("level", 0)
		var level_label = Label.new()
		level_label.text = "Level %d" % level
		level_label.horizontal_alignment = 1
		level_label.theme_override_font_sizes["font_size"] = 12
		vbox.add_child(level_label)

		var upgrade_btn = Button.new()
		upgrade_btn.text = "Upgrade (%d⚙️)" % (100 * (level + 1))
		upgrade_btn.custom_minimum_size_y = 30
		vbox.add_child(upgrade_btn)
		upgrade_btn.pressed.connect(_upgrade_chip.bind(chip_idx))
	else:
		var label = Label.new()
		label.text = "Empty"
		label.horizontal_alignment = 1
		label.theme_override_font_sizes["font_size"] = 12
		vbox.add_child(label)

	return container


func _upgrade_chip(chip_idx: int) -> void:
	# Simplified
	var chips = save_manager.save_data["guardian"]["chips"]
	var level = chips.get(str(chip_idx), {}).get("level", 0)
	var cost = 100 * (level + 1)

	if currency_manager.spend("bits", cost, "guardian_chip"):
		if not chips.has(str(chip_idx)):
			chips[str(chip_idx)] = {}
		chips[str(chip_idx)]["level"] = level + 1
		AudioManager.play_upgrade()
		_build_chips()
		_update_currency_display()


func _unlock_slot(slot_idx: int) -> void:
	var cost = 100 * (slot_idx + 1)
	if currency_manager.spend("bits", cost, "guardian_slot"):
		save_manager.save_data["guardian"]["slots_unlocked"] = slot_idx + 1
		AudioManager.play_level_up()
		_build_chips()
		_update_currency_display()


func _update_currency_display() -> void:
	bit_amount.text = ui_manager.format_number(currency_manager.get_currency("bits"))


func _on_currency_changed(currency: String, old: int, new: int) -> void:
	if currency == "bits":
		_update_currency_display()
		_build_chips()


func _close() -> void:
	visible = false
	UIManager.menu_closed.emit("Guardian")


func popup() -> void:
	visible = true
	_update_currency_display()
	_build_chips()
	UIManager.menu_opened.emit("Guardian")