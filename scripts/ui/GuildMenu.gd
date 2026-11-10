extends CanvasLayer
class_name GuildMenu

@onready var save_manager: SaveManager = SaveManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var ui_manager: UIManager = UIManager

@onready var guild_name: Label = %GuildName
@onready var join_btn: Button = %JoinBtn
@onready var claim_btn: Button = %ClaimBtn
@onready var store_container: VBoxContainer = %StoreContainer
@onready var token_amount: Label = %TokenAmount
@onready var bit_amount: Label = %BitAmount
@onready var close_btn: Button = %CloseBtn

func _ready() -> void:
	_connect_signals()
	_build_guild()
	_update_currency_display()
	visible = false


func _connect_signals() -> void:
	close_btn.pressed.connect(_close)
	join_btn.pressed.connect(_join_guild)
	claim_btn.pressed.connect(_claim_chest)
	currency_manager.currency_changed.connect(_on_currency_changed)


func _build_guild() -> void:
	for child in store_container.get_children():
		child.queue_free()

	var guild = save_manager.save_data.get("guild", {})
	var joined = guild.get("joined", false)
	var tokens = guild.get("tokens", 0)
	var bits = guild.get("bits", 0)

	if joined:
		guild_name.text = "The Tower Clan"
		join_btn.text = "Leave Guild"
	else:
		guild_name.text = "No Guild Joined"
		join_btn.text = "Join Guild"

	# Guild store items
	var items = [
		{"name": "Chip", "cost": 200, "currency": "tokens"},
		{"name": "Relic (Common)", "cost": 75, "currency": "tokens"},
		{"name": "Relic (Rare)", "cost": 150, "currency": "tokens"},
		{"name": "Theme", "cost": 100, "currency": "tokens"},
		{"name": "Bits (25)", "cost": 25, "currency": "tokens"},
		{"name": "Gems (100)", "cost": 100, "currency": "tokens"},
		{"name": "Shards (250)", "cost": 250, "currency": "tokens"},
	]

	for item in items:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("h_separation", 10)
		hbox.custom_minimum_size_y = 35
		store_container.add_child(hbox)

		var label = Label.new()
		label.text = item.name
		label.custom_minimum_size_x = 200
		label.theme_override_font_sizes["font_size"] = 12
		hbox.add_child(label)

		var cost_label = Label.new()
		cost_label.text = "%d %s" % [item.cost, item.currency == "tokens" ? "🎫" : "⚙️"]
		cost_label.custom_minimum_size_x = 100
		cost_label.horizontal_alignment = 1
		cost_label.theme_override_font_sizes["font_size"] = 12
		hbox.add_child(cost_label)

		var btn = Button.new()
		btn.text = "Buy"
		btn.custom_minimum_size = Vector2(80, 30)
		hbox.add_child(btn)
		btn.pressed.connect(_buy_item.bind(item))


func _join_guild() -> void:
	var guild = save_manager.save_data.get("guild", {})
	if guild.get("joined", false):
		guild["joined"] = false
		UIManager.show_info("Left guild")
	else:
		guild["joined"] = true
		UIManager.show_info("Joined The Tower Clan!")

	_build_guild()


func _claim_chest() -> void:
	currency_manager.add("tokens", 150, "guild_chest")
	currency_manager.add("bits", 185, "guild_chest")
	AudioManager.play_level_up()
	UIManager.show_success("Weekly chest claimed!")
	_update_currency_display()


func _buy_item(item: Dictionary) -> void:
	var currency = item.currency
	var cost = item.cost

	if currency_manager.spend(currency, cost, "guild_store"):
		if item.name == "Chip":
			UIManager.show_info("Chip purchased! Check Guardian menu.")
		elif "Relic" in item.name:
			UIManager.show_info("Relic purchased! Check Relics menu.")
		elif item.name == "Theme":
			UIManager.show_info("Theme purchased!")
		elif "Bits" in item.name:
			currency_manager.add("bits", 25, "guild_store")
		elif "Gems" in item.name:
			currency_manager.add("gems", 100, "guild_store")
		elif "Shards" in item.name:
			currency_manager.add("module_shards", 250, "guild_store")

		AudioManager.play_upgrade()
		_update_currency_display()


func _update_currency_display() -> void:
	token_amount.text = ui_manager.format_number(currency_manager.get_currency("tokens"))
	bit_amount.text = ui_manager.format_number(currency_manager.get_currency("bits"))


func _on_currency_changed(currency: String, old: int, new: int) -> void:
	if currency in ["tokens", "bits"]:
		_update_currency_display()


func _close() -> void:
	visible = false
	UIManager.menu_closed.emit("Guild")


func popup() -> void:
	visible = true
	_update_currency_display()
	_build_guild()
	UIManager.menu_opened.emit("Guild")