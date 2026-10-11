## Test regresi keamanan (SAFETY_AND_CONTENT.md §3.1/§3.2/§3.4):
##   1. Layar Content Warning DIRUTEKAN sebagai scene boot dan WAJIB tampil +
##      butuh konfirmasi sebelum permainan (sebelum menu utama).
##   2. Menu Jeda (Esc) ada di scene permainan, dapat dibuka/ditutup, dan
##      Menu Bantuan terjangkau DARINYA (juga dari menu utama).
##   3. Tombol jeda & keluar selalu tersedia (aksi input `pause` = Esc).
##
## Uji ini hanya MEMBACA/INSTANSIASI; tidak mengubah naskah atau urutan adegan.
extends Node

const CONTENT_WARNING_SCENE = preload("res://scenes/ui/content_warning.tscn")
const MAIN_MENU_SCENE = preload("res://scenes/main_menu/main_menu.tscn")
const PAUSE_MENU_SCENE = preload("res://scenes/ui/pause_menu.tscn")
const BEDROOM_SCENE = preload("res://scenes/bedroom/bedroom.tscn")
const CORRIDOR_SCENE = preload("res://scenes/corridor/corridor.tscn")
const LIFT_SCENE = preload("res://scenes/lift/lift.tscn")
const BALCONY_SCENE = preload("res://scenes/balcony/balcony.tscn")

const GAMEPLAY_SCENES: Array[String] = [
	"res://scenes/bedroom/bedroom.tscn",
	"res://scenes/corridor/corridor.tscn",
	"res://scenes/lift/lift.tscn",
	"res://scenes/balcony/balcony.tscn",
	"res://scenes/intro/intro_cutscene.tscn",
	"res://scenes/transitions/flashback.tscn",
]

var _fail: int = 0


func _ready() -> void:
	print("=== TEST: CONTENT WARNING + MENU JEDA (KEAMANAN) ===")
	TranslationServer.set_locale("id")

	_test_boot_scene_is_content_warning()
	_test_pause_action_exists()
	await _test_content_warning_gate()
	_test_pause_menu_from_main_menu()
	await _test_pause_menu_in_gameplay_scenes()

	if _fail == 0:
		print("=== SEMUA TEST CONTENT WARNING + MENU JEDA LULUS ===")
		get_tree().quit(0)
	else:
		print("=== GAGAL: %d assertion ===" % _fail)
		get_tree().quit(1)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		printerr("    ASSERT GAGAL: " + msg)


# ---------------------------------------------------------------------------
# 1. Scene boot = content warning (peringatan tampil SEBELUM permainan)
# ---------------------------------------------------------------------------
func _test_boot_scene_is_content_warning() -> void:
	print("  - Scene boot harus content warning...")
	var f := FileAccess.open("res://project.godot", FileAccess.READ)
	_check(f != null, "tidak bisa baca project.godot")
	if f == null:
		return
	var main_scene: String = ""
	while not f.eof_reached():
		var line: String = f.get_line().strip_edges()
		if line.begins_with("run/main_scene="):
			main_scene = line.split("=")[1].strip_edges().trim_prefix("\"").trim_suffix("\"")
	f.close()
	_check(main_scene == "res://scenes/ui/content_warning.tscn",
		"run/main_scene harus content_warning.tscn (dapat '%s')" % main_scene)
	_check(ContentWarning.MAIN_MENU_SCENE == "res://scenes/main_menu/main_menu.tscn",
		"ContentWarning.MAIN_MENU_SCENE harus menuju menu utama")


# ---------------------------------------------------------------------------
# 2. Aksi input `pause` (Esc) terdaftar
# ---------------------------------------------------------------------------
func _test_pause_action_exists() -> void:
	print("  - Aksi input 'pause' (Esc) harus ada...")
	_check(InputMap.has_action("pause"), "aksi input 'pause' tidak terdaftar di project.godot")
	if InputMap.has_action("pause"):
		var has_esc: bool = false
		for ev in InputMap.action_get_events("pause"):
			if ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_ESCAPE:
				has_esc = true
		_check(has_esc, "aksi 'pause' harus dipetakan ke Esc")


# ---------------------------------------------------------------------------
# 3. Content warning butuh konfirmasi; "Aku mengerti" -> menu utama
# ---------------------------------------------------------------------------
func _test_content_warning_gate() -> void:
	print("  - Content warning butuh konfirmasi...")
	var cw: ContentWarning = CONTENT_WARNING_SCENE.instantiate()
	add_child(cw)
	await get_tree().process_frame

	_check(cw.title_label.text == tr("CW_TITLE"), "CW: judul salah")
	_check(cw.desc_label.text == tr("CW_DESC"), "CW: deskripsi salah")
	_check(cw.proceed_button.text == tr("CW_BTN_PROCEED"), "CW: tombol konfirmasi salah")
	_check(cw.help_button != null, "CW: tombol bantuan harus ada")
	_check(cw.quit_button != null, "CW: tombol keluar harus ada")
	_check(cw.help_menu != null, "CW: Menu Bantuan harus tersedia")

	var acked: Dictionary = {"ok": false}
	cw.warning_acknowledged.connect(func() -> void: acked["ok"] = true)
	cw.proceed_button.emit_signal("pressed")
	_check(acked["ok"], "CW: 'Aku mengerti' harus memancarkan warning_acknowledged")

	cw.queue_free()
	await get_tree().process_frame


# ---------------------------------------------------------------------------
# 4. Menu Bantuan terjangkau dari MENU UTAMA
# ---------------------------------------------------------------------------
func _test_pause_menu_from_main_menu() -> void:
	print("  - Menu Bantuan dari menu utama...")
	var mm: MainMenu = MAIN_MENU_SCENE.instantiate()
	add_child(mm)
	_check(mm.help_menu != null, "MainMenu: Menu Bantuan harus ada")
	mm.help_button.emit_signal("pressed")
	_check(mm.help_menu.visible, "MainMenu: tombol Bantuan harus membuka Menu Bantuan")
	mm.help_menu.close_button.emit_signal("pressed")
	_check(not mm.help_menu.visible, "MainMenu: Menu Bantuan harus bisa ditutup")
	mm.queue_free()


# ---------------------------------------------------------------------------
# 5. Menu Jeda ada di tiap scene permainan; Esc membuka/menutup;
#    Menu Bantuan terjangkau DARI menu jeda; tombol keluar selalu ada.
# ---------------------------------------------------------------------------
func _test_pause_menu_in_gameplay_scenes() -> void:
	print("  - Menu Jeda di scene permainan...")

	# Uji perilaku mendalam pada satu scene gameplay (bedroom).
	var bed: BedroomController = BEDROOM_SCENE.instantiate()
	bed.auto_start_intro = false
	add_child(bed)
	await get_tree().process_frame

	var pm: PauseMenu = bed.get_node_or_null("UI/PauseMenu")
	_check(pm != null, "Bedroom: node PauseMenu harus ada")
	if pm != null:
		_check(not pm.visible, "PauseMenu: harus tersembunyi saat mulai")
		_check(pm.quit_button != null, "PauseMenu: tombol keluar harus selalu ada")
		_check(pm.help_menu != null, "PauseMenu: Menu Bantuan harus ada")

		# Esc membuka jeda -> waktu permainan berhenti.
		_send_pause(bed)
		_check(pm.visible, "PauseMenu: Esc harus membuka menu jeda")
		_check(get_tree().paused, "PauseMenu: membuka jeda harus menghentikan waktu (paused)")

		# Menu Bantuan terjangkau DARI menu jeda.
		pm.help_button.emit_signal("pressed")
		_check(pm.help_menu.visible, "PauseMenu: tombol Bantuan harus membuka Menu Bantuan")
		_check(pm.help_menu.item2_label.text.contains("119"),
			"PauseMenu: Menu Bantuan harus memuat sumber bantuan (119)")
		pm.help_menu.close_button.emit_signal("pressed")

		# Esc menutup jeda -> waktu lanjut.
		_send_pause(bed)
		_check(not pm.visible, "PauseMenu: Esc kedua harus menutup menu jeda")
		_check(not get_tree().paused, "PauseMenu: menutup jeda harus melanjutkan waktu")

	bed.queue_free()
	await get_tree().process_frame

	# Semua scene permainan harus memuat Menu Jeda (tombol selalu tersedia).
	for path in GAMEPLAY_SCENES:
		var node: Node = (load(path) as PackedScene).instantiate()
		if "auto_start_intro" in node:
			node.set("auto_start_intro", false)
		if "auto_start" in node:
			node.set("auto_start", false)
		if "auto_start_sequence" in node:
			node.set("auto_start_sequence", false)
		if "navigate_scenes" in node:
			node.set("navigate_scenes", false)
		add_child(node)
		await get_tree().process_frame
		var pause_node: PauseMenu = _find_pause(node)
		_check(pause_node != null, "%s: harus memuat Menu Jeda" % path)
		if pause_node != null:
			_check(pause_node.help_menu != null, "%s: Menu Jeda harus punya Menu Bantuan" % path)
			_check(pause_node.quit_button != null, "%s: Menu Jeda harus punya tombol keluar" % path)
		node.queue_free()
		await get_tree().process_frame


## Kirim aksi `pause` (Esc) ke menu jeda di dalam scene, seperti input nyata.
func _send_pause(scene_root: Node) -> void:
	var pm: PauseMenu = _find_pause(scene_root)
	if pm != null:
		pm._unhandled_input(_make_pause_event())


func _find_pause(root: Node) -> PauseMenu:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is PauseMenu:
			return n as PauseMenu
		for ch in n.get_children():
			stack.append(ch)
	return null


func _make_pause_event() -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = "pause"
	ev.pressed = true
	return ev
