## Test intro cutscene "bangun" (gaya komik).
## Memastikan: mulai dari layar hitam, panel muncul (FadeRect memudar),
## blur berkurang, dan pada akhirnya pindah ke kamar.
extends Node

const INTRO_SCENE = preload("res://scenes/intro/intro_cutscene.tscn")


func _ready() -> void:
	print("=== TEST: INTRO CUTSCENE (BANGUN) ===")
	TranslationServer.set_locale("id")

	var intro: IntroCutscene = INTRO_SCENE.instantiate()
	intro.auto_start = false
	add_child(intro)
	await get_tree().process_frame

	# 1. Layar harus mulai HITAM TOTAL
	assert(intro.fade_rect.color.a == 1.0, "intro: layar harus mulai hitam penuh")

	# 1b. Monolog harus digambar DI ATAS tirai hitam (kalau tidak, teks tak terlihat)
	assert(intro.monologue_label.get_index() > intro.fade_rect.get_index(),
		"intro: MonologueLabel harus di atas FadeRect agar teks terlihat")

	# 2. Panel pertama ada & teksturnya termuat
	assert(intro.panel != null, "intro: Panel tidak ada")
	assert(IntroCutscene.PANELS.size() == 4, "intro: harus ada 4 panel komik")

	# 3. Jalankan intro (dengan text_speed tinggi agar cepat)
	var old_speed: float = SettingsManager.text_speed
	SettingsManager.text_speed = 100.0

	var finished: Dictionary = {"ok": false}
	intro.intro_finished.connect(func() -> void: finished["ok"] = true)

	# Percepat: langsung main, lalu tunggu tirai hitam mulai memudar
	intro.play_intro()
	await get_tree().create_timer(0.4).timeout
	# Saat mata masih tertutup: monolog tampil, tirai masih hitam penuh
	assert(intro.monologue_label.visible == true,
		"intro: monolog pembuka harus tampil saat mata masih tertutup")

	# Tunggu monolog selesai & tirai mulai memudar (membuka mata)
	var guard0 := 0
	while intro.fade_rect.color.a >= 1.0 and guard0 < 400:
		await get_tree().create_timer(0.1).timeout
		guard0 += 1
	assert(intro.fade_rect.color.a < 1.0,
		"intro: tirai hitam harus mulai memudar setelah monolog (membuka mata)")
	assert(intro.panel.texture != null, "intro: panel harus punya tekstur")

	# Tunggu sampai intro selesai
	var guard := 0
	while not finished["ok"] and guard < 600:
		await get_tree().create_timer(0.1).timeout
		guard += 1
	assert(finished["ok"] == true, "intro: intro_finished harus dipancarkan")

	SettingsManager.text_speed = old_speed
	intro.queue_free()
	print("    Intro cutscene: OK")
	print("=== SEMUA TEST INTRO LULUS ===")
	get_tree().quit(0)
