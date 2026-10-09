## SettingsManager — Autoload
## Pengaturan pemain: volume, kecepatan teks, aksesibilitas, lewati adegan sensitif.
## Simpan/muat ke user://settings.cfg
extends Node

signal settings_changed()

const SETTINGS_PATH: String = "user://settings.cfg"

# --- Nilai default ---
var text_speed: float = 1.0           # pengali kecepatan teks (0.5 = lambat, 2.0 = cepat)
var volume_bgm: float = 0.8
var volume_sfx: float = 0.8
var volume_ambience: float = 0.8
var skip_sensitive_scenes: bool = false
var no_time_pressure: bool = false
var high_contrast: bool = false
var reduce_flash: bool = false
var font_size_multiplier: float = 1.0


func _ready() -> void:
	load_settings()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "volume_bgm", volume_bgm)
	config.set_value("audio", "volume_sfx", volume_sfx)
	config.set_value("audio", "volume_ambience", volume_ambience)
	config.set_value("gameplay", "text_speed", text_speed)
	config.set_value("gameplay", "skip_sensitive_scenes", skip_sensitive_scenes)
	config.set_value("gameplay", "no_time_pressure", no_time_pressure)
	config.set_value("accessibility", "high_contrast", high_contrast)
	config.set_value("accessibility", "reduce_flash", reduce_flash)
	config.set_value("accessibility", "font_size_multiplier", font_size_multiplier)
	config.save(SETTINGS_PATH)
	settings_changed.emit()


func load_settings() -> void:
	var config := ConfigFile.new()
	var err: Error = config.load(SETTINGS_PATH)
	if err != OK:
		return  # pakai default

	volume_bgm = config.get_value("audio", "volume_bgm", volume_bgm)
	volume_sfx = config.get_value("audio", "volume_sfx", volume_sfx)
	volume_ambience = config.get_value("audio", "volume_ambience", volume_ambience)
	text_speed = config.get_value("gameplay", "text_speed", text_speed)
	skip_sensitive_scenes = config.get_value("gameplay", "skip_sensitive_scenes", skip_sensitive_scenes)
	no_time_pressure = config.get_value("gameplay", "no_time_pressure", no_time_pressure)
	high_contrast = config.get_value("accessibility", "high_contrast", high_contrast)
	reduce_flash = config.get_value("accessibility", "reduce_flash", reduce_flash)
	font_size_multiplier = config.get_value("accessibility", "font_size_multiplier", font_size_multiplier)
	settings_changed.emit()


func reset_to_defaults() -> void:
	text_speed = 1.0
	volume_bgm = 0.8
	volume_sfx = 0.8
	volume_ambience = 0.8
	skip_sensitive_scenes = false
	no_time_pressure = false
	high_contrast = false
	reduce_flash = false
	font_size_multiplier = 1.0
	save_settings()
