extends CanvasLayer
class_name ModulesMenu

@onready var save_manager: SaveManager = SaveManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var ui_manager: UIManager = UIManager

@onready var cannon_module: PanelContainer = %CannonModule
@onready var armor_module: PanelContainer = %ArmorModule
@onready var generator_module: PanelContainer = %GeneratorModule
@onready var core_module: PanelContainer = %CoreModule
@onready var shard_amount: Label = %ShardAmount
@onready var stone_amount: Label = %StoneAmount
@onready var close_btn: Button = %CloseBtn

func _ready() -> void:
	_connect_signals()
	_build_modules()
	_update_currency_display()
	visible = false


func _connect_signals() -> void:
	close_btn.pressed.connect(_close)
	currency_manager.currency_changed.connect(_on_currency_changed)


func _build_modules() -> void:
	_clear_module(cannon_module)
	_clear_module(armor_module)
	_clear_module(generator_module)
	_clear_module(core_module)

	_build_module_slot(cannon_module, "cannon")
	_build_module_slot(armor_module, "armor")
	_build_module_slot(generator_module, "generator")
	_build_module_slot(core_module, "core")


func _clear_module(container: PanelContainer) -> void:
	for child in container.get_children():
		child.queue_free()


func _build_module_slot(container: PanelContainer, slot_type: String) -> void:
	var module_data = save_manager.save_data.get("modules", {}).get(slot_type, {})

	var vbox = VBoxContainer.new()
	vbox.theme_override_constants["v_separation"] = 8
	container.add_child(vbox)

	# Module level/rarity
	if module_data:
		var level_label = Label.new()
		level_label.text = "Level %d" % module_data.get("level", 1)
		level_label.horizontal_alignment = 1
		level_label.theme_override_font_sizes["font_size"] = 14
		vbox.add_child(level_label)

		var rarity = module_data.get("rarity", "Common")
		var rarity_label = Label.new()
		rarity_label.text = rarity
		rarity_label.horizontal_alignment = 1
		rarity_label.add_theme_color_override("font_color", ui_manager.get_rarity_color(rarity))
		rarity_label.theme_override_font_sizes["font_size"] = 12
		vbox.add_child(rarity_label)

		# Main effect
		var main_effect = module_data.get("main_effect", "Damage +10%")
		var effect_label = Label.new()
		effect_label.text = main_effect
		effect_label.horizontal_alignment = 1
		effect_label.theme_override_font_sizes["font_size"] = 12
		effect_label.autowrap_mode = 1
		vbox.add_child(effect_label)

		# Sub-effects
		var sub_effects = module_data.get("sub_effects", [])
		for se in sub_effects:
			var se_label = Label.new()
			se_label.text = "• %s" % se
			se_label.horizontal_alignment = 1
			se_label.theme_override_font_sizes["font_size"] = 10
			vbox.add_child(se_label)
	else:
		var label = Label.new()
		label.text = "Empty\nTap to pull"
		label.horizontal_alignment = 1
		label.vertical_alignment = 1
		label.theme_override_font_sizes["font_size"] = 14
		vbox.add_child(label)

	# Action buttons
	var hbox = HBoxContainer.new()
	hbox.theme_override_constants["h_separation"] = 5
	vbox.add_child(hbox)

	var pull_btn = Button.new()
	pull_btn.text = "Pull (100💰)"
	pull_btn.custom_minimum_size = Vector2(100, 35)
	hbox.add_child(pull_btn)
	pull_btn.pressed.connect(_pull_module.bind(slot_type))

	var merge_btn = Button.new()
	merge_btn.text = "Merge"
	merge_btn.custom_minimum_size = Vector2(80, 35)
	merge_btn.disabled = true
	hbox.add_child(merge_btn)

	var reroll_btn = Button.new()
	reroll_btn.text = "Reroll"
	reroll_btn.custom_minimum_size = Vector2(80, 35)
	reroll_btn.disabled = true
	hbox.add_child(reroll_btn)


func _pull_module(slot_type: String) -> void:
	if not currency_manager.spend("coins", 100, "module_pull"):
		return

	# Simplified pull - random rarity
	var rarities = ["Common", "Common", "Common", "Common", "Common", "Common", "Common", "Rare", "Rare", "Epic"]
	var rarity = rarities[randi() % rarities.size()]

	var effects = {
		"cannon": ["Damage", "Attack Speed", "Crit Factor", "Range"],
		"armor": ["Health", "Defense", "Regen", "Thorns"],
		"generator": ["Cash", "Coins", "Interest", "Recovery"],
		"core": ["UW Duration", "UW Cooldown", "UW Damage", "UW Bonus"],
	}

	var main = effects[slot_type][randi() % effects[slot_type].size()] + " +%d%%" % randi_range(5, 25)
	var subs = []
	for i in randi_range(1, 4):
		subs.append("%s +%d%%" % [effects[slot_type][randi() % effects[slot_type].size()], randi_range(1, 10)])

	save_manager.save_data["modules"][slot_type] = {
		"level": 1,
		"rarity": rarity,
		"main_effect": main,
		"sub_effects": subs,
	}

	AudioManager.play_level_up()
	_build_modules()
	_update_currency_display()


func _update_currency_display() -> void:
	shard_amount.text = ui_manager.format_number(currency_manager.get_currency("module_shards"))
	stone_amount.text = ui_manager.format_number(currency_manager.get_currency("power_stones"))


func _on_currency_changed(currency: String, old: int, new: int) -> void:
	if currency in ["module_shards", "power_stones"]:
		_update_currency_display()


func _close() -> void:
	visible = false
	UIManager.menu_closed.emit("Modules")


func popup() -> void:
	visible = true
	_update_currency_display()
	_build_modules()
	UIManager.menu_opened.emit("Modules")