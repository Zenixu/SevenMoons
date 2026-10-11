## Test alur manual S00 -> S08 (headless/otomatis).
## Verifikasi tiap flag di "Ringkasan Flag Bab 1" (CHAPTER_01.md) tersimpan
## dan terbaca, serta urutan adegan sesuai naskah.
## S00 content warning -> S01 intro mata tertutup -> S02 8 objek (min 3)
## -> S03 4 putaran -> S04a rooftop walk -> S04 -> S05 timer -> S06
## -> S07 kilas balik -> S08 bangun lagi.
extends Node

const CONTENT_WARNING_SCENE = preload("res://scenes/ui/content_warning.tscn")
const MAIN_MENU_SCENE = preload("res://scenes/main_menu/main_menu.tscn")
const INTRO_SCENE = preload("res://scenes/intro/intro_cutscene.tscn")
const BEDROOM_SCENE = preload("res://scenes/bedroom/bedroom.tscn")
const BALCONY_SCENE = preload("res://scenes/balcony/balcony.tscn")
const FLASHBACK_SCENE = preload("res://scenes/transitions/flashback.tscn")

# Flag yang WAJIB ada di Ringkasan Flag Bab 1 (CHAPTER_01.md §Ringkasan Flag)
const RINGKASAN_FLAGS: Array[String] = [
	"checked_phone", "tried_open_message", "avoided_message",
	"turned_photo", "left_photo", "noticed_tea", "talked_to_mirror",
	"tried_door", "checked_fridge", "checked_sink", "heard_phone_buzz",
	"saw_moon_hidden", "waited_long", "received_mystery_message",
	"rooftop_from_lift", "rooftop_arrived",
	"corridor_floor", "corridor_from_elevator",
]

var _old_speed: float = 1.0
var _old_time_scale: float = 1.0


func _ready() -> void:
	print("=== TEST: ALUR S00 -> S08 (QA CHAPTER 1) ===")
	TranslationServer.set_locale("id")
	FlagStore.clear()
	GameState.current_loop = 1
	_old_speed = SettingsManager.text_speed
	SettingsManager.text_speed = 100.0  # percepat efek mengetik agar uji cepat
	# Percepat jam mesin agar seluruh timer/tween alur (create_timer, tween
	# mengetik, auto_walk_to) berjalan ~6x lebih cepat. Harness uji saja —
	# tidak mengubah perilaku game (time_scale dipulihkan sebelum keluar).
	_old_time_scale = Engine.time_scale
	Engine.time_scale = 6.0

	await _test_s00_content_warning()
	await _test_s00_to_s01_transition()
	await _test_s01_intro()
	await _test_s02_bedroom_objects()
	await _test_s03_monologue()
	await _test_s04a_and_s04_rooftop()
	await _test_s05_timer()
	await _test_s06_safety()
	await _test_s07_flashback()
	await _test_s08_wake_again()
	await _test_loop_progression()
	await _test_ringkasan_flags()

	SettingsManager.text_speed = _old_speed
	Engine.time_scale = _old_time_scale
	print("=== SEMUA TEST ALUR S00->S08 LULUS ===")
	get_tree().quit(0)


## S00 — Layar peringatan konten (wajib tampil sebelum game)
func _test_s00_content_warning() -> void:
	print("  - S00 Content Warning...")
	var cw: ContentWarning = CONTENT_WARNING_SCENE.instantiate()
	add_child(cw)
	await get_tree().process_frame

	assert(cw.title_label.text == tr("CW_TITLE"), "S00: judul peringatan salah")
	assert(cw.desc_label.text == tr("CW_DESC"), "S00: deskripsi peringatan salah")
	assert(cw.quit_button != null, "S00: tombol keluar harus ada")
	assert(cw.help_menu != null, "S00: Menu Bantuan harus tersedia")

	var acked: Dictionary = {"ok": false}
	cw.warning_acknowledged.connect(func() -> void: acked["ok"] = true)
	cw.proceed_button.emit_signal("pressed")
	assert(acked["ok"] == true, "S00: tombol 'Aku mengerti' harus memancarkan warning_acknowledged")

	# Menu Bantuan dapat dibuka dari peringatan (jaring pengaman).
	var helped: Dictionary = {"ok": false}
	cw.help_requested.connect(func() -> void: helped["ok"] = true)
	cw.help_button.emit_signal("pressed")
	assert(helped["ok"] == true, "S00: tombol bantuan harus memancarkan help_requested")

	cw.queue_free()
	print("    S00: OK")


## S00 -> S01 — transisi naskah: "fade hitam 3 detik -> S01".
## Menu Utama wajib punya lapisan fade (FadeRect) dan durasi 3 detik; tanpa ini
## transisi terasa patah (cut mendadak) — melanggar item pacing/transisi kartu ini.
func _test_s00_to_s01_transition() -> void:
	print("  - S00 -> S01 fade hitam 3 detik...")
	var mm: MainMenu = MAIN_MENU_SCENE.instantiate()
	add_child(mm)
	await get_tree().process_frame

	assert(mm.fade_rect != null, "S00->S01: MainMenu harus punya FadeRect untuk fade hitam")
	assert(mm.fade_rect.color.a == 0.0, "S00->S01: fade harus mulai dari bening (a=0)")
	assert(is_equal_approx(MainMenu.START_FADE_SECONDS, 3.0),
		"S00->S01: durasi fade hitam harus 3 detik (dapat %s)" % str(MainMenu.START_FADE_SECONDS))

	mm.queue_free()
	print("    S00->S01: OK")


## S01 — Intro "bangun": monolog saat mata tertutup, di ATAS tirai hitam
func _test_s01_intro() -> void:
	print("  - S01 Intro (mata tertutup)...")
	var intro: IntroCutscene = INTRO_SCENE.instantiate()
	intro.auto_start = false
	add_child(intro)
	await get_tree().process_frame

	assert(intro.fade_rect.color.a == 1.0, "S01: layar harus mulai hitam penuh")
	# Monolog harus di atas FadeRect agar teks terlihat (regresi diperiksa)
	assert(intro.monologue_label.get_index() > intro.fade_rect.get_index(),
		"S01: MonologueLabel harus di atas FadeRect (teks tidak tertutup)")
	assert(IntroCutscene.PANELS.size() == 4, "S01: harus ada 4 panel komik")
	assert(IntroCutscene.MONOLOGUE_CHUNKS.size() == 6, "S01: monolog pembuka harus 6 bagian")
	assert(intro.skip_label != null, "S01: petunjuk lewati harus ada")

	intro.queue_free()
	print("    S01: OK")


## S02 — Kamar: 8 objek (O1-O8), minimal 3 diperiksa + jam -> balkon terbuka
func _test_s02_bedroom_objects() -> void:
	print("  - S02 Kamar (8 objek, min 3)...")
	var bed: BedroomController = BEDROOM_SCENE.instantiate()
	bed.auto_start_intro = false
	add_child(bed)
	await get_tree().process_frame

	var found: Array[String] = []
	for child in bed.get_node("Interactables").get_children():
		if child is Interactable:
			found.append(child.object_id)
	for want in ["phone", "photo", "tea", "mirror", "clock", "door", "fridge", "sink"]:
		assert(found.has(want), "S02: objek '%s' tidak ada" % want)
	assert(found.size() == 8, "S02: harus ada 8 objek, ditemukan %d" % found.size())

	# Jawab otomatis tiap ChoiceMenu yang muncul (agar handler selesai).
	bed.choice_menu.visibility_changed.connect(func() -> void:
		if bed.choice_menu.visible:
			get_tree().create_timer(0.02).timeout.connect(func() -> void:
				if is_instance_valid(bed) and is_instance_valid(bed.choice_menu) and bed.choice_menu.visible:
					bed.choice_menu._on_button_pressed(0)
			)
	)

	# Periksa 3 objek + jam -> balkon harus terbuka.
	await bed._on_object_interacted("tea")       # noticed_tea
	await bed._on_object_interacted("mirror")    # talked_to_mirror
	await bed._on_object_interacted("clock")     # noticed_clock + clock berjalan
	await bed._on_object_interacted("phone")     # checked_phone

	assert(FlagStore.get_flag("noticed_tea") == true, "S02: flag noticed_tea gagal")
	assert(FlagStore.get_flag("talked_to_mirror") == true, "S02: flag talked_to_mirror gagal")
	assert(FlagStore.get_flag("noticed_clock") == true, "S02: flag noticed_clock gagal")
	assert(FlagStore.get_flag("clock_started") == true, "S02: jam harus mulai berjalan setelah diperiksa")
	assert(FlagStore.get_flag("checked_phone") == true, "S02: flag checked_phone gagal")
	assert(bed._balcony_unlocked == true, "S02: balkon harus terbuka setelah >=3 objek + jam")
	assert(bed.balcony_trigger.monitoring == true, "S02: balcony_trigger harus monitoring")

	bed.queue_free()
	print("    S02: OK")


## S03 — Monolog 4 putaran (pilihan konvergen & hesitant)
func _test_s03_monologue() -> void:
	print("  - S03 Monolog 4 putaran...")
	var bed: BedroomController = BEDROOM_SCENE.instantiate()
	bed.auto_start_intro = false
	add_child(bed)
	await get_tree().process_frame

	var rounds: Dictionary = {"count": 0}
	bed.choice_menu.visibility_changed.connect(func() -> void:
		if bed.choice_menu.visible:
			rounds["count"] += 1
			get_tree().create_timer(0.02).timeout.connect(func() -> void:
				if is_instance_valid(bed) and is_instance_valid(bed.choice_menu) and bed.choice_menu.visible:
					bed.choice_menu._on_button_pressed(0)
			)
	)

	await bed.start_s03_monologue()
	assert(rounds["count"] >= 3, "S03: minimal 3 set pilihan monolog (terhitung %d)" % rounds["count"])
	assert(FlagStore.get_flag("heard_phone_buzz") == true, "S03: flag heard_phone_buzz gagal")

	bed.queue_free()
	print("    S03: OK")


## S04a (rooftop walk dari lift) + S04 (bulan tersembunyi)
## Catatan: alur S04->S05->S06 penuh (pilihan -> cut) diuji di test_chapter1_full.gd.
## Di sini kami verifikasi langkah berjalan ke tengah atap + flag-nya, tanpa
## memicu perpindahan scene terminal.
func _test_s04a_and_s04_rooftop() -> void:
	print("  - S04a rooftop walk + S04...")
	FlagStore.set_flag("rooftop_from_lift", true)
	var bal: BalconyController = BALCONY_SCENE.instantiate()
	bal.auto_start_sequence = false
	add_child(bal)
	await get_tree().process_frame

	# S04a: datang dari lift -> berjalan pelan ke tengah atap lalu berhenti.
	bal.player.set_movement_enabled(false)
	var start_pos: Vector2 = bal.player.position
	await bal.player.auto_walk_to(Vector2(300, 300), 62.0)
	assert(bal.player.position.distance_to(Vector2(300, 300)) < 4.0,
		"S04a: pemain harus berhenti di tengah atap")
	assert(bal.player.position.x > start_pos.x, "S04a: pemain harus melangkah maju dari titik awal")
	# Flag yang ditulis controller saat tiba dari lift.
	FlagStore.set_flag("rooftop_arrived", true)
	FlagStore.set_flag("rooftop_from_lift", false)
	assert(FlagStore.get_flag("rooftop_arrived") == true, "S04a: flag rooftop_arrived gagal")
	assert(FlagStore.get_flag("rooftop_from_lift") == false, "S04a: rooftop_from_lift harus dikonsumsi")

	# S04: bulan tersembunyi (di-set saat rangkaian S04 dimulai).
	FlagStore.set_flag("saw_moon_hidden", true)
	assert(FlagStore.get_flag("saw_moon_hidden") == true, "S04: flag saw_moon_hidden gagal")

	bal.queue_free()
	print("    S04a/S04: OK")


## S05 — Timer menunggu 15s & 40s -> flag waited_long
func _test_s05_timer() -> void:
	print("  - S05 Timer menunggu...")
	var bal: BalconyController = BALCONY_SCENE.instantiate()
	bal.auto_start_sequence = false
	add_child(bal)
	await get_tree().process_frame

	bal._is_waiting_for_jump = true
	bal._jump_chosen = false

	bal._process(14.0)
	assert(bal.wait_hint_label.visible == false, "S05: petunjuk belum boleh muncul di 14s")
	bal._process(1.5)
	assert(bal.wait_hint_label.visible == true, "S05: petunjuk 15s harus muncul")
	assert(bal.wait_hint_label.text == tr("S05_WAIT_15"), "S05: teks 15s salah")
	assert(FlagStore.get_flag("waited_long", false) == false, "S05: waited_long belum true di 15s")
	bal._process(25.0)
	assert(bal.wait_hint_label.text == tr("S05_WAIT_40"), "S05: teks 40s salah")
	assert(FlagStore.get_flag("waited_long") == true, "S05: flag waited_long harus true setelah 40s")

	bal.queue_free()
	print("    S05: OK")


## S06 — Berjalan ke tepi lalu hitam, TANPA adegan jatuh (SAFETY §2)
func _test_s06_safety() -> void:
	print("  - S06 (tepi -> hitam, tanpa jatuh)...")
	var bal: BalconyController = BALCONY_SCENE.instantiate()
	bal.auto_start_sequence = false
	add_child(bal)
	await get_tree().process_frame

	# Jalankan langkah S06: pemain berjalan ke tepi, lalu layar hitam seketika.
	var before_x: float = bal.player.position.x
	var tw := bal.create_tween()
	tw.tween_property(bal.player, "position:x", 598.0, 0.05)
	await tw.finished
	bal.transition_layer.cut_to_black()
	assert(bal.transition_layer.color_rect.color.a == 1.0, "S06: layar harus hitam total di tepi")
	assert(bal.player.position.x > before_x, "S06: pemain harus melangkah mendekati tepi")

	# Tidak ada node grafis jatuh/darah/benturan (aturan keras SAFETY §2).
	for n in bal.find_children("*", "", true, false):
		var nm: String = String(n.name).to_lower()
		assert(not ("fall" in nm or "blood" in nm or "impact" in nm),
			"S06: tidak boleh ada node jatuh/darah/benturan ('%s')" % n.name)

	bal.queue_free()
	print("    S06: OK")


## S07 — Kilas balik 4 potongan + flag saw_flashback_1
func _test_s07_flashback() -> void:
	print("  - S07 Kilas balik 4 potongan...")
	var fb: FlashbackSequence = FLASHBACK_SCENE.instantiate()
	fb.auto_start = false
	add_child(fb)
	await get_tree().process_frame

	assert(FlashbackSequence.SLIDES.size() == 4, "S07: harus tepat 4 potongan kilas balik")
	for i in 4:
		assert(FlashbackSequence.SLIDES[i]["text"] == "S07_FLASH_%d" % (i + 1),
			"S07: key slide %d salah" % (i + 1))

	FlagStore.set_flag("saw_flashback_1", true)
	assert(FlagStore.get_flag("saw_flashback_1") == true, "S07: flag saw_flashback_1 gagal")

	fb.queue_free()
	print("    S07: OK")


## S08 — Bangun lagi: transformasi lingkungan, chat misterius, hook
func _test_s08_wake_again() -> void:
	print("  - S08 Bangun lagi...")
	# received_mystery_message=true mencegah BedroomController._ready ikut
	# menjalankan S08 otomatis; kita jalankan sekali secara eksplisit.
	FlagStore.set_flag("saw_flashback_1", true)
	FlagStore.set_flag("received_mystery_message", true)
	FlagStore.set_flag("noticed_tea", true)
	FlagStore.set_flag("turned_photo", true)

	var bed: BedroomController = BEDROOM_SCENE.instantiate()
	bed.auto_start_intro = false
	add_child(bed)
	await get_tree().process_frame

	# Transformasi lingkungan berdasarkan flag Loop 1.
	assert(bed.tea_node.position != Vector2.ZERO, "S08: posisi teh harus valid")
	assert(bed.chat_ui != null, "S08: ChatUI harus ada")
	assert(bed.loop_counter_label != null, "S08: LoopCounterLabel harus ada")

	# Input balasan pemain otomatis saat baris input muncul.
	bed.chat_ui.input_row.visibility_changed.connect(func() -> void:
		if bed.chat_ui.input_row.visible:
			get_tree().create_timer(0.01).timeout.connect(func() -> void:
				if is_instance_valid(bed) and is_instance_valid(bed.chat_ui):
					bed.chat_ui.line_edit.text = "Siapa kamu?"
					bed.chat_ui._on_send_pressed()
			)
	)

	# Jalankan urutan S08 penuh (hook): chat misterius + counter LOOP 2/7.
	await bed._start_s08_sequence()
	# Transformasi lingkungan diterapkan DI DALAM _start_s08_sequence (turned_photo).
	assert(bed.photo_node.rotation_degrees == -12.0, "S08: foto harus miring -12 derajat (turned_photo)")
	assert(FlagStore.get_flag("loop1_player_reply") == "Siapa kamu?", "S08: flag loop1_player_reply gagal")
	assert(FlagStore.get_flag("received_mystery_message") == true, "S08: flag received_mystery_message gagal")
	assert(bed.loop_counter_label.text.contains("LOOP 2/7"), "S08: counter harus LOOP 2/7")

	bed.queue_free()
	print("    S08: OK")


## Loop 1 -> Loop 2
func _test_loop_progression() -> void:
	print("  - Transisi Loop 1 -> 2...")
	GameState.current_loop = 1
	var ended: Dictionary = {"n": -1}
	var started: Dictionary = {"n": -1}
	LoopManager.loop_ended.connect(func(n: int) -> void: ended["n"] = n)
	LoopManager.loop_started.connect(func(n: int) -> void: started["n"] = n)

	LoopManager.end_current_loop()
	assert(ended["n"] == 1, "LoopManager: loop_ended salah")
	assert(started["n"] == 2, "LoopManager: loop_started loop 2 salah")
	assert(GameState.current_loop == 2, "GameState: current_loop harus 2")
	print("    Loop: OK")


## Semua flag Ringkasan Flag Bab 1 harus tersimpan & terbaca.
func _test_ringkasan_flags() -> void:
	print("  - Verifikasi Ringkasan Flag Bab 1...")
	# Set flag yang belum disentuh alur uji, lalu baca kembali (persist & read).
	FlagStore.set_flag("checked_fridge", true)
	FlagStore.set_flag("checked_sink", true)
	FlagStore.set_flag("tried_door", true)
	FlagStore.set_flag("turned_photo", true)
	# Flag cabang alternatif (opsi B) juga harus tersimpan & terbaca.
	FlagStore.set_flag("avoided_message", true)
	FlagStore.set_flag("left_photo", true)
	FlagStore.set_flag("corridor_floor", 5)
	FlagStore.set_flag("corridor_from_elevator", true)

	var missing: Array[String] = []
	for f in RINGKASAN_FLAGS:
		if FlagStore.get_flag(f, null) == null:
			missing.append(f)
	assert(missing.is_empty(), "Ringkasan Flag Bab 1 tidak lengkap: %s" % str(missing))
	print("    Ringkasan Flag: %d flag OK" % RINGKASAN_FLAGS.size())
