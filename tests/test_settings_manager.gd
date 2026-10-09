## Test scene untuk SettingsManager
extends Node

func _ready() -> void:
	print("=== TEST: SettingsManager ===")

	# Test default values
	assert(SettingsManager.text_speed == 1.0, "default text_speed salah")
	assert(SettingsManager.volume_bgm == 0.8, "default volume_bgm salah")
	assert(SettingsManager.skip_sensitive_scenes == false, "default skip salah")
	assert(SettingsManager.no_time_pressure == false, "default no_time_pressure salah")

	# Test modify & save
	SettingsManager.text_speed = 2.0
	SettingsManager.skip_sensitive_scenes = true
	SettingsManager.volume_sfx = 0.5
	SettingsManager.save_settings()

	# Test reload
	SettingsManager.text_speed = 0.0  # sementara rusak
	SettingsManager.load_settings()
	assert(SettingsManager.text_speed == 2.0, "load_settings text_speed gagal")
	assert(SettingsManager.skip_sensitive_scenes == true, "load_settings skip gagal")
	assert(SettingsManager.volume_sfx == 0.5, "load_settings volume_sfx gagal")

	# Test signal
	var signal_ctx: Dictionary = {"fired": false}
	SettingsManager.settings_changed.connect(func() -> void:
		signal_ctx["fired"] = true
	)
	SettingsManager.save_settings()
	assert(signal_ctx["fired"] == true, "signal settings_changed tidak terpancar")

	# Test reset
	SettingsManager.reset_to_defaults()
	assert(SettingsManager.text_speed == 1.0, "reset text_speed gagal")
	assert(SettingsManager.skip_sensitive_scenes == false, "reset skip gagal")
	assert(SettingsManager.volume_sfx == 0.8, "reset volume_sfx gagal")

	print("=== SEMUA TEST SettingsManager LULUS ===")
