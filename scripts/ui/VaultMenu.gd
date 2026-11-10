extends CanvasLayer
class_name VaultMenu

@onready var save_manager: SaveManager = SaveManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var ui_manager: UIManager = UIManager

@onready var power_container: VBoxContainer = %PowerContainer
@onready var enemy_container: VBoxContainer = %EnemyContainer
@onready var key_amount: Label = %KeyAmount
@onready var close_btn: Button = %CloseBtn

func _ready() -> void:
	_connect_signals()
	_build_vault()
	_update_currency_display()
	visible = false


func _connect_signals() -> void:
	close_btn.pressed.connect(_close)
	currency_manager.currency_changed.connect(_on_currency_changed)


func _build_vault() -> void:
	_clear(power_container)
	_clear(enemy_container)

	# Power upgrades (47 total)
	for i in 47:
		var widget = _create_vault_upgrade("Power %d" % (i + 1), "Increases power stat", i + 1)
		power_container.add_child(widget)

	# Enemy upgrades (30 total)
	for i in 30:
		var widget = _create_vault_upgrade("Enemy %d" % (i + 1), "Reduces enemy stat", i + 1)
		enemy_container.add_child(widget)


func _clear(container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()


func _create_vault_upgrade(name: String, desc: String, idx: int) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("h_separation", 10)
	container.custom_minimum_size_y = 40

	var label = Label.new()
	label.text = "%s - %s" % [name, desc]
	label.custom_minimum_size_x = 300
	label.theme_override_font_sizes["font_size"] = 12
	container.add_child(label)

	var level_label = Label.new()
	level_label.text = "Level: 0/30"
	level_label.custom_minimum_size_x = 100
	level_label.horizontal_alignment = 1
	level_label.theme_override_font_sizes["font_size"] = 12
	container.add_child(level_label)

	var cost_label = Label.new()
	cost_label.text = "Cost: %d🔑" % (idx * 10)
	cost_label.custom_minimum_size_x = 100
	cost_label.horizontal_alignment = 1
	cost_label.theme_override_font_sizes["font_size"] = 12
	container.add_child(cost_label)

	var btn = Button.new()
	btn.text = "Upgrade"
	btn.custom_minimum_size = Vector2(80, 30)
	container.add_child(btn)
	btn.pressed.connect(_upgrade.bind(name))

	return container


func _upgrade(name: String) -> void:
	if currency_manager.spend("keys", 10, "vault_upgrade"):
		AudioManager.play_upgrade()
		_update_currency_display()


func _update_currency_display() -> void:
	key_amount.text = ui_manager.format_number(currency_manager.get_currency("keys"))


func _on_currency_changed(currency: String, old: int, new: int) -> void:
	if currency == "keys":
		_update_currency_display()


func _close() -> void:
	visible = false
	UIManager.menu_closed.emit("Vault")


func popup() -> void:
	visible = true
	_update_currency_display()
	UIManager.menu_opened.emit("Vault")