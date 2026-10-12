## Test regresi: monolog S03 diputar TEPAT SEKALI per sesi/permainan — kartu t_e95f2abf.
##
## Bug lama: penjaga S03 (`_s03_played`) hanya variabel instance, jadi reset
## setiap kali controller kamar dibuat ulang. Akibatnya pemain bisa keluar kamar,
## kembali lewat pintu kamar (lorong lantai 3), lalu keluar lagi dan S03 terulang.
##
## Memverifikasi:
##   1. S03 benar-benar berjalan pada kunjungan kamar pertama (lewat pintu O6).
##   2. Penjaga dipersistensikan di FlagStore (`s03_played`).
##   3. Setelah kembali ke kamar (simulasi `corridor_floor=3` + `room_door`) dan
##      keluar lagi, S03 TIDAK diputar ulang (`s03_play_count` kunjungan ke-2 = 0,
##      `heard_phone_buzz` tidak berubah).
##   4. Sama untuk jalur keluar jendela/balkon: sekali lewat balkon, lalu kembali
##      dari lorong dan keluar lewat pintu → S03 tetap tidak berulang.
##
## Catatan: memakai `_check()` (bukan `assert()` mentah) supaya kegagalan benar-
## benar menggagalkan suite (exit code != 0), bukan sekadar mencetak SCRIPT ERROR.
extends Node

const BEDROOM_SCENE = preload("res://scenes/bedroom/bedroom.tscn")
const CORRIDOR_SCENE = preload("res://scenes/corridor/corridor.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	print("=== TEST: S03 DIPUTAR TEPAT SEKALI (TIDAK BERULANG SAAT KEMBALI KE KAMAR) ===")
	TranslationServer.set_locale("id")
	FlagStore.clear()
	GameState.current_loop = 1

	var old_speed: float = SettingsManager.text_speed
	var old_scale: float = Engine.time_scale
	SettingsManager.text_speed = 100.0
	Engine.time_scale = 6.0

	await _test_once_via_door_then_reentry()
	await _test_once_via_balcony_then_reentry()

	SettingsManager.text_speed = old_speed
	Engine.time_scale = old_scale

	if _failures.is_empty():
		print("=== SEMUA TEST S03 SEKALI LULUS ===")
		get_tree().quit(0)
	else:
		for msg in _failures:
			push_error("S03 SEKALI GAGAL: %s" % msg)
			print("S03 SEKALI GAGAL: %s" % msg)
		print("=== TEST S03 SEKALI GAGAL: %d kegagalan ===" % _failures.size())
		get_tree().quit(1)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failures.append(msg)


## Helper: buat controller kamar uji (navigate=false agar tak memindah scene uji).
func _make_bed() -> BedroomController:
	var bed: BedroomController = BEDROOM_SCENE.instantiate()
	bed.auto_start_intro = false
	bed.navigate_scenes = false
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


## Simulasi pemain kembali ke kamar dari lorong: lantai 3 + sentuh pintu kamar.
## Corridor uji navigate=false (tidak benar-benar memindah scene).
func _return_to_room_via_corridor() -> void:
	FlagStore.set_flag("corridor_floor", 3)
	var corr: CorridorController = CORRIDOR_SCENE.instantiate()
	corr.auto_start = false
	corr.navigate_scenes = false
	add_child(corr)
	await get_tree().process_frame
	await corr._handle_room_door()
	corr.queue_free()
	await get_tree().process_frame


## Kasus 1: keluar kamar lewat pintu O6 → kembali dari lorong → keluar lagi.
func _test_once_via_door_then_reentry() -> void:
	print("  - Jalur pintu O6: S03 sekali, lalu kembali dari lorong & keluar lagi...")
	FlagStore.clear()
	FlagStore.set_flag("checked_phone", true)

	# Kunjungan kamar #1 — S03 harus berjalan.
	var bed1: BedroomController = _make_bed()
	await get_tree().process_frame
	_auto_answer_first(bed1)
	await bed1._handle_door()

	_check(bed1.s03_play_count == 1, "harus diputar sekali pada kunjungan #1 (dapat %d)" % bed1.s03_play_count)
	_check(FlagStore.get_flag("heard_phone_buzz", false) == true, "heard_phone_buzz harus terpasang setelah S03 berjalan")
	_check(FlagStore.get_flag(BedroomController.S03_PLAYED_FLAG, false) == true,
		"penjaga harus dipersistensikan di FlagStore ('%s')" % BedroomController.S03_PLAYED_FLAG)
	bed1.queue_free()
	await get_tree().process_frame

	# Kembali ke kamar dari lorong (lantai 3 + pintu kamar).
	await _return_to_room_via_corridor()

	# Kunjungan kamar #2 — instance BARU; S03 tidak boleh berjalan lagi.
	var bed2: BedroomController = _make_bed()
	await get_tree().process_frame
	_check(bed2._s03_played == true, "penjaga harus tersinkron dari FlagStore pada instance kamar baru")
	var buzz_before: bool = bool(FlagStore.get_flag("heard_phone_buzz", false))
	_auto_answer_first(bed2)
	await bed2._handle_door()

	_check(bed2.s03_play_count == 0, "TIDAK boleh diputar ulang saat keluar lagi (dapat %d)" % bed2.s03_play_count)
	_check(bool(FlagStore.get_flag("heard_phone_buzz", false)) == buzz_before,
		"heard_phone_buzz tidak boleh berubah pada kunjungan ke-2")
	# Keluar kamar tetap berfungsi (bukan terblokir).
	_check(FlagStore.get_flag("visited_corridor", false) == true,
		"keluar kamar ke-2 tetap harus berfungsi (visited_corridor terpasang)")
	bed2.queue_free()
	await get_tree().process_frame
	print("    Jalur pintu O6: selesai (kegagalan sejauh ini: %d)" % _failures.size())


## Kasus 2: keluar kamar lewat jendela/balkon → kembali dari lorong → keluar pintu.
func _test_once_via_balcony_then_reentry() -> void:
	print("  - Jalur jendela/balkon: S03 sekali, lalu kembali dari lorong & keluar pintu...")
	FlagStore.clear()
	FlagStore.set_flag("checked_phone", true)

	# Kunjungan kamar #1 — buka balkon lalu sentuh trigger → S03 berjalan sekali.
	var bed1: BedroomController = _make_bed()
	await get_tree().process_frame
	bed1._inspected_objects = {"tea": true, "mirror": true, "clock": true}
	FlagStore.set_flag("noticed_clock", true)
	bed1._check_balcony_condition()
	_check(bed1._balcony_unlocked == true, "balkon harus terbuka (prasyarat uji)")
	_auto_answer_first(bed1)
	await bed1._on_balcony_trigger_entered(bed1.player)

	_check(bed1.s03_play_count == 1, "harus diputar sekali lewat balkon (dapat %d)" % bed1.s03_play_count)
	_check(FlagStore.get_flag(BedroomController.S03_PLAYED_FLAG, false) == true, "penjaga harus dipersistensikan")
	bed1.queue_free()
	await get_tree().process_frame

	# Kembali ke kamar dari lorong, lalu keluar lewat pintu O6.
	await _return_to_room_via_corridor()

	var bed2: BedroomController = _make_bed()
	await get_tree().process_frame
	_check(bed2._s03_played == true, "penjaga harus tersinkron pada instance kamar baru")
	_auto_answer_first(bed2)
	await bed2._handle_door()

	_check(bed2.s03_play_count == 0, "TIDAK boleh diputar ulang lewat pintu setelah balkon (dapat %d)" % bed2.s03_play_count)
	_check(FlagStore.get_flag("visited_corridor", false) == true, "keluar kamar tetap harus berfungsi")
	bed2.queue_free()
	await get_tree().process_frame
	print("    Jalur jendela/balkon: selesai (kegagalan sejauh ini: %d)" % _failures.size())
