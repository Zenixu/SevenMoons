## Test alur NAVIGASI SCENE (bukan sekadar memanggil method) — kartu t_033e8f70.
##
## Permintaan pemilik: "ketika selesai membaca chat kenapa langsung cutscene ke
## akhir, tidak berjalan ke lorong dan melewati liftnya?"
##
## Driver ini hidup sebagai anak `root` (bukan current_scene) sehingga SELAMAT
## melewati `get_tree().change_scene_to_file()`. Ia berperan sebagai pemain:
##   - menyentuh Interactable lewat sinyal asli `interact()`
##   - menekan tombol pilihan lewat sinyal `pressed` tombol asli
## lalu mencatat RANTAI SCENE yang benar-benar dilewati.
##
## Yang diverifikasi:
##   1. Keluar dari kamar (setelah ponsel) -> LORONG, BUKAN langsung balkon.
##   2. Lorong -> LIFT (masuk lift, pilih lantai) -> baru BALCONY (rooftop).
##   3. Tidak ada perpindahan scene langsung kamar -> balcony.
##   4. Monolog S03 tetap diputar, TEPAT SEKALI (tidak dilewati/berulang).
##   5. Urutan adegan tetap utuh (S04a..S06 dijalankan balcony_controller).
extends Node

const BEDROOM := "res://scenes/bedroom/bedroom.tscn"
const CORRIDOR := "res://scenes/corridor/corridor.tscn"
const LIFT := "res://scenes/lift/lift.tscn"
const BALCONY := "res://scenes/balcony/balcony.tscn"

const MAX_SCENE_VISITS := 12
const BUDGET_MS := 90000

var _visited: Array[String] = []
var _last_path: String = ""
var _did: Dictionary = {}
var _choice_seq: int = 0
var _s03_max: int = 0
var _start_ms: int = 0
var _finished: bool = false


func _ready() -> void:
	print("=== TEST: RUTE KAMAR -> LORONG -> LIFT -> ROOFTOP ===")
	TranslationServer.set_locale("id")
	FlagStore.clear()
	GameState.current_loop = 1
	SettingsManager.text_speed = 100.0
	Engine.time_scale = 6.0
	_start_ms = Time.get_ticks_msec()

	# Boot kamar sebagai current_scene (driver tetap anak root).
	var inst: Node = (load(BEDROOM) as PackedScene).instantiate()
	inst.auto_start_intro = false        # lewati intro S01; fokus pada navigasi
	get_tree().root.add_child.call_deferred(inst)
	await get_tree().process_frame
	get_tree().current_scene = inst

	set_process(true)


func _process(_delta: float) -> void:
	if _finished:
		return
	var cs: Node = get_tree().current_scene
	if cs == null:
		return
	var path: String = cs.scene_file_path
	if path != _last_path:
		_last_path = path
		_visited.append(path)
		print("SCENE[%d] %s" % [_visited.size(), path.get_file()])
		if _visited.size() > MAX_SCENE_VISITS:
			_fail("terlalu banyak perpindahan scene")

	# Rekam jumlah S03 yang benar-benar diputar (sebelum kamar dibebaskan).
	if path == BEDROOM and is_instance_valid(cs) and "s03_play_count" in cs:
		_s03_max = maxi(_s03_max, int(cs.get("s03_play_count")))

	if Time.get_ticks_msec() - _start_ms > BUDGET_MS:
		_fail("timeout: chain=%s" % str(_visited))
		return

	_auto_answer_choices(cs)
	_drive(cs, path)
	_check_done()


## Jawab ChoiceMenu yang muncul (sinyal `pressed` tombol asli), indeks per-scene.
func _auto_answer_choices(cs: Node) -> void:
	var cm: ChoiceMenu = _find_choice_menu(cs)
	if cm == null or not cm.visible:
		return
	var bc: Node = cm.get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsScroll/ButtonContainer")
	if bc == null:
		return
	var n: int = bc.get_child_count()
	if n == 0:
		return
	var key: String = "%s|seq=%d|n=%d" % [_last_path, _choice_seq, n]
	if _did.has(key):
		return
	_choice_seq += 1
	var idx: int = _choice_index_for(_last_path)
	if idx >= n:
		idx = n - 1
	var btn: Node = bc.get_child(idx)
	_did[key] = true
	print("  choice: scene=%s seq=%d n=%d -> idx=%d (text=%s)" % [_last_path.get_file(), _choice_seq, n, idx, _btn_text(btn)])
	btn.emit_signal("pressed")


func _btn_text(btn: Node) -> String:
	if btn is Button:
		return (btn as Button).text
	return "?"


func _choice_index_for(path: String) -> int:
	match path:
		LIFT:
			return 2   # Lantai 5 — Atap
		_:
			return 0   # pilihan pertama (termasuk [Lompat] di balcony)


func _drive(cs: Node, path: String) -> void:
	match path:
		BEDROOM:
			_drive_bedroom(cs)
		CORRIDOR:
			_drive_corridor(cs)
		_:
			pass  # LIFT & BALCONY dijawab otomatis oleh _auto_answer_choices


func _drive_bedroom(cs: Node) -> void:
	if not _player_free(cs):
		return
	# 1) Periksa ponsel (syarat gate) — lewat sinyal asli Interactable.
	if not _did.has("bed_phone"):
		_did["bed_phone"] = true
		var phone: Node = _interactable(cs, "phone")
		if phone:
			print("  BEDROOM: touch phone")
			phone.call("interact")
		return
	# 2) Buka pintu O6 (setelah ponsel) — harus menuju LORONG.
	if FlagStore.get_flag("checked_phone", false) and not _did.has("bed_door"):
		if not _is_busy(cs):
			_did["bed_door"] = true
			var door: Node = _interactable(cs, "door")
			if door:
				print("  BEDROOM: touch door")
				door.call("interact")


func _drive_corridor(cs: Node) -> void:
	if not _player_free(cs):
		return
	if _did.has("corr_elev"):
		return
	_did["corr_elev"] = true
	var elev: Node = _interactable(cs, "elevator")
	if elev:
		print("  CORRIDOR: touch elevator")
		elev.call("interact")


## Selesai ketika rooftop benar-benar tercapai lewat lorong + lift.
func _check_done() -> void:
	if _visited.is_empty() or _visited.back() != BALCONY:
		return
	_verify_and_finish()


func _verify_and_finish() -> void:
	# Rantai scene yang diharapkan (keluar kamar lewat lorong & lift).
	var chain_names: Array[String] = []
	for p in _visited:
		chain_names.append(String(p).get_file())

	# 1. Kamar -> balcony TIDAK boleh langsung.
	for i in range(_visited.size() - 1):
		assert(not (_visited[i] == BEDROOM and _visited[i + 1] == BALCONY),
			"RUTE: kamar TIDAK boleh langsung ke balcony.tscn (chain=%s)" % str(chain_names))

	# 2. Lorong & lift harus dilewati, dan urutannya benar.
	var i_corr: int = _visited.find(CORRIDOR)
	var i_lift: int = _visited.find(LIFT)
	var i_bal: int = _visited.find(BALCONY)
	assert(i_corr != -1, "RUTE: corridor.tscn tidak dilewati (chain=%s)" % str(chain_names))
	assert(i_lift != -1, "RUTE: lift.tscn tidak dilewati (chain=%s)" % str(chain_names))
	assert(i_corr < i_lift and i_lift < i_bal,
		"RUTE: urutan harus kamar->corridor->lift->balcony (chain=%s)" % str(chain_names))

	# 3. S03 tetap diputar tepat sekali (tidak dilewati, tidak berulang).
	assert(_s03_max == 1, "S03: monolog harus diputar tepat sekali (dapat %d)" % _s03_max)
	assert(FlagStore.get_flag("heard_phone_buzz", false) == true,
		"S03: flag heard_phone_buzz harus terpasang (S03 benar-benar berjalan)")

	# 4. Flag kedatangan rooftop diset benar oleh lift_controller.
	assert(int(FlagStore.get_flag("corridor_floor", 0)) == 5,
		"LIFT: corridor_floor harus 5 setelah memilih atap")
	assert(FlagStore.get_flag("rooftop_arrived", false) == true,
		"ROOFTOP: jalur kedatangan dari lift (rooftop_from_lift) harus dijalankan balcony_controller")
	assert(FlagStore.get_flag("visited_corridor", false) == true,
		"RUTE: visited_corridor harus terpasang saat keluar kamar")

	_finished = true
	set_process(false)
	Engine.time_scale = 1.0
	SettingsManager.text_speed = 1.0
	print("RUTE OK: chain=%s" % str(chain_names))
	print("=== SEMUA TEST RUTE KAMAR->ROOFTOP LULUS ===")
	get_tree().quit(0)


func _fail(reason: String) -> void:
	if _finished:
		return
	_finished = true
	set_process(false)
	Engine.time_scale = 1.0
	SettingsManager.text_speed = 1.0
	push_error("RUTE GAGAL: %s" % reason)
	print("=== TEST RUTE GAGAL: %s ===" % reason)
	get_tree().quit(1)


func _player_free(cs: Node) -> bool:
	if _is_busy(cs):
		return false
	var p: Node = cs.get_node_or_null("Player")
	if p == null:
		return true
	return bool(p.get("can_move"))


func _is_busy(cs: Node) -> bool:
	var cm: ChoiceMenu = _find_choice_menu(cs)
	if cm and cm.visible:
		return true
	var tb: Node = _find_thought_box(cs)
	if tb and bool(tb.get("_is_typing")):
		return true
	return false


func _interactable(cs: Node, obj_id: String) -> Node:
	var parent: Node = cs.get_node_or_null("Interactables")
	if parent == null:
		return null
	for ch in parent.get_children():
		if ch.get("object_id") == obj_id:
			return ch
	return null


func _find_choice_menu(root: Node) -> ChoiceMenu:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is ChoiceMenu:
			return n
		for c in n.get_children():
			stack.append(c)
	return null


func _find_thought_box(root: Node) -> ThoughtBox:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is ThoughtBox:
			return n
		for c in n.get_children():
			stack.append(c)
	return null
