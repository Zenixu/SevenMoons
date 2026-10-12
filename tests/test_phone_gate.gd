## Test regresi GATE ponsel (permintaan pemilik):
## "jika belum membuka HP, maka tidak diperbolehkan keluar kamar dahulu."
##
## Memverifikasi:
##   1. Sebelum `checked_phone`: pintu (O6) & trigger balkon DITAHAN —
##      scene TIDAK berpindah (current_scene tetap kamar uji), flag keluar
##      (visited_corridor) tetap false, dan teks penahan terlokalisasi tampil.
##   2. Naskah O6 tetap dimainkan utuh (tried_door di-set, alur konfirmasi jalan).
##   3. Setelah `checked_phone = true`: kedua jalur keluar berfungsi seperti biasa.
##   4. Kunci lokalisasi `S02_EXIT_NEED_PHONE` ada di id.csv (bukan literal).
extends Node

const BEDROOM_SCENE = preload("res://scenes/bedroom/bedroom.tscn")
const EXIT_KEY := "S02_EXIT_NEED_PHONE"


func _ready() -> void:
	print("=== TEST: GATE PONSEL SEBELUM KELUAR KAMAR ===")
	TranslationServer.set_locale("id")
	FlagStore.clear()
	GameState.current_loop = 1

	var old_speed: float = SettingsManager.text_speed
	var old_scale: float = Engine.time_scale
	SettingsManager.text_speed = 100.0
	Engine.time_scale = 6.0

	await _test_key_exists()
	await _test_door_blocked_before_phone()
	await _test_door_allowed_after_phone()
	await _test_balcony_blocked_before_phone()
	await _test_balcony_allowed_after_phone()

	SettingsManager.text_speed = old_speed
	Engine.time_scale = old_scale
	print("=== SEMUA TEST GATE PONSEL LULUS ===")
	get_tree().quit(0)


## Kunci teks penahan harus terdaftar di lokalisasi (bukan string literal).
func _test_key_exists() -> void:
	print("  - Kunci lokalisasi S02_EXIT_NEED_PHONE...")
	assert(tr(EXIT_KEY) != EXIT_KEY, "GATE: kunci '%s' tak ada di id.csv" % EXIT_KEY)
	assert(not tr(EXIT_KEY).is_empty(), "GATE: teks penahan kosong")
	print("    Kunci lokalisasi: OK")


## Helper: buat controller kamar untuk uji; `navigate` mengatur izin pindah scene.
func _make_bed(navigate: bool) -> BedroomController:
	var bed: BedroomController = BEDROOM_SCENE.instantiate()
	bed.auto_start_intro = false
	bed.navigate_scenes = navigate
	add_child(bed)
	return bed


## Auto-jawab ChoiceMenu yang muncul dengan pilihan pertama (index 0).
func _auto_answer_first(bed: BedroomController) -> void:
	bed.choice_menu.visibility_changed.connect(func() -> void:
		if bed.choice_menu.visible:
			get_tree().create_timer(0.02).timeout.connect(func() -> void:
				if is_instance_valid(bed) and is_instance_valid(bed.choice_menu) and bed.choice_menu.visible:
					bed.choice_menu._on_button_pressed(0)
			)
	)


## Rekam teks yang benar-benar tampil di ThoughtBox (label-nya dibersihkan di akhir).
func _snapshot_thought(bed: BedroomController) -> Dictionary:
	var snap: Dictionary = {"text": ""}
	bed.thought_box.text_completed.connect(func() -> void:
		snap["text"] = bed.thought_box.label.text
	)
	return snap


## Sebelum periksa ponsel: pintu O6 dimainkan utuh tetapi keluar DITAHAN.
## navigate_scenes=true: bila gate gagal, change_scene_to_file akan memindahkan
## scene dan meruntuhkan uji ini — jadi lolosnya membuktikan scene TIDAK berubah.
func _test_door_blocked_before_phone() -> void:
	print("  - Pintu O6 tanpa ponsel: harus tertahan...")
	assert(FlagStore.get_flag("checked_phone", false) == false, "GATE: checked_phone harus false di awal")
	var bed: BedroomController = _make_bed(true)
	await get_tree().process_frame
	var snap: Dictionary = _snapshot_thought(bed)
	_auto_answer_first(bed)

	await bed._handle_door()

	# Scene tetap kamar uji (gate mencegah perpindahan scene).
	assert(get_tree().current_scene == self, "GATE: scene harus tetap kamar saat checked_phone=false")
	assert(is_instance_valid(bed) and bed.is_inside_tree(), "GATE: kamar harus tetap hidup (tak pindah scene)")
	# Naskah O6 tetap dimainkan: pemain memilih buka -> tried_door terpasang.
	assert(FlagStore.get_flag("tried_door") == true, "GATE: alur naskah O6 (tried_door) harus tetap jalan")
	# Keluar DITAHAN: flag keluar tidak boleh terpasang.
	assert(FlagStore.get_flag("visited_corridor", false) == false, "GATE: visited_corridor tidak boleh terpasang saat tertahan")
	# Teks penahan terlokalisasi tampil.
	assert(snap["text"] == tr(EXIT_KEY), "GATE: teks penahan harus tampil (dapat '%s')" % snap["text"])

	bed.queue_free()
	print("    Pintu tertahan tanpa ponsel: OK")


## Setelah periksa ponsel: pintu berfungsi seperti biasa (flag keluar terpasang).
func _test_door_allowed_after_phone() -> void:
	print("  - Pintu O6 setelah ponsel: harus berfungsi...")
	FlagStore.set_flag("checked_phone", true)
	var bed: BedroomController = _make_bed(false)   # navigate=false: uji flag, bukan pindah scene
	await get_tree().process_frame
	_auto_answer_first(bed)

	await bed._handle_door()

	assert(FlagStore.get_flag("visited_corridor") == true, "GATE: setelah ponsel, keluar lewat pintu harus berfungsi")
	bed.queue_free()
	print("    Pintu berfungsi setelah ponsel: OK")


## Sebelum periksa ponsel: trigger balkon DITAHAN (S03 tidak berjalan, tetap di kamar).
func _test_balcony_blocked_before_phone() -> void:
	print("  - Balkon tanpa ponsel: harus tertahan...")
	FlagStore.clear()
	var bed: BedroomController = _make_bed(true)
	await get_tree().process_frame
	# Paksa balkon terbuka (>=3 objek + jam) agar trigger aktif.
	bed._inspected_objects = {"tea": true, "mirror": true, "clock": true}
	FlagStore.set_flag("noticed_clock", true)
	bed._check_balcony_condition()
	assert(bed._balcony_unlocked == true, "GATE: balkon harus terbuka (prasyarat uji)")
	var snap: Dictionary = _snapshot_thought(bed)

	await bed._on_balcony_trigger_entered(bed.player)

	assert(get_tree().current_scene == self, "GATE: scene harus tetap kamar saat balkon dicoba tanpa ponsel")
	assert(FlagStore.get_flag("heard_phone_buzz", false) == false, "GATE: S03 tidak boleh berjalan sebelum ponsel diperiksa")
	assert(snap["text"] == tr(EXIT_KEY), "GATE: teks penahan balkon harus tampil (dapat '%s')" % snap["text"])
	# Pemain tetap bisa bergerak & penanda tak macet untuk percobaan ulang.
	assert(bed.player.can_move == true, "GATE: gerak pemain harus dipulihkan setelah penahan balkon")
	assert(bed._exit_block_active == false, "GATE: penanda penahan harus reset")

	bed.queue_free()
	print("    Balkon tertahan tanpa ponsel: OK")


## Setelah periksa ponsel: balkon berfungsi (S03 berjalan) seperti biasa.
func _test_balcony_allowed_after_phone() -> void:
	print("  - Balkon setelah ponsel: harus berfungsi...")
	FlagStore.clear()
	FlagStore.set_flag("checked_phone", true)
	var bed: BedroomController = _make_bed(false)
	await get_tree().process_frame
	bed._inspected_objects = {"tea": true, "mirror": true, "clock": true}
	FlagStore.set_flag("noticed_clock", true)
	bed._check_balcony_condition()
	_auto_answer_first(bed)

	await bed._on_balcony_trigger_entered(bed.player)

	assert(FlagStore.get_flag("heard_phone_buzz") == true, "GATE: setelah ponsel, balkon harus memulai S03")
	assert(bed._exit_block_active == false, "GATE: penanda penahan tetap reset pada jalur normal")
	bed.queue_free()
	print("    Balkon berfungsi setelah ponsel: OK")
