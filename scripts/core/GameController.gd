extends Node
class_name GameController

signal game_started
signal game_paused
signal game_resumed
signal run_ended

@onready var save_manager: SaveManager = SaveManager
@onready var wave_manager: WaveManager = WaveManager
@onready var currency_manager: CurrencyManager = CurrencyManager
@onready var workshop_manager: WorkshopManager = WorkshopManager
@onready var audio_manager: AudioManager = AudioManager
@onready var ui_manager: UIManager = UIManager

var is_running: bool = false
var is_paused: bool = false
var run_start_time: float = 0.0
var total_playtime: float = 0.0

func _ready() -> void:
	_connect_signals()
	_init_new_game_if_needed()

	# Start music
	audio_manager.play_music("ambient_calm")


func _connect_signals() -> void:
	save_manager.load_completed.connect(_on_load_completed)
	save_manager.save_completed.connect(_on_save_completed)

	wave_manager.game_over.connect(_on_game_over)
	wave_manager.tier_upgraded.connect(_on_tier_upgraded)

	ui_manager.menu_opened.connect(_on_menu_opened)
	ui_manager.menu_closed.connect(_on_menu_closed)


func _init_new_game_if_needed() -> void:
	if not save_manager.has("tier"):
		save_manager.new_game()
		save_manager.save_game()


func _on_load_completed(success: bool) -> void:
	if success:
		print("Game loaded successfully")
		_restore_game_state()
	else:
		print("No save found, starting new game")
		save_manager.new_game()


func _restore_game_state() -> void:
	var tier = save_manager.get("tier", 1)
	var wave = save_manager.get("wave", 0)
	var speed = save_manager.get_setting("game_speed", 1.0)

	wave_manager.set_game_speed(speed)

	if wave > 0:
		# Resume run
		start_run()


func _on_save_completed(success: bool) -> void:
	if not success:
		ui_manager.show_error("Failed to save game!")


func _on_menu_opened(menu: String) -> void:
	if menu != "Settings" and is_running:
		pause_game()


func _on_menu_closed(menu: String) -> void:
	if not ui_manager.get_current_menu() and is_paused:
		resume_game()


func _on_game_over() -> void:
	end_run()
	ui_manager.show_error("Game Over! Tower destroyed.", 10.0)
	audio_manager.play_error()


func _on_tier_upgraded(new_tier: int) -> void:
	audio_manager.play_prestige()
	save_manager.save_game()


func start_run() -> void:
	if is_running:
		return

	is_running = true
	is_paused = false
	run_start_time = Time.get_ticks_msec() / 1000.0

	# Reset temporary workshop upgrades
	workshop_manager.reset_run_upgrades()

	# Reset tower
	var tower = get_tree().get_first_node_in_group("tower")
	if tower:
		tower.current_health = tower.max_health
		tower.shield_current = tower.shield_max
		tower.heatup_stacks = 0

	# Start wave manager
	wave_manager.start_run()

	# Start music
	audio_manager.play_music("battle")

	game_started.emit()


func end_run() -> void:
	if not is_running:
		return

	is_running = false
	is_paused = false

	var run_time = Time.get_ticks_msec() / 1000.0 - run_start_time
	total_playtime += run_time
	save_manager.save_data["statistics"]["total_playtime"] = total_playtime

	wave_manager.end_run()
	audio_manager.play_music("ambient_calm", 3.0)
	save_manager.save_game()

	run_ended.emit()


func pause_game() -> void:
	if not is_running or is_paused:
		return

	is_paused = true
	wave_manager.set_game_speed(0.0)
	game_paused.emit()


func resume_game() -> void:
	if not is_running or not is_paused:
		return

	is_paused = false
	var speed = save_manager.get_setting("game_speed", 1.0)
	wave_manager.set_game_speed(speed)
	game_resumed.emit()


func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()


func prestige() -> void:
	# Manual prestige (if wave requirement met)
	var tier = save_manager.get("tier", 1)
	var wave = save_manager.get("wave", 0)
	var required = GameData.new().get_waves_for_tier_milestone(tier)

	if wave >= required and tier < 24:
		end_run()
		# Wave manager handles the actual prestige
	else:
		ui_manager.show_warning("Need wave %d to prestige!" % required)


func get_run_time() -> float:
	if not is_running:
		return 0.0
	return Time.get_ticks_msec() / 1000.0 - run_start_time


func get_total_playtime() -> float:
	return total_playtime + get_run_time()


func quit_to_menu() -> void:
	end_run()
	save_manager.save_game()
	get_tree().quit()


func _process(delta: float) -> void:
	# Auto-save
	static var auto_save_timer = 0.0
	auto_save_timer += delta
	if auto_save_timer >= GameData.new().auto_save_interval:
		save_manager.save_game()
		auto_save_timer = 0.0