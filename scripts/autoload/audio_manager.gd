## AudioManager — Autoload
## Bus: BGM, SFX, Ambience — terpisah, bisa di-fade.
## Ambience bersifat BERLAPIS: gerimis, dengung kulkas, dan jam dinding bisa
## berbunyi bersamaan (masing-masing punya player & volume sendiri).
## Sinyal: leitmotif_stage_changed(stage)
extends Node

signal leitmotif_stage_changed(stage: int)

# --- Bus names (dibuat di default_bus_layout.tres) ---
const BUS_BGM: StringName = &"BGM"
const BUS_SFX: StringName = &"SFX"
const BUS_AMBIENCE: StringName = &"Ambience"

# --- Chapter 1 Audio Assets Preload ---
const STREAM_RAIN: AudioStream = preload("res://assets/audio/ambience/rain_gentle_loop.wav")
const STREAM_FRIDGE: AudioStream = preload("res://assets/audio/ambience/fridge_hum_loop.wav")
const STREAM_CLOCK_TICK: AudioStream = preload("res://assets/audio/ambience/clock_tick_loop.wav")
const STREAM_PHONE_VIBRATE: AudioStream = preload("res://assets/audio/sfx/phone_vibrate.wav")
const STREAM_CLOCK_CHIME: AudioStream = preload("res://assets/audio/sfx/clock_chime.wav")
const STREAM_CHAT_TYPE: AudioStream = preload("res://assets/audio/sfx/chat_type.wav")
const STREAM_THEME_FRAGMENT_A: AudioStream = preload("res://assets/audio/bgm/theme_fragment_a.wav")
const STREAM_THEME_FRAGMENT_A_REVERSED: AudioStream = preload("res://assets/audio/bgm/theme_fragment_a_reversed.wav")
const STREAM_THEME_WARM_NOTE: AudioStream = preload("res://assets/audio/bgm/theme_warm_single_note.wav")

# --- Layer ambience default (level linear sebelum bus volume) ---
const AMB_RAIN_DB: float = -4.0
const AMB_FRIDGE_DB: float = -14.0
const AMB_CLOCK_DB: float = -20.0

var _bgm_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 4

# Ambience berlapis: nama layer -> player. Layer "main" dipakai play_ambience() lama.
var _ambience_layers: Dictionary = {}
const AMB_MAIN: StringName = &"main"
const AMB_RAIN: StringName = &"rain"
const AMB_FRIDGE: StringName = &"fridge"
const AMB_CLOCK: StringName = &"clock"

var _current_leitmotif_stage: int = 0


func _ready() -> void:
	# BGM player
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = BUS_BGM
	add_child(_bgm_player)

	# Ambience layers
	_ambience_layers[AMB_MAIN] = _make_ambience_player(0.0)
	_ambience_layers[AMB_RAIN] = _make_ambience_player(AMB_RAIN_DB)
	_ambience_layers[AMB_FRIDGE] = _make_ambience_player(AMB_FRIDGE_DB)
	_ambience_layers[AMB_CLOCK] = _make_ambience_player(AMB_CLOCK_DB)

	# SFX pool
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_pool.append(player)

	_apply_volumes()
	if not SettingsManager.settings_changed.is_connected(_apply_volumes):
		SettingsManager.settings_changed.connect(_apply_volumes)


func _make_ambience_player(level_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = BUS_AMBIENCE
	p.volume_db = level_db
	add_child(p)
	return p


func _apply_volumes() -> void:
	_set_bus_volume(BUS_BGM, SettingsManager.volume_bgm)
	_set_bus_volume(BUS_SFX, SettingsManager.volume_sfx)
	_set_bus_volume(BUS_AMBIENCE, SettingsManager.volume_ambience)


func _set_bus_volume(bus_name: StringName, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		# Bus belum ada — gunakan Master sebagai fallback saat dev
		return
	var db: float = linear_to_db(clampf(linear, 0.0, 1.0))
	AudioServer.set_bus_volume_db(idx, db)


# --- BGM ---

func play_bgm(stream: AudioStream, fade_in: float = 1.0) -> void:
	if _bgm_player.stream == stream and _bgm_player.playing:
		return
	if _bgm_player.playing:
		await fade_out_bgm(0.5)
	_bgm_player.stream = stream
	_bgm_player.volume_db = -80.0
	_bgm_player.play()
	var tw := create_tween()
	tw.tween_property(_bgm_player, "volume_db", 0.0, fade_in)


func stop_bgm(fade_out_time: float = 1.0) -> void:
	await fade_out_bgm(fade_out_time)
	_bgm_player.stop()


func fade_out_bgm(duration: float = 1.0) -> void:
	if not _bgm_player.playing:
		return
	var tw := create_tween()
	tw.tween_property(_bgm_player, "volume_db", -80.0, duration)
	await tw.finished


# --- Ambience (berlapis) ---

## Nyalakan/geser satu lapisan ambience. Layer yang sudah memutar stream yang
## sama tidak di-restart (loop tetap mulus).
func set_ambience_layer(layer: StringName, stream: AudioStream, level_db: float, fade_in: float = 2.0) -> void:
	if not _ambience_layers.has(layer):
		_ambience_layers[layer] = _make_ambience_player(level_db)
	var p: AudioStreamPlayer = _ambience_layers[layer]
	if p.stream == stream and p.playing:
		var keep := create_tween()
		keep.tween_property(p, "volume_db", level_db, fade_in)
		return
	if p.playing:
		var out := create_tween()
		out.tween_property(p, "volume_db", -80.0, minf(fade_in, 0.8))
		await out.finished
	p.stream = stream
	p.volume_db = -80.0
	p.play()
	var tw := create_tween()
	tw.tween_property(p, "volume_db", level_db, fade_in)


func stop_ambience_layer(layer: StringName, fade_out_time: float = 1.0) -> void:
	if not _ambience_layers.has(layer):
		return
	var p: AudioStreamPlayer = _ambience_layers[layer]
	if not p.playing:
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", -80.0, fade_out_time)
	await tw.finished
	p.stop()


## API lama: satu lapisan "main" (dipakai DialogueRunner untuk cue data).
func play_ambience(stream: AudioStream, fade_in: float = 2.0) -> void:
	await set_ambience_layer(AMB_MAIN, stream, 0.0, fade_in)


func stop_ambience(fade_out_time: float = 2.0) -> void:
	for layer in _ambience_layers.keys():
		stop_ambience_layer(layer, fade_out_time)


func fade_out_ambience(duration: float = 2.0) -> void:
	for layer in _ambience_layers.keys():
		var p: AudioStreamPlayer = _ambience_layers[layer]
		if p.playing:
			var tw := create_tween()
			tw.tween_property(p, "volume_db", -80.0, duration)
	await get_tree().create_timer(duration).timeout


## Susun ambience khas kamar apartemen: gerimis + dengung kulkas + jam dinding.
func play_rain(fade_in: float = 2.0) -> void:
	set_ambience_layer(AMB_RAIN, STREAM_RAIN, AMB_RAIN_DB, fade_in)
	set_ambience_layer(AMB_FRIDGE, STREAM_FRIDGE, AMB_FRIDGE_DB, fade_in)
	set_ambience_layer(AMB_CLOCK, STREAM_CLOCK_TICK, AMB_CLOCK_DB, fade_in)


## Hentikan hanya lapisan jam (mis. saat keluar kamar / jam berhenti).
func stop_clock_tick(fade_out_time: float = 1.5) -> void:
	stop_ambience_layer(AMB_CLOCK, fade_out_time)


func stop_fridge_hum(fade_out_time: float = 1.5) -> void:
	stop_ambience_layer(AMB_FRIDGE, fade_out_time)


# --- SFX ---

func play_sfx(stream: AudioStream) -> void:
	for player in _sfx_pool:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	# Semua pool penuh — pakai yang pertama (paling tua)
	_sfx_pool[0].stream = stream
	_sfx_pool[0].play()


# --- Leitmotif stage ---

func set_leitmotif_stage(stage: int) -> void:
	if stage != _current_leitmotif_stage:
		_current_leitmotif_stage = stage
		leitmotif_stage_changed.emit(stage)


func get_leitmotif_stage() -> int:
	return _current_leitmotif_stage


# --- Convenience Helpers for Chapter 1 ---

func play_theme_a(fade_in: float = 1.0) -> void:
	play_bgm(STREAM_THEME_FRAGMENT_A, fade_in)


func play_theme_a_reversed(fade_in: float = 1.0) -> void:
	play_bgm(STREAM_THEME_FRAGMENT_A_REVERSED, fade_in)


func play_warm_note(fade_in: float = 0.5) -> void:
	play_bgm(STREAM_THEME_WARM_NOTE, fade_in)


func play_vibrate() -> void:
	play_sfx(STREAM_PHONE_VIBRATE)


func play_chime() -> void:
	play_sfx(STREAM_CLOCK_CHIME)


func play_typing_sfx() -> void:
	play_sfx(STREAM_CHAT_TYPE)
