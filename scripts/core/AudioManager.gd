extends Node
class_name AudioManager

@onready var save_manager: SaveManager = SaveManager

# Audio buses
const BUS_MASTER = "Master"
const BUS_MUSIC = "Music"
const BUS_SFX = "SFX"
const BUS_UI = "UI"

# Sound effects (generated procedurally)
var sfx_library: Dictionary = {}
var music_player: AudioStreamPlayer = null
var current_music: String = ""

func _ready() -> void:
	_generate_sfx()
	_setup_music_player()
	_apply_volumes()

	# Load saved volumes
	var master = save_manager.get_setting("master_volume", 1.0)
	var music = save_manager.get_setting("music_volume", 0.7)
	var sfx = save_manager.get_setting("sfx_volume", 0.8)
	set_volume(BUS_MASTER, master)
	set_volume(BUS_MUSIC, music)
	set_volume(BUS_SFX, sfx)


func _generate_sfx() -> void:
	# Generate procedural sound effects using AudioStreamGenerator

	# Shoot sound
	sfx_library["shoot"] = _create_tone(440, 0.1, 0.3, "square")

	# Hit sound
	sfx_library["hit"] = _create_tone(220, 0.05, 0.4, "saw")

	# Kill sound
	sfx_library["kill"] = _create_chord([330, 440, 550], 0.15, 0.3, "sine")

	# Level up
	sfx_library["level_up"] = _create_arpeggio([262, 330, 392, 523], 0.08, 0.4, "sine")

	# Coin gain
	sfx_library["coin"] = _create_tone(880, 0.03, 0.2, "sine")

	# Gem gain
	sfx_library["gem"] = _create_chord([660, 880, 1100], 0.2, 0.3, "sine")

	# Wave start
	sfx_library["wave_start"] = _create_tone(150, 0.3, 0.3, "saw")

	# Boss spawn
	sfx_library["boss_spawn"] = _create_sweep(100, 50, 1.0, 0.5, "saw")

	# Ultimate weapon
	sfx_library["uw_activate"] = _create_chord([220, 330, 440, 550], 0.5, 0.4, "square")

	# Bot activate
	sfx_library["bot_activate"] = _create_arpeggio([440, 550, 660, 880], 0.05, 0.3, "sine")

	# Upgrade purchase
	sfx_library["upgrade"] = _create_tone(523, 0.1, 0.3, "sine")

	# Error/insufficient funds
	sfx_library["error"] = _create_tone(150, 0.2, 0.4, "saw")

	# UI click
	sfx_library["click"] = _create_tone(800, 0.02, 0.15, "square")

	# UI hover
	sfx_library["hover"] = _create_tone(1000, 0.01, 0.1, "sine")

	# Prestige/tier up
	sfx_library["prestige"] = _create_arpeggio([262, 392, 523, 784, 1047], 0.1, 0.5, "sine")

	# Relic unlock
	sfx_library["relic"] = _create_chord([523, 660, 784, 1047], 0.8, 0.4, "sine")


func _create_tone(freq: float, duration: float, volume: float, wave: String) -> AudioStreamGenerator:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	var length = int(44100 * duration)
	var data = PackedFloat32Array()
	data.resize(length * 2)  # Stereo

	for i in range(length):
		var t = i / 44100.0
		var envelope = 1.0 - (t / duration)
		var sample = 0.0

		match wave:
			"sine": sample = sin(TAU * freq * t)
			"square": sample = 1.0 if sin(TAU * freq * t) > 0 else -1.0
			"saw": sample = 2.0 * (t * freq - floor(t * freq + 0.5))
			"triangle": sample = 2.0 * abs(2.0 * (t * freq - floor(t * freq + 0.5))) - 1.0

		sample *= envelope * volume
		data[i * 2] = sample
		data[i * 2 + 1] = sample

	generator.push_frame(data)
	return generator


func _create_chord(freqs: Array[float], duration: float, volume: float, wave: String) -> AudioStreamGenerator:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	var length = int(44100 * duration)
	var data = PackedFloat32Array()
	data.resize(length * 2)

	for i in range(length):
		var t = i / 44100.0
		var envelope = 1.0 - (t / duration)
		var sample = 0.0

		for freq in freqs:
			match wave:
				"sine": sample += sin(TAU * freq * t)
				"square": sample += 1.0 if sin(TAU * freq * t) > 0 else -1.0
				"saw": sample += 2.0 * (t * freq - floor(t * freq + 0.5))

		sample /= freqs.size()
		sample *= envelope * volume
		data[i * 2] = sample
		data[i * 2 + 1] = sample

	generator.push_frame(data)
	return generator


func _create_arpeggio(freqs: Array[float], note_duration: float, volume: float, wave: String) -> AudioStreamGenerator:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	var total_duration = note_duration * freqs.size()
	var length = int(44100 * total_duration)
	var data = PackedFloat32Array()
	data.resize(length * 2)

	for i in range(length):
		var t = i / 44100.0
		var note_index = min(int(t / note_duration), freqs.size() - 1)
		var note_t = fmod(t, note_duration)
		var envelope = 1.0 - (note_t / note_duration)
		var freq = freqs[note_index]
		var sample = 0.0

		match wave:
			"sine": sample = sin(TAU * freq * note_t)
			"square": sample = 1.0 if sin(TAU * freq * note_t) > 0 else -1.0
			"saw": sample = 2.0 * (note_t * freq - floor(note_t * freq + 0.5))

		sample *= envelope * volume
		data[i * 2] = sample
		data[i * 2 + 1] = sample

	generator.push_frame(data)
	return generator


func _create_sweep(start_freq: float, end_freq: float, duration: float, volume: float, wave: String) -> AudioStreamGenerator:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	var length = int(44100 * duration)
	var data = PackedFloat32Array()
	data.resize(length * 2)

	for i in range(length):
		var t = i / 44100.0
		var progress = t / duration
		var freq = lerp(start_freq, end_freq, progress)
		var envelope = 1.0 - progress
		var sample = 0.0

		match wave:
			"sine": sample = sin(TAU * freq * t)
			"square": sample = 1.0 if sin(TAU * freq * t) > 0 else -1.0
			"saw": sample = 2.0 * (t * freq - floor(t * freq + 0.5))

		sample *= envelope * volume
		data[i * 2] = sample
		data[i * 2 + 1] = sample

	generator.push_frame(data)
	return generator


func _setup_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = BUS_MUSIC
	add_child(music_player)

	# Generate ambient music loops
	_generate_music_tracks()


func _generate_music_tracks() -> void:
	# Create a few ambient music tracks
	music_library = {}

	# Calm ambient
	music_library["ambient_calm"] = _create_ambient_track([130.8, 174.6, 196.0, 261.6], 30.0, 0.15)

	# Tense ambient (higher tiers)
	music_library["ambient_tense"] = _create_ambient_track([110.0, 130.8, 164.8, 220.0], 30.0, 0.2)

	# Battle music
	music_library["battle"] = _create_ambient_track([220.0, 277.2, 330.0, 440.0], 20.0, 0.25)

	# Boss music
	music_library["boss"] = _create_ambient_track([110.0, 138.6, 164.8, 220.0], 15.0, 0.3)

	# Menu music
	music_library["menu"] = _create_ambient_track([261.6, 329.6, 392.0, 523.3], 40.0, 0.12)


func _create_ambient_track(freqs: Array[float], duration: float, volume: float) -> AudioStreamGenerator:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	var length = int(44100 * duration)
	var data = PackedFloat32Array()
	data.resize(length * 2)

	var chord_duration = duration / 8.0  # 8 chords per loop

	for i in range(length):
		var t = i / 44100.0
		var chord_index = int(fmod(t, duration) / chord_duration) % 8
		var chord_t = fmod(t, chord_duration)
		var envelope = 0.5 + 0.5 * sin(TAU * 0.1 * t)  # Slow breathing

		# Pick notes for this chord
		var base_idx = chord_index % freqs.size()
		var chord_freqs = [
			freqs[base_idx],
			freqs[(base_idx + 2) % freqs.size()] * 2,
			freqs[(base_idx + 4) % freqs.size()] * 2,
		]

		var sample = 0.0
		for freq in chord_freqs:
			sample += sin(TAU * freq * chord_t) * 0.3
			sample += sin(TAU * freq * 2 * chord_t) * 0.1

		sample *= envelope * volume
		data[i * 2] = sample
		data[i * 2 + 1] = sample

	generator.push_frame(data)
	return generator


func _apply_volumes() -> void:
	AudioServer.set_bus_volume_db(BUS_MASTER, linear_to_db(save_manager.get_setting("master_volume", 1.0)))
	AudioServer.set_bus_volume_db(BUS_MUSIC, linear_to_db(save_manager.get_setting("music_volume", 0.7)))
	AudioServer.set_bus_volume_db(BUS_SFX, linear_to_db(save_manager.get_setting("sfx_volume", 0.8)))
	AudioServer.set_bus_volume_db(BUS_UI, linear_to_db(save_manager.get_setting("sfx_volume", 0.8)))


func play_sfx(name: String, volume: float = 1.0, pitch: float = 1.0, position: Vector2 = Vector2.ZERO) -> void:
	if not sfx_library.has(name):
		return

	var player = AudioStreamPlayer2D.new()
	player.stream = sfx_library[name]
	player.volume_db = linear_to_db(volume)
	player.pitch_scale = pitch
	player.global_position = position
	player.autoplay = true
	add_child(player)

	# Cleanup when finished
	player.finished.connect(func(): player.queue_free())


func play_music(track: String, fade_time: float = 2.0) -> void:
	if not music_library.has(track):
		return

	if current_music == track and music_player.playing:
		return

	# Fade out current
	if music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_time)
		tween.tween_callback(func(): _switch_music(track, fade_time))
	else:
		_switch_music(track, fade_time)


func _switch_music(track: String, fade_time: float) -> void:
	music_player.stream = music_library[track]
	music_player.volume_db = -80
	music_player.play()
	current_music = track

	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", linear_to_db(save_manager.get_setting("music_volume", 0.7)), fade_time)


func stop_music(fade_time: float = 2.0) -> void:
	if music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_time)
		tween.tween_callback(func(): music_player.stop())
		current_music = ""


func set_volume(bus: String, volume: float) -> void:
	volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(volume))
	save_manager.set_setting("%s_volume" % bus.to_lower(), volume)
	save_manager.save_settings()


func get_volume(bus: String) -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(bus))


func linear_to_db(linear: float) -> float:
	if linear <= 0:
		return -80.0
	return 20.0 * log10(linear)


func db_to_linear(db: float) -> float:
	return pow(10.0, db / 20.0)


# --- Convenience methods ---

func play_shoot(pitch: float = 1.0) -> void:
	play_sfx("shoot", 0.3, pitch)

func play_hit(pitch: float = 1.0) -> void:
	play_sfx("hit", 0.4, pitch)

func play_kill(pitch: float = 1.0) -> void:
	play_sfx("kill", 0.3, pitch)

func play_level_up() -> void:
	play_sfx("level_up", 0.5)

func play_coin(amount: int = 1) -> void:
	var vol = clamp(0.1 + amount * 0.01, 0.1, 0.5)
	play_sfx("coin", vol)

func play_gem() -> void:
	play_sfx("gem", 0.5)

func play_wave_start() -> void:
	play_sfx("wave_start", 0.4)

func play_boss_spawn() -> void:
	play_sfx("boss_spawn", 0.6)

func play_uw_activate() -> void:
	play_sfx("uw_activate", 0.5)

func play_bot_activate() -> void:
	play_sfx("bot_activate", 0.4)

func play_upgrade() -> void:
	play_sfx("upgrade", 0.4)

func play_error() -> void:
	play_sfx("error", 0.5)

func play_click() -> void:
	play_sfx("click", 0.3)

func play_hover() -> void:
	play_sfx("hover", 0.15)

func play_prestige() -> void:
	play_sfx("prestige", 0.6)

func play_relic() -> void:
	play_sfx("relic", 0.5)