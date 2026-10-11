## Test scene untuk AudioManager
## Memverifikasi peta audio Bab 1 (AUDIO_DESIGN.md §5-§6):
##  - bus terpisah: BGM / SFX / Ambience
##  - level hujan normal vs quiet (AMB_RAIN_DB > AMB_RAIN_QUIET_DB)
##  - aset leitmotif "Tema Bulan" tergenerasi & termuat
##  - SFX konteks berbeda (door_knock != type_tick)
##  - leitmotif stage + sinkronisasi volume pemain
extends Node

var _fail: int = 0


func _ready() -> void:
	print("=== TEST: AudioManager ===")

	_test_buses_separate()
	_test_rain_levels()
	_test_leitmotif_assets()
	_test_sfx_context()
	_test_leitmotif_stage()
	_test_volume_sync()

	if _fail == 0:
		print("=== SEMUA TEST AudioManager LULUS ===")
	else:
		print("=== TEST AudioManager GAGAL: %d masalah ===" % _fail)

	# Pastikan proses headless berhenti (tanpa quit(), Godot menggantung).
	get_tree().quit(0 if _fail == 0 else 1)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: ", msg)


## MECHANICS_SPEC §Volume: musik, SFX, ambience harus terpisah.
func _test_buses_separate() -> void:
	print("  - Bus terpisah (BGM / SFX / Ambience)...")
	_check(AudioManager.BUS_BGM == &"BGM", "BUS_BGM salah")
	_check(AudioManager.BUS_SFX == &"SFX", "BUS_SFX salah")
	_check(AudioManager.BUS_AMBIENCE == &"Ambience", "BUS_AMBIENCE salah")
	var idx_bgm: int = AudioServer.get_bus_index(&"BGM")
	var idx_sfx: int = AudioServer.get_bus_index(&"SFX")
	var idx_amb: int = AudioServer.get_bus_index(&"Ambience")
	_check(idx_bgm != -1, "bus BGM tidak ada di layout")
	_check(idx_sfx != -1, "bus SFX tidak ada di layout")
	_check(idx_amb != -1, "bus Ambience tidak ada di layout")
	_check(idx_bgm != idx_sfx and idx_sfx != idx_amb and idx_bgm != idx_amb,
		"bus BGM/SFX/Ambience harus berbeda")
	print("    Bus terpisah: OK")


## §5 / D006: hujan normal lebih keras dari hujan quiet (quiet untuk intro/lift).
func _test_rain_levels() -> void:
	print("  - Level hujan normal vs quiet...")
	_check(AudioManager.AMB_RAIN_DB > AudioManager.AMB_RAIN_QUIET_DB,
		"AMB_RAIN_DB harus lebih keras (>) dari AMB_RAIN_QUIET_DB")
	_check(is_equal_approx(AudioManager.AMB_RAIN_QUIET_DB, -15.0),
		"AMB_RAIN_QUIET_DB harus -15 dB (D006)")
	_check(AudioManager.has_method("play_rain"), "play_rain() hilang")
	_check(AudioManager.has_method("play_rain_only"), "play_rain_only() hilang")
	_check(AudioManager.has_method("play_rain_quiet"), "play_rain_quiet() hilang")
	_check(AudioManager.has_method("set_rain_level"), "set_rain_level() hilang")
	_check(AudioManager.has_method("play_lift_ambience"), "play_lift_ambience() hilang")
	_check(AudioManager.has_method("stop_lift_hum"), "stop_lift_hum() hilang")
	print("    Level hujan: OK")


## §2/§7: Fragmen A (normal + dibalik) & satu nada hangat harus termuat.
func _test_leitmotif_assets() -> void:
	print("  - Aset leitmotif 'Tema Bulan'...")
	_check(AudioManager.STREAM_THEME_FRAGMENT_A != null, "Fragmen A tidak termuat")
	_check(AudioManager.STREAM_THEME_FRAGMENT_A_REVERSED != null,
		"Fragmen A dibalik tidak termuat")
	_check(AudioManager.STREAM_THEME_WARM_NOTE != null, "Nada hangat tidak termuat")
	_check(AudioManager.STREAM_RAIN != null, "Hujan tidak termuat")
	_check(AudioManager.STREAM_LIFT_HUM != null, "Hum lift tidak termuat")
	_check(AudioManager.has_method("play_theme_a"), "play_theme_a() hilang")
	_check(AudioManager.has_method("play_theme_a_reversed"), "play_theme_a_reversed() hilang")
	_check(AudioManager.has_method("play_warm_note"), "play_warm_note() hilang")
	print("    Leitmotif: OK")


## §5 / D009: ketukan pintu (door_knock) harus SFX berbeda dari ketikan (type_tick).
func _test_sfx_context() -> void:
	print("  - SFX konteks (door_knock != type_tick)...")
	_check(AudioManager.STREAM_DOOR_KNOCK != null, "door_knock tidak termuat")
	_check(AudioManager.STREAM_TYPE_TICK != null, "type_tick tidak termuat")
	_check(AudioManager.STREAM_DOOR_KNOCK != AudioManager.STREAM_TYPE_TICK,
		"door_knock harus berbeda dari type_tick (D009)")
	_check(AudioManager.STREAM_LIFT_DING != null, "lift_ding tidak termuat")
	_check(AudioManager.STREAM_FOOTSTEP != null, "footstep tidak termuat")
	print("    SFX konteks: OK")


## Sinyal leitmotif stage (dipakai LoopManager).
func _test_leitmotif_stage() -> void:
	print("  - Leitmotif stage & sinyal...")
	AudioManager.set_leitmotif_stage(0)
	_check(AudioManager.get_leitmotif_stage() == 0, "default stage salah")

	var stage_ctx: Dictionary = {"received": -1}
	AudioManager.leitmotif_stage_changed.connect(func(s: int) -> void:
		stage_ctx["received"] = s
	)
	AudioManager.set_leitmotif_stage(3)
	_check(AudioManager.get_leitmotif_stage() == 3, "set stage gagal")
	_check(stage_ctx["received"] == 3, "signal stage gagal")

	# Tidak set ulang jika sama.
	stage_ctx["received"] = -1
	AudioManager.set_leitmotif_stage(3)
	_check(stage_ctx["received"] == -1, "stage seharusnya tidak trigger ulang")
	print("    Leitmotif stage: OK")


## Volume pemain (BGM/SFX/Ambience) tersinkron ke bus terpisah (koordinasi lavis).
func _test_volume_sync() -> void:
	print("  - Sinkronisasi volume pemain...")
	var old_bgm: float = SettingsManager.volume_bgm
	var old_sfx: float = SettingsManager.volume_sfx
	var old_amb: float = SettingsManager.volume_ambience

	SettingsManager.volume_bgm = 0.5
	SettingsManager.volume_sfx = 0.3
	SettingsManager.volume_ambience = 1.0
	SettingsManager.settings_changed.emit()

	var idx_bgm: int = AudioServer.get_bus_index(&"BGM")
	var idx_sfx: int = AudioServer.get_bus_index(&"SFX")
	var idx_amb: int = AudioServer.get_bus_index(&"Ambience")
	if idx_bgm != -1 and idx_sfx != -1 and idx_amb != -1:
		_check(is_equal_approx(AudioServer.get_bus_volume_db(idx_bgm), linear_to_db(0.5)),
			"volume bus BGM tidak tersinkron")
		_check(is_equal_approx(AudioServer.get_bus_volume_db(idx_sfx), linear_to_db(0.3)),
			"volume bus SFX tidak tersinkron")
		_check(is_equal_approx(AudioServer.get_bus_volume_db(idx_amb), linear_to_db(1.0)),
			"volume bus Ambience tidak tersinkron")
		print("    Volume bus: OK")
	else:
		print("    Volume bus: skip (bus belum ada di headless)")

	SettingsManager.volume_bgm = old_bgm
	SettingsManager.volume_sfx = old_sfx
	SettingsManager.volume_ambience = old_amb
	SettingsManager.settings_changed.emit()
	print("    Sinkronisasi volume: OK")
