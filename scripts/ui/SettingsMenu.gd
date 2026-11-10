extends CanvasLayer
class_name SettingsMenu

@onready var save_manager: SaveManager = SaveManager
@onready var audio_manager: AudioManager = AudioManager
@onready var ui_manager: UIManager = UIManager
@onready var wave_manager: WaveManager = WaveManager

@onready var master_vol: HSlider = %MasterVol
@onready var music_vol: HSlider = %MusicVol
@onready var sfx_vol: HSlider = %SfxVol
@onready var auto_battle: CheckButton = %AutoBattle
@onready var show_damage: CheckButton = %ShowDamage
@onready var show_health: CheckButton = %ShowHealth
@onready var auto_save: CheckButton = %AutoSave
@onready var notifications: CheckButton = %Notifications
@onready var show_fps: CheckButton = %ShowFPS
@onready var reduced_motion: CheckButton = %ReducedMotion
@onready var high_contrast: CheckButton = %HighContrast
@onready var vsync: CheckButton = %VSync
@onready var save_btn: Button = %SaveBtn
@onready var export_btn: Button = %ExportBtn
@onready var import_btn: Button = %ImportBtn
@onready var reset_btn: Button = %ResetBtn
@onready var close_btn: Button = %CloseBtn

func _ready() -> void:
	_connect_signals()
	_load_settings()
	visible = false


func _connect_signals() -> void:
	close_btn.pressed.connect(_close)

	master_vol.value_changed.connect(_on_master_vol_changed)
	music_vol.value_changed.connect(_on_music_vol_changed)
	sfx_vol.value_changed.connect(_on_sfx_vol_changed)

	auto_battle.toggled.connect(_on_auto_battle_toggled)
	show_damage.toggled.connect(_on_show_damage_toggled)
	show_health.toggled.connect(_on_show_health_toggled)
	auto_save.toggled.connect(_on_auto_save_toggled)
	notifications.toggled.connect(_on_notifications_toggled)

	show_fps.toggled.connect(_on_show_fps_toggled)
	reduced_motion.toggled.connect(_on_reduced_motion_toggled)
	high_contrast.toggled.connect(_on_high_contrast_toggled)
	vsync.toggled.connect(_on_vsync_toggled)

	save_btn.pressed.connect(_save_game)
	export_btn.pressed.connect(_export_save)
	import_btn.pressed.connect(_import_save)
	reset_btn.pressed.connect(_confirm_reset)


func _load_settings() -> void:
	master_vol.value = save_manager.get_setting("master_volume", 1.0)
	music_vol.value = save_manager.get_setting("music_volume", 0.7)
	sfx_vol.value = save_manager.get_setting("sfx_volume", 0.8)

	auto_battle.button_pressed = save_manager.get_setting("auto_battle", false)
	show_damage.button_pressed = save_manager.get_setting("show_damage_numbers", true)
	show_health.button_pressed = save_manager.get_setting("show_health_bars", true)
	auto_save.button_pressed = save_manager.get_setting("auto_save", true)
	notifications.button_pressed = save_manager.get_setting("notifications", true)

	show_fps.button_pressed = save_manager.get_setting("show_fps", false)
	reduced_motion.button_pressed = save_manager.get_setting("reduced_motion", false)
	high_contrast.button_pressed = save_manager.get_setting("high_contrast", false)
	vsync.button_pressed = save_manager.get_setting("vsync", true)

	_apply_graphics_settings()


func _on_master_vol_changed(value: float) -> void:
	audio_manager.set_volume("Master", value)
	save_manager.set_setting("master_volume", value)


func _on_music_vol_changed(value: float) -> void:
	audio_manager.set_volume("Music", value)
	save_manager.set_setting("music_volume", value)


func _on_sfx_vol_changed(value: float) -> void:
	audio_manager.set_volume("SFX", value)
	save_manager.set_setting("sfx_volume", value)


func _on_auto_battle_toggled(pressed: bool) -> void:
	save_manager.set_setting("auto_battle", pressed)


func _on_show_damage_toggled(pressed: bool) -> void:
	save_manager.set_setting("show_damage_numbers", pressed)


func _on_show_health_toggled(pressed: bool) -> void:
	save_manager.set_setting("show_health_bars", pressed)


func _on_auto_save_toggled(pressed: bool) -> void:
	save_manager.set_setting("auto_save", pressed)


func _on_notifications_toggled(pressed: bool) -> void:
	save_manager.set_setting("notifications", pressed)


func _on_show_fps_toggled(pressed: bool) -> void:
	save_manager.set_setting("show_fps", pressed)
	Engine.debug_draw_overdraw = pressed  # Simplified


func _on_reduced_motion_toggled(pressed: bool) -> void:
	save_manager.set_setting("reduced_motion", pressed)
	ui_manager.set_reduced_motion(pressed)


func _on_high_contrast_toggled(pressed: bool) -> void:
	save_manager.set_setting("high_contrast", pressed)
	ui_manager.set_high_contrast(pressed)


func _on_vsync_toggled(pressed: bool) -> void:
	save_manager.set_setting("vsync", pressed)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if pressed else DisplayServer.VSYNC_DISABLED)


func _apply_graphics_settings() -> void:
	# Apply VSync
	var vs = save_manager.get_setting("vsync", true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vs else DisplayServer.VSYNC_DISABLED)

	# Apply reduced motion
	var rm = save_manager.get_setting("reduced_motion", false)
	ui_manager.set_reduced_motion(rm)

	# Apply high contrast
	var hc = save_manager.get_setting("high_contrast", false)
	ui_manager.set_high_contrast(hc)


func _save_game() -> void:
	save_manager.save_game()
	UIManager.show_success("Game saved!")


func _export_save() -> void:
	# Would export save to file
	UIManager.show_info("Save export not implemented in MVP")


func _import_save() -> void:
	# Would import save from file
	UIManager.show_info("Save import not implemented in MVP")


func _confirm_reset() -> void:
	UIManager.confirm_action(
		"Reset Game",
		"This will DELETE ALL PROGRESS. Are you sure?",
		"Reset",
		"Cancel"
	).then(func(confirmed: bool):
		if confirmed:
			_reset_game()
	)


func _reset_game() -> void:
	save_manager.save_data.clear()
	save_manager.new_game()
	save_manager.save_game()
	UIManager.show_warning("Game reset! Restarting...")
	get_tree().reload_current_scene()


func _close() -> void:
	visible = false
	UIManager.menu_closed.emit("Settings")


func popup() -> void:
	visible = true
	_load_settings()
	UIManager.menu_opened.emit("Settings")