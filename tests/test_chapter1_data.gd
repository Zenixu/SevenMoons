## Test data & lokalisasi Chapter 1 (mikha)
## Memverifikasi:
##  1. chapter_01.json memuat tanpa error & sesuai format resmi (tipe step didukung).
##  2. SETIAP kunci teks/prompt punya entri di id.csv (tr() tidak jatuh ke fallback kunci).
##  3. Kunci speaker "ARU"/"SUARA" tersedia di id.csv.
##  4. Urutan adegan JSON persis rantai naskah: S01->S02->S03->S04->S05->S06->S07->S08
##     (+ S06_ALT bercabang ke S07).
##  5. Semua target next_scene valid (ada di dalam "scenes").
##
## Catatan: test ini HANYA membaca data — tidak mengubah naskah/urutan.
extends Node

const SUPPORTED_STEPS: Array[String] = [
	"narration", "line", "pause", "choice", "set_flag", "ui",
	"sfx", "bgm", "vfx", "next_scene", "chat_message", "text_input",
]
const EXPECTED_CHAIN: Array[String] = ["S01", "S02", "S03", "S04", "S05", "S06", "S07", "S08"]

var _fail: int = 0


func _ready() -> void:
	print("=== TEST: DATA & LOKALISASI CHAPTER 1 ===")
	TranslationServer.set_locale("id")

	_test_load()
	_test_step_types()
	_test_text_keys()
	_test_speakers()
	_test_scene_chain()

	if _fail == 0:
		print("=== SEMUA TEST DATA CHAPTER 1 LULUS ===")
		get_tree().quit(0)
	else:
		print("=== TEST DATA CHAPTER 1 GAGAL: %d masalah ===" % _fail)
		get_tree().quit(1)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: ", msg)


func _test_load() -> void:
	var err: Error = DialogueRunner.load_chapter(1)
	_check(err == OK, "DialogueRunner.load_chapter(1) gagal")
	_check(DialogueRunner._chapter_data.has("scenes"), "chapter data tanpa 'scenes'")
	print("  - chapter_01.json dimuat: OK")


func _iter_steps() -> Array:
	var out: Array = []
	var scenes: Dictionary = DialogueRunner._chapter_data.get("scenes", {})
	for sid in scenes.keys():
		for step in scenes[sid].get("steps", []):
			out.append({"sid": sid, "step": step})
	return out


func _test_step_types() -> void:
	for item in _iter_steps():
		var step: Dictionary = item["step"]
		var t: String = step.get("type", "")
		_check(SUPPORTED_STEPS.has(t), "tipe step tak didukung '%s' di %s" % [t, item["sid"]])
	print("  - semua tipe step didukung: OK")


func _test_text_keys() -> void:
	var missing: Array[String] = []
	for item in _iter_steps():
		var step: Dictionary = item["step"]
		for field in ["text", "prompt"]:
			if step.has(field) and typeof(step[field]) == TYPE_STRING:
				var key: String = step[field]
				# tr() mengembalikan kunci apa adanya bila entri tak ada.
				if tr(key) == key:
					missing.append("%s:%s" % [item["sid"], key])
		# Pilihan juga berisi kunci teks.
		for opt in step.get("options", []):
			if opt is Dictionary and opt.has("text"):
				var okey: String = opt["text"]
				if tr(okey) == okey:
					missing.append("%s:opt:%s" % [item["sid"], okey])
	_check(missing.is_empty(), "kunci tanpa entri id.csv: %s" % str(missing))
	print("  - semua kunci teks tersedia di id.csv: OK")


func _test_speakers() -> void:
	var speakers: Dictionary = {}
	for item in _iter_steps():
		var step: Dictionary = item["step"]
		if step.get("type", "") == "line" and step.has("speaker"):
			speakers[step["speaker"]] = true
	for sp in ["ARU", "SUARA"]:
		_check(speakers.has(sp), "speaker '%s' tidak dipakai di JSON" % sp)
		_check(tr(sp) != sp, "kunci speaker '%s' tak ada di id.csv" % sp)
	print("  - kunci speaker ARU/SUARA tersedia: OK")


func _test_scene_chain() -> void:
	var scenes: Dictionary = DialogueRunner._chapter_data.get("scenes", {})
	for sid in EXPECTED_CHAIN:
		_check(scenes.has(sid), "scene '%s' tidak ada" % sid)

	# Rantai utama via next_scene harus berurutan.
	for i in EXPECTED_CHAIN.size() - 1:
		var sid: String = EXPECTED_CHAIN[i]
		var nxt: String = EXPECTED_CHAIN[i + 1]
		var target: String = _first_next_target(sid)
		_check(target == nxt, "%s.next_scene harus '%s' (dapat '%s')" % [sid, nxt, target])

	# Semua target next_scene valid.
	for sid in scenes.keys():
		for step in scenes[sid].get("steps", []):
			if step.get("type", "") == "next_scene":
				var tgt: String = step.get("target", "")
				_check(scenes.has(tgt), "%s.next_scene target '%s' tidak ada" % [sid, tgt])
	_check(_first_next_target("S06_ALT") == "S07", "S06_ALT.next_scene harus S07")
	print("  - urutan adegan & target next_scene valid: OK")


func _first_next_target(sid: String) -> String:
	var scenes: Dictionary = DialogueRunner._chapter_data.get("scenes", {})
	if not scenes.has(sid):
		return ""
	for step in scenes[sid].get("steps", []):
		if step.get("type", "") == "next_scene":
			return step.get("target", "")
	# Scene eksplorasi (mis. S02) memakai field "next" di tingkat scene.
	return scenes[sid].get("next", "")
