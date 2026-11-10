extends CanvasLayer
class_name LabsMenu

@onready var save_manager: SaveManager = SaveManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var ui_manager: UIManager = UIManager

# UI References
@onready var category_tabs: TabBar = %CategoryTabs
@onready var slot_buttons: HBoxContainer = %SlotButtons
@onready var main_container: VBoxContainer = %MainContainer
@onready var attack_container: VBoxContainer = %AttackContainer
@onready var defense_container: VBoxContainer = %DefenseContainer
@onready var utility_container: VBoxContainer = %UtilityContainer
@onready var uw_container: VBoxContainer = %UWContainer
@onready var cards_container: VBoxContainer = %CardsContainer
@onready var perks_container: VBoxContainer = %PerksContainer
@onready var bots_container: VBoxContainer = %BotsContainer
@onready var modules_container: VBoxContainer = %ModulesContainer
@onready var enemies_container: VBoxContainer = %EnemiesContainer
@onready var battle_container: VBoxContainer = %BattleContainer
@onready var cell_amount: Label = %CellAmount
@onready var gem_amount: Label = %GemAmount
@onready var speed_label: Label = %SpeedLabel
@onready var close_btn: Button = %CloseBtn

var current_category: int = 0
var current_slot: int = 0
var active_lab: String = ""
var lab_progress: float = 0.0
var lab_widgets: Dictionary = {}

# Lab categories and their research items
const LAB_CATEGORIES = {
	"Main": [
		{"id": "game_speed", "name": "Game Speed", "max": 7, "base_cost": 1000, "exp": 2.5, "desc": "Raises maximum game speed", "effect_per_level": 0.5},
		{"id": "starting_cash", "name": "Starting Cash", "max": 99, "base_cost": 500, "exp": 1.3, "desc": "More cash at start of each round", "effect_per_level": 5},
		{"id": "workshop_attack_discount", "name": "Workshop Attack Discount", "max": 99, "base_cost": 1000, "exp": 1.25, "desc": "Reduces Attack workshop coin cost", "effect_per_level": 0.005},
		{"id": "workshop_defense_discount", "name": "Workshop Defense Discount", "max": 99, "base_cost": 1000, "exp": 1.25, "desc": "Reduces Defense workshop coin cost", "effect_per_level": 0.005},
		{"id": "workshop_utility_discount", "name": "Workshop Utility Discount", "max": 99, "base_cost": 1000, "exp": 1.25, "desc": "Reduces Utility workshop coin cost", "effect_per_level": 0.005},
		{"id": "labs_coin_discount", "name": "Labs Coin Discount", "max": 99, "base_cost": 2000, "exp": 1.3, "desc": "Reduces all lab coin costs", "effect_per_level": 0.003},
		{"id": "labs_speed", "name": "Labs Speed", "max": 99, "base_cost": 2000, "exp": 1.3, "desc": "Multiplies research speed for other labs", "effect_per_level": 0.02},
		{"id": "buy_multiplier", "name": "Buy Multiplier", "max": 4, "base_cost": 5000, "exp": 3.0, "desc": "Adds x5, x10, Max, x100 buttons", "effect_per_level": 1},
		{"id": "presets", "name": "Presets", "max": 5, "base_cost": 10000, "exp": 2.5, "desc": "Save/load build presets", "effect_per_level": 1},
	],
	"Attack": [
		{"id": "damage", "name": "Damage", "max": 100, "base_cost": 100, "exp": 1.15, "desc": "Increases tower damage", "effect_per_level": 0.02},
		{"id": "attack_speed", "name": "Attack Speed", "max": 99, "base_cost": 150, "exp": 1.16, "desc": "Increases attack speed", "effect_per_level": 0.02},
		{"id": "crit_factor", "name": "Critical Factor", "max": 99, "base_cost": 200, "exp": 1.18, "desc": "Increases critical damage", "effect_per_level": 0.03},
		{"id": "range", "name": "Range", "max": 80, "base_cost": 250, "exp": 1.18, "desc": "Increases tower range", "effect_per_level": 0.02},
		{"id": "damage_per_meter", "name": "Damage per Meter", "max": 99, "base_cost": 300, "exp": 1.2, "desc": "Damage increases with distance", "effect_per_level": 0.03},
		{"id": "super_crit_chance", "name": "Super Crit Chance", "max": 50, "base_cost": 500, "exp": 1.25, "desc": "Chance for super critical hit", "effect_per_level": 0.001},
		{"id": "super_crit_mult", "name": "Super Crit Multiplier", "max": 40, "base_cost": 800, "exp": 1.3, "desc": "Super crit damage multiplier", "effect_per_level": 0.02},
		{"id": "rend_armor", "name": "Max Rend Armor", "max": 30, "base_cost": 1000, "exp": 1.3, "desc": "Maximum armor rend cap", "effect_per_level": 0.05},
		{"id": "light_speed_shots", "name": "Light Speed Shots", "max": 1, "base_cost": 5000, "exp": 1.0, "desc": "Instant projectile travel", "effect_per_level": 1},
	],
	"Defense": [
		{"id": "health", "name": "Health", "max": 100, "base_cost": 100, "exp": 1.15, "desc": "Increases tower health", "effect_per_level": 0.03},
		{"id": "health_regen", "name": "Health Regen", "max": 100, "base_cost": 150, "exp": 1.16, "desc": "Increases health regeneration", "effect_per_level": 0.03},
		{"id": "defense_absolute", "name": "Defense Absolute", "max": 100, "base_cost": 200, "exp": 1.18, "desc": "Flat damage reduction", "effect_per_level": 10},
		{"id": "defense_percent", "name": "Defense Percent", "max": 50, "base_cost": 250, "exp": 1.18, "desc": "% damage reduction (caps at 98%)", "effect_per_level": 0.002},
		{"id": "orb_speed", "name": "Orb Speed", "max": 20, "base_cost": 300, "exp": 1.2, "desc": "Increases orb rotation speed", "effect_per_level": 0.1},
		{"id": "land_mine_damage", "name": "Land Mine Damage", "max": 20, "base_cost": 400, "exp": 1.2, "desc": "Increases land mine damage", "effect_per_level": 0.1},
		{"id": "land_mine_decay", "name": "Land Mine Decay", "max": 35, "base_cost": 500, "exp": 1.22, "desc": "Reduces mine damage decay", "effect_per_level": 0.5},
		{"id": "shockwave_size", "name": "Shockwave Size", "max": 20, "base_cost": 600, "exp": 1.22, "desc": "Increases shockwave radius", "effect_per_level": 0.05},
		{"id": "orb_boss_hit", "name": "Orb Boss Hit", "max": 10, "base_cost": 800, "exp": 1.25, "desc": "Orbs can damage bosses", "effect_per_level": 0.002},
		{"id": "wall_health", "name": "Wall Health", "max": 50, "base_cost": 1000, "exp": 1.2, "desc": "Increases wall health", "effect_per_level": 0.02},
		{"id": "wall_rebuild", "name": "Wall Rebuild", "max": 20, "base_cost": 1500, "exp": 1.25, "desc": "Reduces wall rebuild time", "effect_per_level": 10},
		{"id": "wall_regen", "name": "Wall Regen", "max": 30, "base_cost": 2000, "exp": 1.25, "desc": "Increases wall regeneration", "effect_per_level": 0.1},
		{"id": "thorns", "name": "Thorns", "max": 20, "base_cost": 2500, "exp": 1.3, "desc": "Reflects damage to attackers", "effect_per_level": 0.01},
		{"id": "invincibility", "name": "Invincibility", "max": 10, "base_cost": 3000, "exp": 1.3, "desc": "Brief invincibility on wall break", "effect_per_level": 1},
		{"id": "fortification", "name": "Fortification", "max": 60, "base_cost": 4000, "exp": 1.3, "desc": "Increases wall defense", "effect_per_level": 0.02},
		{"id": "garlic", "name": "Garlic Thorns", "max": 10, "base_cost": 5000, "exp": 1.4, "desc": "Enemies near tower take damage", "effect_per_level": 0.5},
	],
	"Utility": [
		{"id": "cash_bonus", "name": "Cash Bonus", "max": 99, "base_cost": 100, "exp": 1.15, "desc": "Increases cash from kills", "effect_per_level": 0.02},
		{"id": "cash_wave", "name": "Cash per Wave", "max": 99, "base_cost": 100, "exp": 1.15, "desc": "Increases base cash per wave", "effect_per_level": 5},
		{"id": "coins", "name": "Coins per Kill", "max": 99, "base_cost": 150, "exp": 1.16, "desc": "Increases coins per kill", "effect_per_level": 0.02},
		{"id": "coins_wave", "name": "Coins per Wave", "max": 99, "base_cost": 200, "exp": 1.17, "desc": "Increases base coins per wave", "effect_per_level": 5},
		{"id": "interest", "name": "Interest Rate", "max": 99, "base_cost": 250, "exp": 1.18, "desc": "Increases interest on cash", "effect_per_level": 0.001},
		{"id": "max_interest", "name": "Max Interest", "max": 15, "base_cost": 500, "exp": 1.2, "desc": "Increases max interest cap", "effect_per_level": 1000},
		{"id": "package_after_boss", "name": "Package After Boss", "max": 1, "base_cost": 1000, "exp": 1.0, "desc": "Guaranteed package after boss", "effect_per_level": 1},
		{"id": "recovery_amount", "name": "Recovery Amount", "max": 20, "base_cost": 300, "exp": 1.18, "desc": "Increases recovery healing", "effect_per_level": 0.04},
		{"id": "recovery_max", "name": "Recovery Max", "max": 20, "base_cost": 400, "exp": 1.2, "desc": "Increases max recovery", "effect_per_level": 0.01},
		{"id": "recovery_chance", "name": "Recovery Chance", "max": 20, "base_cost": 500, "exp": 1.22, "desc": "Increases package spawn chance", "effect_per_level": 0.002},
		{"id": "enemy_attack_skip", "name": "Enemy Attack Skip", "max": 20, "base_cost": 800, "exp": 1.25, "desc": "Skips enemy attack levels", "effect_per_level": 0.1},
		{"id": "enemy_health_skip", "name": "Enemy Health Skip", "max": 20, "base_cost": 800, "exp": 1.25, "desc": "Skips enemy health levels", "effect_per_level": 0.1},
	],
}

func _ready() -> void:
	_connect_signals()
	_build_slot_buttons()
	_build_all_categories()
	_update_currency_display()
	visible = false


func _connect_signals() -> void:
	category_tabs.tab_changed.connect(_on_category_changed)
	close_btn.pressed.connect(_close)
	currency_manager.currency_changed.connect(_on_currency_changed)


func _build_slot_buttons() -> void:
	var slots_unlocked = save_manager.get("labs/slots_unlocked", 1)
	for i in 5:
		var btn = Button.new()
		btn.text = "Slot %d" % (i + 1)
		btn.toggle_mode = true
		btn.button_group = "LabSlotGroup"
		btn.pressed = (i == current_slot)
		btn.disabled = (i >= slots_unlocked)
		btn.custom_minimum_size = Vector2(80, 35)
		btn.theme_override_font_sizes["font_size"] = 14
		if i >= slots_unlocked:
			btn.tooltip_text = "Unlock with gems"
		btn.toggled.connect(_on_slot_changed.bind(i))
		slot_buttons.add_child(btn)

	# Add unlock button for locked slots
	for i in range(slots_unlocked, 5):
		var btn = slot_buttons.get_child(i)
		btn.text = "Unlock (%d💎)" % [200 * (i + 1)]
		btn.pressed.connect(_unlock_slot.bind(i))


func _build_all_categories() -> void:
	for cat_name in LAB_CATEGORIES:
		var container = _get_container_for_category(cat_name)
		if container:
			_build_category(cat_name, container)


func _get_container_for_category(cat_name: String) -> VBoxContainer:
	match cat_name:
		"Main": return main_container
		"Attack": return attack_container
		"Defense": return defense_container
		"Utility": return utility_container
		"UW": return uw_container
		"Cards": return cards_container
		"Perks": return perks_container
		"Bots": return bots_container
		"Modules": return modules_container
		"Enemies": return enemies_container
		"Battle Cond.": return battle_container
	return null


func _build_category(cat_name: String, container: VBoxContainer) -> void:
	var labs = LAB_CATEGORIES.get(cat_name, [])

	for lab in labs:
		var widget = _create_lab_widget(cat_name, lab)
		container.add_child(widget)
		lab_widgets["%s_%s" % [cat_name, lab.id]] = widget


func _create_lab_widget(cat_name: String, lab: Dictionary) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("h_separation", 10)
	container.custom_minimum_size_y = 50

	var name_label = Label.new()
	name_label.text = lab.name
	name_label.custom_minimum_size_x = 200
	name_label.theme_override_font_sizes["font_size"] = 16
	name_label.tooltip_text = lab.desc
	container.add_child(name_label)

	var level_label = Label.new()
	level_label.custom_minimum_size_x = 80
	level_label.horizontal_alignment = 1
	level_label.theme_override_font_sizes["font_size"] = 16
	container.add_child(level_label)

	var effect_label = Label.new()
	effect_label.custom_minimum_size_x = 120
	effect_label.horizontal_alignment = 1
	effect_label.theme_override_font_sizes["font_size"] = 14
	container.add_child(effect_label)

	var cost_label = Label.new()
	cost_label.custom_minimum_size_x = 100
	cost_label.horizontal_alignment = 1
	cost_label.theme_override_font_sizes["font_size"] = 14
	container.add_child(cost_label)

	var research_btn = Button.new()
	research_btn.text = "Research"
	research_btn.custom_minimum_size = Vector2(100, 40)
	research_btn.disabled = true
	container.add_child(research_btn)

	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 1
	progress_bar.value = 0
	progress_bar.custom_minimum_size = Vector2(100, 8)
	progress_bar.visible = false
	container.add_child(progress_bar)

	var max_label = Label.new()
	max_label.text = "MAX"
	max_label.custom_minimum_size_x = 100
	max_label.horizontal_alignment = 1
	max_label.theme_override_font_sizes["font_size"] = 16
	max_label.visible = false
	container.add_child(max_label)

	var widget_data = {
		"lab": lab,
		"category": cat_name,
		"level_label": level_label,
		"effect_label": effect_label,
		"cost_label": cost_label,
		"research_btn": research_btn,
		"progress_bar": progress_bar,
		"max_label": max_label,
	}
	container.set_meta("widget_data", widget_data)

	research_btn.pressed.connect(_on_research_pressed.bind(cat_name, lab.id))

	_update_lab_widget(container)

	return container


func _update_lab_widget(widget: HBoxContainer) -> void:
	var data = widget.get_meta("widget_data")
	var lab = data.lab
	var cat = data.category

	var level = save_manager.get_lab_level(lab.id)
	var max_level = lab.max
	var cost = _calculate_lab_cost(lab, level)
	var effect = level * lab.effect_per_level

	data.level_label.text = "%d / %d" % [level, max_level]

	if lab.effect_per_level >= 1:
		data.effect_label.text = "+%d" % effect
	elif lab.effect_per_level >= 0.01:
		data.effect_label.text = "×%.2f" % (1.0 + effect)
	else:
		data.effect_label.text = "+%.2f%%" % (effect * 100)

	if level >= max_level:
		data.cost_label.text = "—"
		data.research_btn.visible = false
		data.max_label.visible = true
		data.progress_bar.visible = false
	else:
		data.cost_label.text = "%s 💰" % ui_manager.format_number(cost)
		data.research_btn.visible = true
		data.max_label.visible = false

		var can_afford = currency_manager.can_afford("coins", cost)
		data.research_btn.disabled = not can_afford
		data.research_btn.text = "Research" if can_afford else "Need Coins"

		# Show progress if this is active lab
		if active_lab == lab.id:
			data.progress_bar.visible = true
			data.progress_bar.value = lab_progress
		else:
			data.progress_bar.visible = false


func _calculate_lab_cost(lab: Dictionary, level: int) -> int:
	var base = lab.base_cost
	var exp = lab.exp
	var discount = 1.0 - save_manager.get_lab_level("labs_coin_discount") * 0.003
	return int(base * pow(exp, level) * discount)


func _update_all_widgets() -> void:
	for cat_name in LAB_CATEGORIES:
		var container = _get_container_for_category(cat_name)
		if container:
			for child in container.get_children():
				if child.has_meta("widget_data"):
					_update_lab_widget(child)


func _update_currency_display() -> void:
	cell_amount.text = ui_manager.format_number(currency_manager.get_currency("elite_cells"))
	gem_amount.text = ui_manager.format_number(currency_manager.get_currency("gems"))

	var lab_speed = 1.0 + save_manager.get_lab_level("labs_speed") * 0.02
	speed_label.text = "Lab Speed: %.2fx" % lab_speed


func _on_category_changed(tab_idx: int) -> void:
	var cats = LAB_CATEGORIES.keys()
	current_category = tab_idx


func _on_slot_changed(slot_idx: int, pressed: bool) -> void:
	if pressed:
		current_slot = slot_idx
		active_lab = ""
		lab_progress = 0.0
		_update_all_widgets()


func _on_research_pressed(cat_name: String, lab_id: String) -> void:
	var level = save_manager.get_lab_level(lab_id)
	var lab = _find_lab(cat_name, lab_id)
	if not lab or level >= lab.max:
		return

	var cost = _calculate_lab_cost(lab, level)
	if not currency_manager.spend("coins", cost, "lab_%s" % lab_id):
		return

	active_lab = lab_id
	lab_progress = 0.0

	# Start research (simplified - instant for MVP)
	_finish_research(lab_id)


func _finish_research(lab_id: String) -> void:
	save_manager.set_lab_level(lab_id, save_manager.get_lab_level(lab_id) + 1)
	active_lab = ""
	lab_progress = 0.0

	AudioManager.play_level_up()
	_update_all_widgets()
	_update_currency_display()


func _unlock_slot(slot_idx: int) -> void:
	var cost = 200 * (slot_idx + 1)
	if currency_manager.spend("gems", cost, "lab_slot_%d" % slot_idx):
		save_manager.save_data["labs"]["slots_unlocked"] = slot_idx + 1
		_build_slot_buttons()
		AudioManager.play_level_up()


func _find_lab(cat_name: String, lab_id: String) -> Dictionary:
	for lab in LAB_CATEGORIES.get(cat_name, []):
		if lab.id == lab_id:
			return lab
	return null


func _on_currency_changed(currency: String, old: int, new: int) -> void:
	if currency in ["coins", "gems", "elite_cells"]:
		_update_currency_display()
		_update_all_widgets()


func _close() -> void:
	visible = false
	UIManager.menu_closed.emit("Labs")


func popup() -> void:
	visible = true
	_update_currency_display()
	_update_all_widgets()
	UIManager.menu_opened.emit("Labs")