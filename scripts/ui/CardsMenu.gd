extends CanvasLayer
class_name CardsMenu

@onready var save_manager: SaveManager = SaveManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var ui_manager: UIManager = UIManager
@onready var game_data: GameData = GameData.new()

@onready var slot_grid: GridContainer = %SlotGrid
@onready var gem_amount: Label = %GemAmount
@onready var slot_count_label: Label = %SlotCount
@onready var close_btn: Button = %CloseBtn

var card_widgets: Dictionary = {}
var selected_card: String = ""

func _ready() -> void:
	_connect_signals()
	_build_card_grid()
	_update_currency_display()
	visible = false


func _connect_signals() -> void:
	close_btn.pressed.connect(_close)
	currency_manager.currency_changed.connect(_on_currency_changed)


func _build_card_grid() -> void:
	# Clear existing
	for child in slot_grid.get_children():
		child.queue_free()

	card_widgets.clear()

	# Get owned cards and slots
	var owned = save_manager.save_data.get("cards", {}).get("owned", {})
	var slots = save_manager.save_data.get("cards", {}).get("slots", [])
	var slot_count = save_manager.save_data.get("cards", {}).get("slot_count", 22)

	# Build slot widgets
	for i in range(slot_count):
		var slot_id = slots[i] if i < slots.size() else ""
		var widget = _create_slot_widget(i, slot_id, owned.get(slot_id, 0))
		slot_grid.add_child(widget)

	# Add empty slots for future unlocks
	for i in range(slot_count, 28):
		var widget = _create_locked_slot(i)
		slot_grid.add_child(widget)


func _create_slot_widget(slot_idx: int, card_id: String, stars: int) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(140, 180)

	# Card frame
	var frame = PanelContainer.new()
	frame.add_theme_constant_override("margin_top", 4)
	frame.add_theme_constant_override("margin_bottom", 4)
	frame.add_theme_constant_override("margin_left", 4)
	frame.add_theme_constant_override("margin_right", 4)
	frame.v_size_flags = 2
	container.add_child(frame)

	var vbox = VBoxContainer.new()
	vbox.theme_override_constants["v_separation"] = 4
	frame.add_child(vbox)

	# Rarity border color
	var rarity = _get_card_rarity(card_id)
	var border_color = ui_manager.get_rarity_color(rarity)

	# Card name
	var name_label = Label.new()
	name_label.text = _get_card_name(card_id) if card_id else "Empty Slot"
	name_label.horizontal_alignment = 1
	name_label.theme_override_font_sizes["font_size"] = 12
	name_label.autowrap_mode = 1
	vbox.add_child(name_label)

	# Stars
	var stars_label = Label.new()
	stars_label.text = "★" * stars + "☆" * (7 - stars)
	stars_label.horizontal_alignment = 1
	stars_label.theme_override_font_sizes["font_size"] = 14
	stars_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	vbox.add_child(stars_label)

	# Effect preview
	if card_id:
		var card_def = _find_card_def(card_id)
		if card_def:
			var lv1 = card_def.lv1
			var lv7 = card_def.lv7
			var value = stars > 0 ? lerp(lv1, lv7, (stars - 1) / 6.0) : lv1
			var effect_label = Label.new()
			effect_label.text = _format_effect(card_def.effect, value)
			effect_label.horizontal_alignment = 1
			effect_label.theme_override_font_sizes["font_size"] = 10
			effect_label.autowrap_mode = 1
			vbox.add_child(effect_label)

	# Upgrade button
	var upgrade_btn = Button.new()
	upgrade_btn.text = stars == 0 ? "Add Card" : "Upgrade (%s)" % ui_manager.format_number(_get_upgrade_cost(stars))
	upgrade_btn.custom_minimum_size_y = 30
	upgrade_btn.disabled = (stars >= 7)
	vbox.add_child(upgrade_btn)

	# Remove button (if card equipped)
	if stars > 0:
		var remove_btn = Button.new()
		remove_btn.text = "Remove"
		remove_btn.custom_minimum_size_y = 25
		remove_btn.flat = true
		vbox.add_child(remove_btn)
		remove_btn.pressed.connect(_remove_card.bind(slot_idx, card_id))

	upgrade_btn.pressed.connect(_upgrade_card.bind(slot_idx, card_id, stars))

	widget_data = {
		"slot_idx": slot_idx,
		"card_id": card_id,
		"stars": stars,
		"name_label": name_label,
		"stars_label": stars_label,
		"upgrade_btn": upgrade_btn,
	}
	container.set_meta("widget_data", widget_data)

	# Click to select
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(140, 180)
	btn.flat = true
	btn.pressed.connect(_select_slot.bind(slot_idx))
	container.add_child(btn)
	btn.move_child(btn, 0)

	return container


func _create_locked_slot(slot_idx: int) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(140, 180)
	container.modulate = Color(1, 1, 1, 0.3)

	var frame = PanelContainer.new()
	frame.add_theme_constant_override("margin_top", 4)
	frame.add_theme_constant_override("margin_bottom", 4)
	frame.add_theme_constant_override("margin_left", 4)
	frame.add_theme_constant_override("margin_right", 4)
	frame.v_size_flags = 2
	container.add_child(frame)

	var label = Label.new()
	label.text = "Slot %d\n(Unlock at Vault)" % (slot_idx + 1)
	label.horizontal_alignment = 1
	label.vertical_alignment = 1
	label.theme_override_font_sizes["font_size"] = 14
	frame.add_child(label)

	return container


func _get_card_rarity(card_id: String) -> String:
	for c in game_data.common_cards:
		if c.id == card_id: return "Common"
	for c in game_data.rare_cards:
		if c.id == card_id: return "Rare"
	for c in game_data.epic_cards:
		if c.id == card_id: return "Epic"
	return "Common"


func _get_card_name(card_id: String) -> String:
	for cat in [game_data.common_cards, game_data.rare_cards, game_data.epic_cards]:
		for c in cat:
			if c.id == card_id:
				return c.name
	return card_id


func _find_card_def(card_id: String) -> Dictionary:
	for cat in [game_data.common_cards, game_data.rare_cards, game_data.epic_cards]:
		for c in cat:
			if c.id == card_id:
				return c
	return null


func _format_effect(effect: String, value: float) -> String:
	match effect:
		"tower_damage_mult", "attack_speed_mult", "tower_health_mult", "health_regen_mult", "range_mult", "cash_mult", "coin_mult":
			return "×%.2f" % value
		"slow_percent", "crit_chance", "defense_percent", "free_upgrade_chance", "crit_coin_chance", "wave_skip_chance", "recovery_spawn_chance", "uw_crit_chance", "nuke_percent", "aoe_damage_mult":
			return "+%.0f%%" % (value * 100)
		"enemy_spawn_mult":
			return "×%.2f enemies" % value
		"defense_absolute", "extra_orb_speed", "plasma_boss_damage", "intro_sprint_waves", "mine_stun_duration", "cells_bonus":
			return "+%.1f" % value
		"death_ray_duration", "energy_net_duration", "super_tower_damage_mult", "second_wind_shield", "demon_mode_duration", "energy_shield_recharge", "wave_cd_reduction", "berserker_damage_per_absorbed", "super_crit_mult":
			return "%s: %.1f" % [effect, value]
	return "%s: %.2f" % [effect, value]


func _get_upgrade_cost(stars: int) -> int:
	if stars >= 7:
		return 0
	var next_star = stars + 1
	var costs = {1: 20, 2: 60, 3: 160, 4: 320, 5: 560, 6: 960, 7: 1600}
	return costs.get(next_star, 0)


func _select_slot(slot_idx: int) -> void:
	selected_card = ""
	for child in slot_grid.get_children():
		if child.has_meta("widget_data"):
			var data = child.get_meta("widget_data")
			if data.slot_idx == slot_idx:
				selected_card = data.card_id
				break


func _upgrade_card(slot_idx: int, card_id: String, stars: int) -> void:
	if stars >= 7:
		return

	var next_star = stars + 1
	var cost = _get_upgrade_cost(stars)

	if not currency_manager.spend("gems", cost, "card_upgrade_%s" % (card_id or "new")):
		return

	var new_card_id = card_id
	if not card_id:
		# Show card selection dialog
		_show_card_selection(slot_idx)
		return

	save_manager.set_card_stars(card_id, next_star)

	# If this card is in a slot, update it
	var slots = save_manager.save_data.get("cards", {}).get("slots", [])
	if slot_idx < slots.size():
		slots[slot_idx] = card_id

	AudioManager.play_level_up()
	_build_card_grid()
	_update_currency_display()


func _remove_card(slot_idx: int, card_id: String) -> void:
	var slots = save_manager.save_data.get("cards", {}).get("slots", [])
	if slot_idx < slots.size():
		slots[slot_idx] = ""
		_build_card_grid()


func _show_card_selection(slot_idx: int) -> void:
	# Would show a dialog to pick which card to add
	# For MVP, just add the first common card
	var first_card = game_data.common_cards[0].id
	save_manager.set_card_stars(first_card, 1)

	var slots = save_manager.save_data.get("cards", {}).get("slots", [])
	if slot_idx < slots.size():
		slots[slot_idx] = first_card

	_build_card_grid()
	_update_currency_display()


func _update_currency_display() -> void:
	gem_amount.text = ui_manager.format_number(currency_manager.get_currency("gems"))

	var slot_count = save_manager.save_data.get("cards", {}).get("slot_count", 22)
	slot_count_label.text = "Slots: %d/28" % slot_count


func _on_currency_changed(currency: String, old: int, new: int) -> void:
	if currency == "gems":
		_update_currency_display()
		_build_card_grid()


func _close() -> void:
	visible = false
	UIManager.menu_closed.emit("Cards")


func popup() -> void:
	visible = true
	_update_currency_display()
	_build_card_grid()
	UIManager.menu_opened.emit("Cards")