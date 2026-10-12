## _audit_flow_probe — GATE/FLOW runtime probe (read-only, bug-hunter).
##
## Menggerakkan ALUR SCENE NYATA (bukan sekadar memanggil _on_button_pressed):
## driver ini hidup sebagai anak `root` (bukan current_scene) sehingga SELAMAT
## melewati `get_tree().change_scene_to_file()`. Ia berperan sebagai "pemain":
##   - menyentuh Interactable lewat sinyal asli `interact()`
##   - menekan tombol pilihan lewat sinyal `pressed` tombol asli
## lalu mencatat RANTAI SCENE yang benar-benar dilewati.
##
## Mode argumen (dibaca dari `--` extra args / env):
##   MODE=full   : content_warning -> ... -> S08 (alur penuh S00->S08)
##   MODE=gate_off: kamar, checked_phone=false, coba pintu -> harus TETAP kamar
##   MODE=gate_on : kamar, checked_phone=true,  pintu -> harus pindah ke corridor
##
## Bukti ditulis ke `res://tests/_audit_flow_result.txt`.
extends Node

const CW := "res://scenes/ui/content_warning.tscn"
const MM := "res://scenes/main_menu/main_menu.tscn"
const INTRO := "res://scenes/intro/intro_cutscene.tscn"
const BEDROOM := "res://scenes/bedroom/bedroom.tscn"
const CORRIDOR := "res://scenes/corridor/corridor.tscn"
const LIFT := "res://scenes/lift/lift.tscn"
const BALCONY := "res://scenes/balcony/balcony.tscn"
const FLASHBACK := "res://scenes/transitions/flashback.tscn"

const RESULT_PATH := "res://tests/_audit_flow_result.txt"

var _mode: String = "full"
var _visited: Array[String] = []
var _lines: Array[String] = []
var _last_path: String = ""
var _start_ms: int = 0
var _budget_ms: int = 120000
var _did: Dictionary = {}         # aksi sekali per scene
var _finished: bool = false
var _max_scene_visits: int = 40
var _choice_seq: int = 0          # urutan pilihan yang dijawab DI SCENE INI
var _loop_bed_visits: int = 0     # berapa kali scene kamar dikunjungi (mode loop)
var _loop_corr_visits: int = 0    # berapa kali scene lorong dikunjungi (mode loop)
## mode loop: s03_play_count yang diamati pada kunjungan kamar ke-2 SETELAH pintu
## disentuh (bukti penjaga S03 persisten: tetap 0 = tidak diputar ulang).
var _bed2_s03_after: int = -1


func _ready() -> void:
	TranslationServer.set_locale("id")
	FlagStore.clear()
	GameState.current_loop = 1
	SettingsManager.text_speed = 100.0
	Engine.time_scale = 6.0

	_mode = _read_mode()
	_start_ms = Time.get_ticks_msec()
	_log("=== AUDIT FLOW PROBE (mode=%s) ===" % _mode)

	# Mulai dari scene yang sesuai mode.
	match _mode:
		"gate_off", "gate_on":
			FlagStore.set_flag("checked_phone", _mode == "gate_on")
			_boot(BEDROOM)
		"window", "window_off":
			FlagStore.set_flag("checked_phone", _mode == "window")
			_boot(BEDROOM)
		"reentry":
			FlagStore.set_flag("checked_phone", true)
			_boot(BEDROOM)
		"loop":
			FlagStore.set_flag("checked_phone", true)
			_boot(BEDROOM)
		_:
			_boot(CW)

	set_process(true)


func _read_mode() -> String:
	# Godot: extra user args after `--`
	for a in OS.get_cmdline_user_args():
		if a.begins_with("mode="):
			return a.substr(5)
	var env: String = OS.get_environment("AUDIT_MODE")
	if env != "":
		return env
	return "full"


## Instansiasi scene pertama sebagai current_scene; driver (self) tetap anak root.
func _boot(path: String) -> void:
	var inst: Node = (load(path) as PackedScene).instantiate()
	if "auto_start_intro" in inst:
		inst.set("auto_start_intro", false)
	if "auto_start" in inst:
		inst.set("auto_start", false)
	get_tree().root.add_child.call_deferred(inst)
	# current_scene di-set setelah node masuk tree.
	await get_tree().process_frame
	get_tree().current_scene = inst


func _process(_delta: float) -> void:
	if _finished:
		return
	var cs: Node = get_tree().current_scene
	if cs == null:
		return
	var path: String = cs.scene_file_path
	if path != _last_path:
		_last_path = path
		_choice_seq = 0
		_visited.append(path)
		if path == BEDROOM:
			_loop_bed_visits += 1
		elif path == CORRIDOR:
			_loop_corr_visits += 1
		_log("SCENE[%d] %s" % [_visited.size(), path.get_file()])
		if _visited.size() > _max_scene_visits:
			_finish("MAX_SCENE_VISITS")

	# Batas waktu.
	if Time.get_ticks_msec() - _start_ms > _budget_ms:
		_finish("TIMEOUT")
		return

	_auto_answer_choices(cs)
	_drive(cs, path)
	_check_done()


## Deteksi selesai per-mode (agar tidak menunggu budget penuh).
func _check_done() -> void:
	var cs: Node = get_tree().current_scene
	if _mode == "gate_off":
		# Setelah dua pilihan pintu dijawab & pemain bebas lagi, hasil sudah pasti.
		if _did.has("gate_door") and not _is_busy(cs) and _player_free(cs):
			_finish("GATE_OFF_DONE")
	elif _mode == "gate_on":
		# Keluar berhasil begitu scene berganti (chain bertambah).
		if _visited.size() >= 2:
			_finish("GATE_ON_DONE")
	elif _mode == "window":
		if _visited.size() >= 2:
			_finish("WINDOW_LEFT_BEDROOM")
	elif _mode == "window_off":
		if _did.has("win") and not _is_busy(cs):
			_finish("WINDOW_OFF_BLOCKED" if _visited.size() == 1 else "WINDOW_OFF_LEFT")
	elif _mode == "loop":
		# Catat s03_play_count pada kamar ke-2 setelah pintu disentuh (bukti tidak berulang).
		if _loop_bed_visits >= 2 and _did.has("loop_out2"):
			var b2: Node = get_tree().current_scene
			if b2 != null and b2.scene_file_path == BEDROOM:
				var cnt: int = int(b2.get("s03_play_count"))
				if cnt != _bed2_s03_after:
					_bed2_s03_after = cnt
					_log("  LOOP: bedroom#2 s03_play_count=%d (penjaga s03_played=%s)" % [
						cnt, str(FlagStore.get_flag(BedroomController.S03_PLAYED_FLAG, false))])
		if _loop_bed_visits >= 2 and _visited.size() >= 3 and not _is_busy(cs) and _bed2_s03_after >= 0:
			_finish("LOOP_DONE")


## Tekan tombol pilihan asli (sinyal `pressed`) sesuai indeks per-scene.
func _auto_answer_choices(cs: Node) -> void:
	var cm: Node = _find_first(cs, "ChoiceMenu")
	if cm == null:
		return
	var idx: int = _choice_index_for(_last_path)
	var bc: Node = cm.get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsScroll/ButtonContainer")
	if bc == null:
		return
	var n: int = bc.get_child_count()
	if n == 0:
		return
	# Kunci per (scene, kunjungan, urutan pilihan) — jumlah tombol bisa sama
	# antar-dialog DAN antar-kunjungan scene yang sama.
	var key: String = "%s|v=%d|seq=%d|n=%d" % [_last_path, _visited.size(), _choice_seq, n]
	if _did.has(key):
		return
	_choice_seq += 1
	if idx >= n:
		idx = n - 1
	var btn: Node = bc.get_child(idx)
	_did[key] = true
	_log("  choice: scene=%s seq=%d n=%d -> press idx=%d (text=%s)" % [_last_path.get_file(), _choice_seq, n, idx, _btn_text(btn)])
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
			return 0


func _drive(cs: Node, path: String) -> void:
	match _mode:
		"gate_off", "gate_on":
			_drive_gate(cs, path)
		"window", "window_off":
			_drive_window(cs, path)
		"loop":
			_drive_loop(cs, path)
		_:
			_drive_full(cs, path)


## ---- Mode loop: kamar->lorong->kamar (room_door lantai 3)->keluar lagi; cek S03 diulang? ----
func _drive_loop(cs: Node, path: String) -> void:
	if path == CORRIDOR:
		# Kunjungan ke-1: kembali ke kamar lewat pintu kamar (lantai 3).
		if _loop_corr_visits == 1 and not _did.has("loop_back"):
			_did["loop_back"] = true
			_log("  LOOP: corridor#1 -> touch room_door (kembali ke kamar)")
			_interactable(cs, "room_door").call("interact")
		return
	if path != BEDROOM:
		return
	# Kamar ke-2: keluar lagi lewat pintu (harus TIDAK memutar S03 lagi).
	if _loop_bed_visits >= 2 and not _did.has("loop_out2"):
		if not _player_free(cs):
			var tb3: Node = _find_first(cs, "ThoughtBox")
			_log("  LOOP: bedroom#2 busy, txt='%s' s03=%s" % [
				str(tb3.get("_current_text") if tb3 else "").substr(0,30), str(cs.get("s03_play_count"))])
			return
		_did["loop_out2"] = true
		_log("  LOOP: bedroom#2 -> touch door (s03_play_count=%s)" % str(cs.get("s03_play_count")))
		_interactable(cs, "door").call("interact")
		return
	# Kamar ke-1: keluar lewat pintu.
	if _loop_bed_visits == 1 and not _did.has("loop_out1"):
		if not _player_free(cs):
			return
		_did["loop_out1"] = true
		_log("  LOOP: bedroom#1 -> touch door (s03_play_count=%s)" % str(cs.get("s03_play_count")))
		_interactable(cs, "door").call("interact")


## ---- Mode window: dari kamar coba keluar lewat jendela/balkon (BalconyTrigger) ----
func _drive_window(cs: Node, path: String) -> void:
	if path != BEDROOM:
		return
	if _did.has("win"):
		return
	if not _did.has("win_dbg"):
		_did["win_dbg"] = true
		_log("  WINDOW: begin (busy=%s)" % str(_is_busy(cs)))
	# Diagnostik periodik.
	if _mode == "window":
		var tb: Node = _find_first(cs, "ThoughtBox")
		var lbl: Node = tb.get_node_or_null("PanelContainer/MarginContainer/ScrollContainer/RichTextLabel") if tb else null
		var txt: String = (lbl as RichTextLabel).text if lbl else "<none>"
		_log("  WINDOW: state busy=%s tea=%s mirror=%s clock=%s unlocked=%s txt='%s'" % [
			str(_is_busy(cs)), str(_did.has("win_tea")), str(_did.has("win_mirror")),
			str(_did.has("win_clock")), str(cs.get("_balcony_unlocked")), txt.substr(0, 24)])
	# Buka balkon: periksa 3 objek + jam (seperti pemain nyata), lalu sentuh trigger.
	var bed: Node = cs
	if not _did.has("win_unlock"):
		if FlagStore.get_flag("noticed_clock", false) and bed.get("_balcony_unlocked") == true:
			_did["win_unlock"] = true
		else:
			# Panggil handler objek asli (bukan set flag langsung) agar setara pemain.
			if not _is_busy(cs):
				if not _did.has("win_tea"):
					_did["win_tea"] = true
					_interactable(cs, "tea").call("interact")
				elif not _did.has("win_mirror"):
					_did["win_mirror"] = true
					_interactable(cs, "mirror").call("interact")
				elif not _did.has("win_clock"):
					_did["win_clock"] = true
					_interactable(cs, "clock").call("interact")
			return
	# Balkon terbuka: berjalan ke trigger (langsung panggil sinyal asli area).
	if not _did.has("win"):
		if not _is_busy(cs):
			_did["win"] = true
			_log("  BEDROOM: enter balcony trigger")
			cs.call("_on_balcony_trigger_entered", cs.get_node("Player"))


## ---- Mode gate: coba keluar kamar lewat pintu O6 (alur naskah penuh) ----
func _drive_gate(cs: Node, path: String) -> void:
	if path != BEDROOM:
		return
	# Tunggu intro selesai & pemain bisa bergerak.
	if not _player_free(cs):
		return
	var door: Node = _interactable(cs, "door")
	if door == null:
		return
	var key: String = "gate_door"
	if _did.has(key):
		return
	# Panggil interaksi lewat sinyal asli Interactable (bukan handler controller).
	_did[key] = true
	_log("  touch door (checked_phone=%s)" % str(FlagStore.get_flag("checked_phone", false)))
	door.call("interact")


## ---- Mode full: S00 -> S08 ----
func _drive_full(cs: Node, path: String) -> void:
	match path:
		CW:
			var b: Node = _find_first(cs, "ProceedButton")
			if b and not _did.has("cw"):
				_did["cw"] = true
				_log("  CW: proceed")
				b.emit_signal("pressed")
		MM:
			var b2: Node = _find_first(cs, "StartButton")
			if b2 and not _did.has("mm"):
				_did["mm"] = true
				_log("  MM: start")
				b2.emit_signal("pressed")
		INTRO:
			if not _did.has("intro"):
				_did["intro"] = true
				_log("  INTRO: skip")
				cs.set("_skipped", true)
		BEDROOM:
			_drive_bedroom(cs)
		CORRIDOR:
			_drive_corridor(cs)
		LIFT:
			pass  # menu lantai dijawab oleh _auto_answer_choices (idx=2)
		BALCONY:
			pass  # pilihan [Lompat] dijawab oleh _auto_answer_choices (idx=0)
		FLASHBACK:
			pass  # auto_start -> bedroom (S08)
	if _mode == "full" and FlagStore.get_flag("received_mystery_message", false) and _last_path == BEDROOM:
		_finish("S08_REACHED")


func _drive_bedroom(cs: Node) -> void:
	# S08 (kembali dari flashback): jawab input chat pemain.
	var chat: Node = _find_chat(cs)
	if chat != null:
		var ir: Node = chat.get_node_or_null("Panel/MarginContainer/VBoxContainer/InputRow")
		if ir != null and (ir as Control).visible:
			var le: Node = chat.get_node_or_null("Panel/MarginContainer/VBoxContainer/InputRow/LineEdit")
			if le != null and not _did.has("s08_input"):
				_did["s08_input"] = true
				_log("  BEDROOM(S08): submit chat input")
				(le as LineEdit).text = "Siapa kamu?"
				chat.call("_on_send_pressed")
			return

	if not _player_free(cs):
		return
	# Fase S02: periksa ponsel (syarat gate), lalu buka pintu -> lorong.
	if not _did.has("bed_phone"):
		_did["bed_phone"] = true
		var phone: Node = _interactable(cs, "phone")
		if phone:
			_log("  BEDROOM: touch phone")
			phone.call("interact")
		return
	if FlagStore.get_flag("checked_phone", false) and not _did.has("bed_door"):
		# Tunggu ponsel selesai (tak ada dialog aktif).
		if not _is_busy(cs):
			_did["bed_door"] = true
			var door: Node = _interactable(cs, "door")
			if door:
				_log("  BEDROOM: touch door")
				door.call("interact")


func _drive_corridor(cs: Node) -> void:
	if not _player_free(cs):
		return
	if _did.has("corr_elev"):
		return
	_did["corr_elev"] = true
	var elev: Node = _interactable(cs, "elevator")
	if elev:
		_log("  CORRIDOR: touch elevator")
		elev.call("interact")


## Pemain bebas bergerak (tak sedang dialog/pilihan).
func _player_free(cs: Node) -> bool:
	if _is_busy(cs):
		return false
	var p: Node = cs.get_node_or_null("Player")
	if p == null:
		return true
	return bool(p.get("can_move"))


func _is_busy(cs: Node) -> bool:
	var interacting: Variant = cs.get("_is_interacting")
	if interacting != null and bool(interacting):
		return true
	var cm: Node = _find_first(cs, "ChoiceMenu")
	if cm and cm.visible:
		return true
	var tb: Node = _find_first(cs, "ThoughtBox")
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


func _find_chat(root: Node) -> Node:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is ChatSystem:
			return n
		for c in n.get_children():
			stack.append(c)
	return null


func _find_first(root: Node, cls: String) -> Node:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.is_class(cls) or (n.get_script() != null and n.get_class() == cls):
			return n
		# class_name types
		if cls == "ChoiceMenu" and n is ChoiceMenu:
			return n
		if cls == "ThoughtBox" and n is ThoughtBox:
			return n
		if cls == "ProceedButton" and n.name == "ProceedButton":
			return n
		if cls == "StartButton" and n.name == "StartButton":
			return n
		for c in n.get_children():
			stack.append(c)
	return null


func _finish(reason: String) -> void:
	if _finished:
		return
	_finished = true
	set_process(false)
	Engine.time_scale = 1.0
	_log("RESULT mode=%s reason=%s chain=%s" % [_mode, reason, str(_visited)])
	_log("FLAGS %s" % str(_flag_snapshot()))
	var f := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(_lines))
		f.close()
	print("=== AUDIT FLOW PROBE DONE (%s) ===" % reason)
	get_tree().quit(0)


func _flag_snapshot() -> Dictionary:
	var keys: Array[String] = [
		"checked_phone", "tried_open_message", "avoided_message", "turned_photo",
		"left_photo", "noticed_tea", "talked_to_mirror", "noticed_clock",
		"clock_started", "tried_door", "checked_fridge", "checked_sink",
		"heard_phone_buzz", "saw_moon_hidden", "waited_long",
		"received_mystery_message", "saw_flashback_1", "rooftop_from_lift",
		"rooftop_arrived", "corridor_floor", "corridor_from_elevator",
		"reached_floor5_balcony", "visited_corridor", "loop1_player_reply",
	]
	var out: Dictionary = {}
	for k in keys:
		var v: Variant = FlagStore.get_flag(k, null)
		if v != null:
			out[k] = v
	return out


func _log(s: String) -> void:
	_lines.append(s)
	print(s)
