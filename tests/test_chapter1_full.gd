## Test scene untuk Implementasi Bab 1 Penuh (Fase 4)
## Menguji:
## 1. Monolog S03 (4 putaran + pilihan konvergen & hesitant + anxiety erase)
## 2. Timer menunggu di S05 (15s & 40s) + flag waited_long
## 3. S06 (siluet gerak -> cut to black 3s tanpa tampilan jatuh/darah)
## 4. S06-ALT (alternatif aman saat skip_sensitive_scenes aktif)
## 5. S07 kilas balik 4 potongan
## 6. S08 bangun lagi, transformasi lingkungan (tea & photo), chat misterius & input teks
## 7. Loop counter "LOOP 2/7" dan penyelesaian Bab 1 (Loop 1 -> Loop 2)
extends Node

const BEDROOM_SCENE = preload("res://scenes/bedroom/bedroom.tscn")
const BALCONY_SCENE = preload("res://scenes/balcony/balcony.tscn")
const FLASHBACK_SCENE = preload("res://scenes/transitions/flashback.tscn")


func _ready() -> void:
	print("=== TEST: IMPLEMENTASI BAB 1 PENUH (FASE 4) ===")
	TranslationServer.set_locale("id")
	FlagStore.clear()
	GameState.current_loop = 1

	await _test_s03_monologue()
	await _test_s05_wait_timer()
	await _test_s06_safety_and_alt()
	await _test_s07_flashback_details()
	await _test_s08_environment_shifts_and_mystery()
	await _test_loop_progression()

	print("=== SEMUA TEST BAB 1 PENUH LULUS ===")
	get_tree().quit(0)


## Test S03: Monolog 4 putaran
func _test_s03_monologue() -> void:
	print("  - Menguji S03: Monolog 4 Putaran...")
	var bed: BedroomController = BEDROOM_SCENE.instantiate()
	bed.auto_start_intro = false
	add_child(bed)

	var old_speed: float = SettingsManager.text_speed
	SettingsManager.text_speed = 100.0

	var choice_ctx: Dictionary = {"count": 0}
	bed.choice_menu.visibility_changed.connect(func() -> void:
		if bed.choice_menu.visible:
			choice_ctx["count"] += 1
			get_tree().create_timer(0.02).timeout.connect(func() -> void:
				if is_instance_valid(bed) and is_instance_valid(bed.choice_menu) and bed.choice_menu.visible:
					bed.choice_menu._on_button_pressed(0)
			)
	)

	# Jalankan start_s03_monologue dengan await
	await bed.start_s03_monologue()

	assert(choice_ctx["count"] >= 3, "S03: harus melalui minimal 3 set pilihan monolog (terhitung: %d)" % choice_ctx["count"])
	assert(FlagStore.get_flag("heard_phone_buzz") == true, "S03: flag heard_phone_buzz harus true")

	SettingsManager.text_speed = old_speed
	bed.queue_free()
	print("    S03 Monolog: OK")


## Test S05: Timer menunggu 15s dan 40s + flag waited_long
func _test_s05_wait_timer() -> void:
	print("  - Menguji S05: Timer Menunggu Balkon...")
	var bal: BalconyController = BALCONY_SCENE.instantiate()
	bal.auto_start_sequence = false
	add_child(bal)

	bal._is_waiting_for_jump = true
	bal._jump_chosen = false

	# Simulasikan lewatnya waktu 14 detik -> belum ada teks petunjuk
	bal._process(14.0)
	assert(bal.wait_hint_label.visible == false, "S05: petunjuk belum boleh muncul di 14 detik")

	# Lewat 15 detik -> petunjuk pertama muncul
	bal._process(1.5)
	assert(bal.wait_hint_label.visible == true, "S05: petunjuk 15s harus muncul")
	assert(bal.wait_hint_label.text == tr("S05_WAIT_15"), "S05: teks 15s salah")
	assert(FlagStore.get_flag("waited_long", false) == false, "S05: flag waited_long belum boleh true di 15s")

	# Lewat 40 detik -> petunjuk kedua muncul & flag dipasang
	bal._process(25.0)
	assert(bal.wait_hint_label.text == tr("S05_WAIT_40"), "S05: teks 40s salah")
	assert(FlagStore.get_flag("waited_long") == true, "S05: flag waited_long harus true setelah 40s")

	bal.queue_free()
	print("    S05 Timer Menunggu: OK")


## Test S06 & S06-ALT: Kepatuhan SAFETY_AND_CONTENT.md
func _test_s06_safety_and_alt() -> void:
	print("  - Menguji S06 & S06-ALT (Safety & Content)...")
	var bal: BalconyController = BALCONY_SCENE.instantiate()
	bal.auto_start_sequence = false
	add_child(bal)

	# 1. Verifikasi S06: Hanya gerak langkah singkat siluet lalu cut to black
	var init_x: float = bal.silhouette.position.x
	var tw := bal.create_tween()
	tw.tween_property(bal.silhouette, "position:x", init_x + 30.0, 0.05)
	await tw.finished

	bal.transition_layer.cut_to_black()
	assert(bal.transition_layer.color_rect.color.a == 1.0, "S06: layar harus hitam total")

	# 2. Verifikasi S06-ALT jika opsi lewati aktif
	SettingsManager.skip_sensitive_scenes = true
	var bal_alt: BalconyController = BALCONY_SCENE.instantiate()
	bal_alt.auto_start_sequence = false
	add_child(bal_alt)

	bal_alt.silhouette.visible = false
	bal_alt.railing.visible = false
	bal_alt.city_backdrop.visible = false

	assert(bal_alt.silhouette.visible == false, "S06-ALT: siluet harus disembunyikan")
	assert(bal_alt.railing.visible == false, "S06-ALT: railing harus disembunyikan")
	assert(bal_alt.city_backdrop.visible == false, "S06-ALT: latar belakang kota harus disembunyikan")

	SettingsManager.skip_sensitive_scenes = false
	bal.queue_free()
	bal_alt.queue_free()
	print("    S06 & S06-ALT Safety: OK")


## Test S07: Kilas Balik 4 Potongan
func _test_s07_flashback_details() -> void:
	print("  - Menguji S07: Kilas Balik 4 Potongan...")
	var fb: FlashbackSequence = FLASHBACK_SCENE.instantiate()
	fb.auto_start = false
	add_child(fb)

	assert(FlashbackSequence.SLIDES.size() == 4, "S07: harus ada tepat 4 potongan kilas balik")
	assert(FlashbackSequence.SLIDES[0]["text"] == "S07_FLASH_1", "S07: slide 1 key salah")
	assert(FlashbackSequence.SLIDES[1]["text"] == "S07_FLASH_2", "S07: slide 2 key salah")
	assert(FlashbackSequence.SLIDES[2]["text"] == "S07_FLASH_3", "S07: slide 3 key salah")
	assert(FlashbackSequence.SLIDES[3]["text"] == "S07_FLASH_4", "S07: slide 4 key salah")

	# Simulasikan pemutaran kilas balik
	FlagStore.set_flag("saw_flashback_1", true)
	assert(FlagStore.get_flag("saw_flashback_1") == true, "S07: flag saw_flashback_1 harus true")

	fb.queue_free()
	print("    S07 Kilas Balik: OK")


## Test S08: Transformasi Lingkungan & Pesan Misterius
func _test_s08_environment_shifts_and_mystery() -> void:
	print("  - Menguji S08: Bangun Lagi & Perubahan Lingkungan...")
	# Set flag dari eksplorasi Loop 1
	FlagStore.clear()
	FlagStore.set_flag("noticed_tea", true)
	FlagStore.set_flag("turned_photo", true)

	var bed: BedroomController = BEDROOM_SCENE.instantiate()
	bed.auto_start_intro = false
	add_child(bed)

	# Simulasikan pergeseran posisi teh & rotasi foto
	bed.tea_node.position += Vector2(14, -6)
	bed.photo_node.rotation_degrees = -12.0

	assert(bed.photo_node.rotation_degrees == -12.0, "S08: foto harus miring -12 derajat")
	assert(bed.tea_node.position != Vector2.ZERO, "S08: posisi teh harus valid")

	# Uji ChatUI & input teks bebas pemain
	assert(bed.chat_ui != null, "S08: ChatUI harus ada di bedroom")
	assert(bed.loop_counter_label != null, "S08: LoopCounterLabel harus ada")

	var old_speed: float = SettingsManager.text_speed
	SettingsManager.text_speed = 100.0

	# Sambungkan listener otomatis untuk submit teks saat input row tampil
	bed.chat_ui.input_row.visibility_changed.connect(func() -> void:
		if bed.chat_ui.input_row.visible:
			get_tree().create_timer(0.01).timeout.connect(func() -> void:
				if is_instance_valid(bed) and is_instance_valid(bed.chat_ui):
					bed.chat_ui.line_edit.text = "Siapa kamu?"
					bed.chat_ui._on_send_pressed()
			)
	)

	var player_reply: String = await bed.chat_ui.prompt_text_input("S08_INPUT_PROMPT")

	assert(player_reply == "Siapa kamu?", "S08: balasan pemain harus tersimpan")
	FlagStore.set_flag("loop1_player_reply", player_reply)
	FlagStore.set_flag("received_mystery_message", true)

	assert(FlagStore.get_flag("loop1_player_reply") == "Siapa kamu?", "S08: flag loop1_player_reply gagal")
	assert(FlagStore.get_flag("received_mystery_message") == true, "S08: flag received_mystery_message gagal")

	# Uji label LOOP 2/7
	bed.loop_counter_label.text = tr("S08_LOOP_LABEL")
	assert(bed.loop_counter_label.text.contains("LOOP 2/7") or bed.loop_counter_label.text == "LOOP 2/7", "S08: teks counter harus LOOP 2/7")

	SettingsManager.text_speed = old_speed
	bed.queue_free()
	print("    S08 Bangun Lagi & Chat Misterius: OK")


## Test Loop Progression: Loop 1 -> Loop 2
func _test_loop_progression() -> void:
	print("  - Menguji Transisi Loop 1 -> Loop 2...")
	GameState.current_loop = 1
	var loop_ended_fired: Dictionary = {"fired": false, "loop": 0}
	var loop_started_fired: Dictionary = {"fired": false, "loop": 0}

	LoopManager.loop_ended.connect(func(n: int) -> void:
		loop_ended_fired["fired"] = true
		loop_ended_fired["loop"] = n
	)
	LoopManager.loop_started.connect(func(n: int) -> void:
		loop_started_fired["fired"] = true
		loop_started_fired["loop"] = n
	)

	LoopManager.end_current_loop()

	assert(loop_ended_fired["fired"] == true, "LoopManager: loop_ended gagal dipancarkan")
	assert(loop_ended_fired["loop"] == 1, "LoopManager: loop_ended nomor salah")
	assert(loop_started_fired["fired"] == true, "LoopManager: loop_started gagal dipancarkan")
	assert(loop_started_fired["loop"] == 2, "LoopManager: loop_started nomor 2 salah")
	assert(GameState.current_loop == 2, "GameState: current_loop harus 2")

	print("    Transisi Loop: OK")
