extends CanvasLayer
class_name TournamentMenu

@onready var save_manager: SaveManager = SaveManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var ui_manager: UIManager = UIManager

@onready var league_label: Label = %LeagueLabel
@onready var rank_label: Label = %RankLabel
@onready var ticket_amount: Label = %TicketAmount
@onready var enter_btn: Button = %EnterBtn
@onready var rewards_container: VBoxContainer = %RewardsContainer
@onready var gem_amount: Label = %GemAmount
@onready var stone_amount: Label = %StoneAmount
@onready var close_btn: Button = %CloseBtn

func _ready() -> void:
	_connect_signals()
	_build_tournament()
	_update_currency_display()
	visible = false


func _connect_signals() -> void:
	close_btn.pressed.connect(_close)
	enter_btn.pressed.connect(_enter_tournament)
	currency_manager.currency_changed.connect(_on_currency_changed)


func _build_tournament() -> void:
	for child in rewards_container.get_children():
		child.queue_free()

	var tourney = save_manager.save_data.get("tournaments", {})
	var league = tourney.get("league", 0)
	var rank = tourney.get("rank", 0)
	var tickets = tourney.get("tickets", 0)

	var league_names = ["Copper", "Silver", "Gold", "Platinum", "Champion", "Legend", "Mythic"]
	league_label.text = "League: %s" % league_names[league]
	rank_label.text = "Rank: %d" % rank
	ticket_amount.text = str(tickets)

	# Rewards per league
	var gem_rewards = [50, 100, 200, 400, 800, 1500, 3000]
	var stone_rewards = [0, 5, 15, 30, 60, 125, 250]
	var key_rewards = [0, 0, 0, 0, 0, 25, 50]

	for i in 7:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("h_separation", 10)
		hbox.custom_minimum_size_y = 30
		rewards_container.add_child(hbox)

		var label = Label.new()
		label.text = league_names[i]
		label.custom_minimum_size_x = 120
		label.theme_override_font_sizes["font_size"] = 12
		hbox.add_child(label)

		var gem_label = Label.new()
		gem_label.text = "%d💎" % gem_rewards[i]
		gem_label.custom_minimum_size_x = 80
		gem_label.horizontal_alignment = 1
		gem_label.theme_override_font_sizes["font_size"] = 12
		hbox.add_child(gem_label)

		var stone_label = Label.new()
		stone_label.text = "%d🔮" % stone_rewards[i]
		stone_label.custom_minimum_size_x = 80
		stone_label.horizontal_alignment = 1
		stone_label.theme_override_font_sizes["font_size"] = 12
		hbox.add_child(stone_label)

		if key_rewards[i] > 0:
			var key_label = Label.new()
			key_label.text = "%d🔑" % key_rewards[i]
			key_label.custom_minimum_size_x = 80
			key_label.horizontal_alignment = 1
			key_label.theme_override_font_sizes["font_size"] = 12
			hbox.add_child(key_label)

		if i == league:
			hbox.modulate = Color(1, 1, 0.5)


func _enter_tournament() -> void:
	var tickets = save_manager.save_data.get("tournaments", {}).get("tickets", 0)
	if tickets <= 0:
		# Buy ticket with gems
		if currency_manager.spend("gems", 100, "tournament_ticket"):
			save_manager.save_data["tournaments"]["tickets"] = tickets + 1
			AudioManager.play_upgrade()
			_build_tournament()
	else:
		save_manager.save_data["tournaments"]["tickets"] = tickets - 1
		# Start tournament run
		UIManager.show_info("Tournament started! Good luck!")
		AudioManager.play_wave_start()


func _update_currency_display() -> void:
	gem_amount.text = ui_manager.format_number(currency_manager.get_currency("gems"))
	stone_amount.text = ui_manager.format_number(currency_manager.get_currency("power_stones"))


func _on_currency_changed(currency: String, old: int, new: int) -> void:
	if currency in ["gems", "power_stones"]:
		_update_currency_display()


func _close() -> void:
	visible = false
	UIManager.menu_closed.emit("Tournament")


func popup() -> void:
	visible = true
	_update_currency_display()
	_build_tournament()
	UIManager.menu_opened.emit("Tournament")