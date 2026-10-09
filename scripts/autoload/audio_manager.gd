## AudioManager — Autoload
## Bus: BGM, SFX, Ambience — terpisah, bisa di-fade.
## Sinyal: leitmotif_stage_changed(stage)
extends Node

signal leitmotif_stage_changed(stage: int)

# --- Bus names (harus dibuat di Godot Audio tab) ---
const BUS_BGM: StringName = &"BGM"
const BUS_SFX: StringName = &"SFX"
const BUS_AMBIENCE: StringName = &"Ambience"

var _bgm_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 4

var _current_leitmotif_stage: int = 0
var _fade_tween: Tween


func _ready() -> void:
	# BGM player
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = BUS_BGM
	add_child(_bgm_player)

	# Ambience player
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = BUS_AMBIENCE
	add_child(_ambience_player)

	# SFX pool
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_pool.append(player)

	_apply_volumes()
	if SettingsManager.settings_changed.is_connected(_apply_volumes):
		return
	SettingsManager.settings_changed.connect(_apply_volumes)


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


# --- Ambience ---

func play_ambience(stream: AudioStream, fade_in: float = 2.0) -> void:
	if _ambience_player.stream == stream and _ambience_player.playing:
		return
	if _ambience_player.playing:
		await fade_out_ambience(1.0)
	_ambience_player.stream = stream
	_ambience_player.volume_db = -80.0
	_ambience_player.play()
	var tw := create_tween()
	tw.tween_property(_ambience_player, "volume_db", 0.0, fade_in)


func stop_ambience(fade_out_time: float = 2.0) -> void:
	await fade_out_ambience(fade_out_time)
	_ambience_player.stop()


func fade_out_ambience(duration: float = 2.0) -> void:
	if not _ambience_player.playing:
		return
	var tw := create_tween()
	tw.tween_property(_ambience_player, "volume_db", -80.0, duration)
	await tw.finished


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
