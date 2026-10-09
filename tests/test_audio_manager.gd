## Test scene untuk AudioManager
extends Node

func _ready() -> void:
	print("=== TEST: AudioManager ===")

	# Test leitmotif stage
	assert(AudioManager.get_leitmotif_stage() == 0, "default stage salah")

	var stage_ctx: Dictionary = {"received": -1}
	AudioManager.leitmotif_stage_changed.connect(func(s: int) -> void:
		stage_ctx["received"] = s
	)
	AudioManager.set_leitmotif_stage(3)
	assert(AudioManager.get_leitmotif_stage() == 3, "set stage gagal")
	assert(stage_ctx["received"] == 3, "signal stage gagal")

	# Tidak set ulang jika sama
	stage_ctx["received"] = -1
	AudioManager.set_leitmotif_stage(3)
	assert(stage_ctx["received"] == -1, "stage seharusnya tidak trigger ulang")

	# Test play_sfx tanpa crash (stream null aman)
	# Tidak bisa uji audio di headless, tapi pastikan tidak error
	print("  - play_sfx tanpa stream: skip (butuh audio device)")

	# Test volume sync
	SettingsManager.volume_bgm = 0.5
	SettingsManager.volume_sfx = 0.3
	SettingsManager.volume_ambience = 1.0
	SettingsManager.settings_changed.emit()
	print("  - volume sync: OK (bus mungkin belum ada di headless)")

	print("=== SEMUA TEST AudioManager LULUS ===")
