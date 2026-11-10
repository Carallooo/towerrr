extends CanvasLayer
class_name EventsMenu

@onready var save_manager: SaveManager = SaveManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var ui_manager: UIManager = UIManager

@onready var event_name: Label = %EventName
@onready var event_progress: ProgressBar = %EventProgress
@onready var missions_container: VBoxContainer = %MissionsContainer
@onready var shop_container: VBoxContainer = %ShopContainer
@onready var medal_amount: Label = %MedalAmount
@onready var close_btn: Button = %CloseBtn

func _ready() -> void:
	_connect_signals()
	_build_events()
	_update_currency_display()
	visible = false


func _connect_signals() -> void:
	close_btn.pressed.connect(_close)
	currency_manager.currency_changed.connect(_on_currency_changed)


func _build_events() -> void:
	for child in missions_container.get_children():
		child.queue_free()
	for child in shop_container.get_children():
		child.queue_free()

	# Current event (simplified)
	var events = ["Into the Matrix", "Full Moon", "Viral Outbreak", "Plasma Returns", "Honey", "Aurora", "Aliens"]
	var current = events[randi() % events.size()]
	event_name.text = "Active: %s" % current
	event_progress.value = 0.3

	# Missions (21 total)
	for i in 21:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("h_separation", 10)
		hbox.custom_minimum_size_y = 35
		missions_container.add_child(hbox)

		var label = Label.new()
		label.text = "Mission %d: %s" % [i + 1, _get_mission_name(i)]
		label.custom_minimum_size_x = 300
		label.theme_override_font_sizes["font_size"] = 12
		hbox.add_child(label)

		var reward = Label.new()
		reward.text = "%d🏅" % (10 + randi() % 11)
		reward.custom_minimum_size_x = 80
		reward.horizontal_alignment = 1
		reward.theme_override_font_sizes["font_size"] = 12
		hbox.add_child(reward)

		var btn = Button.new()
		btn.text = "Claim"
		btn.custom_minimum_size = Vector2(80, 30)
		btn.disabled = (randf() > 0.5)
		hbox.add_child(btn)
		btn.pressed.connect(_claim_mission.bind(i))

	# Event shop
	var shop_items = [
		{"name": "Event Relic (350🏅)", "cost": 350},
		{"name": "Event Relic (700🏅)", "cost": 700},
		{"name": "Event Relic (1100🏅)", "cost": 1100},
		{"name": "Gems (150🏅)", "cost": 150},
		{"name": "Stones (15🏅)", "cost": 15},
		{"name": "Shards (250🏅)", "cost": 250},
	]

	for item in shop_items:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("h_separation", 10)
		hbox.custom_minimum_size_y = 35
		shop_container.add_child(hbox)

		var label = Label.new()
		label.text = item.name
		label.custom_minimum_size_x = 300
		label.theme_override_font_sizes["font_size"] = 12
		hbox.add_child(label)

		var btn = Button.new()
		btn.text = "Buy"
		btn.custom_minimum_size = Vector2(80, 30)
		hbox.add_child(btn)
		btn.pressed.connect(_buy_shop_item.bind(item))


func _get_mission_name(idx: int) -> String:
	var names = [
		"Defeat 1000 enemies", "Reach wave 500", "Kill 10 elites", "Kill 5 bosses",
		"Earn 100K coins", "Earn 50K cash", "Use 5 UWs", "Activate 3 bots",
		"Upgrade workshop 10 times", "Research 5 labs", "Upgrade 3 cards", "Merge 2 modules",
		"Kill 50 fleet", "Complete 3 daily", "Prestige once", "Join tournament",
		"Claim daily reward", "Watch ad for gems", "Share game", "Rate game", "Follow dev"
	]
	return names[idx % names.size()]


func _claim_mission(idx: int) -> void:
	currency_manager.add("medals", 10 + randi() % 11, "mission")
	AudioManager.play_level_up()
	UIManager.show_success("Mission completed!")
	_update_currency_display()


func _buy_shop_item(item: Dictionary) -> void:
	if currency_manager.spend("medals", item.cost, "event_shop"):
		if "Relic" in item.name:
			UIManager.show_info("Event relic purchased! Check Relics menu.")
		elif "Gems" in item.name:
			currency_manager.add("gems", 100, "event_shop")
		elif "Stones" in item.name:
			currency_manager.add("power_stones", 10, "event_shop")
		elif "Shards" in item.name:
			currency_manager.add("module_shards", 50, "event_shop")

		AudioManager.play_upgrade()
		_update_currency_display()


func _update_currency_display() -> void:
	medal_amount.text = ui_manager.format_number(currency_manager.get_currency("medals"))


func _on_currency_changed(currency: String, old: int, new: int) -> void:
	if currency == "medals":
		_update_currency_display()


func _close() -> void:
	visible = false
	UIManager.menu_closed.emit("Events")


func popup() -> void:
	visible = true
	_update_currency_display()
	_build_events()
	UIManager.menu_opened.emit("Events")