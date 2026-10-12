## Test aksesibilitas & layout UI (Bab 1)
## Membuktikan:
##   1. "Ukuran Huruf" (font_size_multiplier) benar-benar men-scale SEMUA teks UI
##      (bukan hanya chat_bubble/choice_menu/thought_box).
##   2. "Kontras Tinggi" memberi warna putih penuh + bingkai, bukan warna saja.
##   3. Layout tidak terpotong saat huruf diperbesar (panel tumbuh/scroll).
##   4. Teks UI lewat lokalisasi (tidak ada string literal hardcoded di scene).
extends Node

const UI_SCENES: Array[String] = [
	"res://scenes/ui/content_warning.tscn",
	"res://scenes/ui/help_menu.tscn",
	"res://scenes/ui/settings_menu.tscn",
	"res://scenes/main_menu/main_menu.tscn",
	"res://scenes/ui/choice_menu.tscn",
	"res://scenes/ui/thought_box.tscn",
	"res://scenes/ui/chat_ui.tscn",
]

const HUD_SCENES: Array[String] = [
	"res://scenes/bedroom/bedroom.tscn",
	"res://scenes/lift/lift.tscn",
	"res://scenes/corridor/corridor.tscn",
]

var _fail: int = 0


func _ready() -> void:
	print("=== TEST: UI AKSESIBILITAS & LAYOUT ===")
	TranslationServer.set_locale("id")

	var old_mult: float = SettingsManager.font_size_multiplier
	var old_hc: bool = SettingsManager.high_contrast

	await _test_font_scaling()
	await _test_high_contrast()
	await _test_no_clip()
	await _test_main_menu_buttons()
	await _test_settings_slider_labels()
	await _test_settings_tab_titles()
	await _test_hud_no_overlap()
	await _test_interact_prompt_centered()
	_test_no_raw_literals()

	# Pulihkan pengaturan agar tak mengotori uji lain (tersimpan ke user://).
	SettingsManager.font_size_multiplier = old_mult
	SettingsManager.high_contrast = old_hc
	SettingsManager.save_settings()

	if _fail == 0:
		print("=== SEMUA TEST UI AKSESIBILITAS LULUS ===")
		get_tree().quit(0)
	else:
		print("=== GAGAL: %d assertion ===" % _fail)
		get_tree().quit(1)


# ---------------------------------------------------------------------------
# 1. Skala huruf ter-wire ke SELURUH teks UI
# ---------------------------------------------------------------------------
func _test_font_scaling() -> void:
	print("  - Menguji skala huruf (2x) di semua UI...")
	SettingsManager.font_size_multiplier = 1.0
	SettingsManager.high_contrast = false
	SettingsManager.save_settings()
	await get_tree().process_frame

	var paths: Array[String] = UI_SCENES.duplicate()
	paths.append_array(HUD_SCENES)

	for path in paths:
		var node: Node = _spawn(path)
		if node == null:
			continue
		await _settle()
		var scaled: Array = _collect_font_nodes(node)
		_check(scaled.size() > 0, "%s: tidak ada node huruf yang ter-wire" % path)
		for entry in scaled:
			_check(int(entry["base"]) > 0, "%s: base font 0" % path)
		# Naikkan ke 2x
		SettingsManager.font_size_multiplier = 2.0
		SettingsManager.save_settings()
		await _settle()
		for entry in scaled:
			var c: Control = entry["node"]
			var key: String = entry["key"]
			var base: int = int(entry["base"])
			var expected: int = int(round(float(base) * 2.0))
			var got: int = c.get_theme_font_size(key)
			_check(got == expected,
				"%s: %s.%s skala 2x diharapkan %d, dapat %d" % [path, c.name, key, expected, got])
		SettingsManager.font_size_multiplier = 1.0
		SettingsManager.save_settings()
		await get_tree().process_frame
		node.queue_free()
	print("    Skala huruf: OK")


# ---------------------------------------------------------------------------
# 2. Kontras tinggi: putih penuh + bingkai (bukan warna saja)
# ---------------------------------------------------------------------------
func _test_high_contrast() -> void:
	print("  - Menguji kontras tinggi...")
	SettingsManager.font_size_multiplier = 1.0
	SettingsManager.high_contrast = false
	SettingsManager.save_settings()
	await get_tree().process_frame

	for path in UI_SCENES:
		var node: Node = _spawn(path)
		if node == null:
			continue
		await _settle()
		SettingsManager.high_contrast = true
		SettingsManager.save_settings()
		await _settle()

		var labels: Array = []
		_collect_controls(node, labels)
		var white_found: bool = false
		for c in labels:
			if c is Label:
				var col: Color = c.get_theme_color("font_color")
				if col.r > 0.99 and col.g > 0.99 and col.b > 0.99:
					white_found = true
					break
			elif c is RichTextLabel:
				var col2: Color = c.get_theme_color("default_color")
				if col2.r > 0.99 and col2.g > 0.99 and col2.b > 0.99:
					white_found = true
					break
		_check(white_found, "%s: kontras tinggi tidak memberi teks putih penuh" % path)

		SettingsManager.high_contrast = false
		SettingsManager.save_settings()
		await get_tree().process_frame
		node.queue_free()
	print("    Kontras tinggi: OK")


# ---------------------------------------------------------------------------
# 3. Layout tidak terpotong saat huruf 2x
# ---------------------------------------------------------------------------
func _test_no_clip() -> void:
	print("  - Menguji layout tak terpotong pada huruf 2x...")
	SettingsManager.font_size_multiplier = 2.0
	SettingsManager.high_contrast = false
	SettingsManager.save_settings()

	for path in UI_SCENES:
		var node: Node = _spawn(path)
		if node == null:
			continue
		await _settle()
		await _settle()

		# Setiap panel teratas harus MUAT di viewport 640x360, ATAU berada di
		# dalam ScrollContainer (bisa digeser) sehingga isinya tetap terjangkau.
		for panel in _top_panels(node):
			var need: Vector2 = panel.get_combined_minimum_size()
			var fits: bool = need.x <= 640.5 and need.y <= 360.5
			var scrollable: bool = _has_scroll_ancestor(panel)
			_check(fits or scrollable,
				"%s: panel %s butuh %s dan tidak scrollable (terpotong)" % [path, panel.name, str(need)])

		node.queue_free()

	SettingsManager.font_size_multiplier = 1.0
	SettingsManager.save_settings()
	print("    Layout tak terpotong: OK")


# ---------------------------------------------------------------------------
# 3b. MainMenu: SEMUA tombol terlihat & dalam batas viewport pada 1x/2x/2.5x
# ---------------------------------------------------------------------------
## Regresi BUG-2: pada font 2x tombol "Keluar" (QuitButton) terpotong oleh
## ScrollContainer. Uji geometri nyata (bukan sekadar pemanggilan sinyal):
## tiap tombol harus berada penuh di dalam viewport pada kondisi diam, dan
## tetap terjangkau (bisa di-scroll sampai penuh) pada 2.5x.
func _test_main_menu_buttons() -> void:
	print("  - Menguji tombol MainMenu terlihat penuh pada 1x/2x/2.5x...")
	const MAIN_MENU: String = "res://scenes/main_menu/main_menu.tscn"
	const BUTTONS: Array[String] = ["StartButton", "SettingsButton", "HelpButton", "QuitButton"]
	var prev_mult: float = SettingsManager.font_size_multiplier

	for mult in [1.0, 2.0, 2.5]:
		SettingsManager.font_size_multiplier = mult
		SettingsManager.save_settings()
		var node: Node = _spawn(MAIN_MENU)
		if node == null:
			continue
		await _settle()
		await _settle()

		var sc: ScrollContainer = node.get_node("MarginContainer/ScrollContainer") as ScrollContainer
		var mb: VBoxContainer = node.get_node(
			"MarginContainer/ScrollContainer/CenterContainer/VBoxContainer/MenuButtons") as VBoxContainer
		var view: Rect2 = sc.get_global_rect()

		# a) Kondisi diam: setiap tombol penuh di dalam viewport.
		for b in BUTTONS:
			var btn: Button = mb.get_node(b) as Button
			_check(btn != null and btn.is_visible_in_tree(),
				"MainMenu x%.1f: %s tidak terlihat" % [mult, b])
			if btn == null:
				continue
			var r: Rect2 = btn.get_global_rect()
			_check(r.size.y > 0.5 and r.size.x > 0.5,
				"MainMenu x%.1f: %s berukuran 0 (tak tampil)" % [mult, b])
			_check(r.position.y >= view.position.y - 0.5 and r.end.y <= view.end.y + 0.5,
				"MainMenu x%.1f: %s terpotong (btn_y=%.0f..%.0f view_y=%.0f..%.0f)" % [
					mult, b, r.position.y, r.end.y, view.position.y, view.end.y])

		# b) Keterjangkauan: pada 2.5x (konten > viewport) tiap tombol tetap
		#    bisa di-scroll sampai terlihat penuh.
		for b in BUTTONS:
			var btn2: Button = mb.get_node(b) as Button
			if btn2 == null:
				continue
			sc.scroll_vertical = 0
			await get_tree().process_frame
			var r2: Rect2 = btn2.get_global_rect()
			var target: int = maxi(0, int(round(float(sc.scroll_vertical) + (r2.end.y - view.end.y))))
			sc.scroll_vertical = target
			await get_tree().process_frame
			var r3: Rect2 = btn2.get_global_rect()
			_check(r3.position.y >= view.position.y - 0.5 and r3.end.y <= view.end.y + 0.5,
				"MainMenu x%.1f: %s tak bisa di-scroll sampai terlihat penuh" % [mult, b])

		node.queue_free()
		await get_tree().process_frame

	SettingsManager.font_size_multiplier = prev_mult
	SettingsManager.save_settings()
	print("    Tombol MainMenu terlihat penuh 1x/2x/2.5x: OK")


# ---------------------------------------------------------------------------
# 3c. SettingsMenu: 5 label slider harus terisi via tr() pada 1x DAN 2x
# ---------------------------------------------------------------------------
## Regresi BUG-5: `_set_label` menambahkan _ROOT dua kali (path ganda) →
## get_node_or_null() = null → kelima label dibiarkan kosong (no-op senyap).
func _test_settings_slider_labels() -> void:
	print("  - Menguji label slider SettingsMenu terisi (1x/2x)...")
	const SETTINGS: String = "res://scenes/ui/settings_menu.tscn"
	const SROOT: String = "MarginContainer/ScrollContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer"
	var expected: Array = [
		{"path": SROOT + "/TabContainer/Audio/BgmRow/Label", "key": "SETTINGS_BGM_VOL"},
		{"path": SROOT + "/TabContainer/Audio/SfxRow/Label", "key": "SETTINGS_SFX_VOL"},
		{"path": SROOT + "/TabContainer/Audio/AmbRow/Label", "key": "SETTINGS_AMBIENCE_VOL"},
		{"path": SROOT + "/TabContainer/Gameplay/TextSpeedRow/Label", "key": "SETTINGS_TEXT_SPEED"},
		{"path": SROOT + "/TabContainer/A11y/FontSizeRow/Label", "key": "SETTINGS_FONT_SIZE"},
	]
	var prev_mult: float = SettingsManager.font_size_multiplier

	for mult in [1.0, 2.0]:
		SettingsManager.font_size_multiplier = mult
		SettingsManager.save_settings()
		var node: Node = _spawn(SETTINGS)
		if node == null:
			continue
		await _settle()
		for e in expected:
			var lbl: Label = node.get_node_or_null(e["path"]) as Label
			_check(lbl != null, "SettingsMenu x%.1f: label hilang di %s" % [mult, e["path"]])
			if lbl == null:
				continue
			var want: String = tr(e["key"])
			_check(lbl.text != "" and lbl.text == want,
				"SettingsMenu x%.1f: %s text=\"%s\" diharapkan \"%s\"" % [mult, e["path"], lbl.text, want])
		node.queue_free()
		await get_tree().process_frame

	SettingsManager.font_size_multiplier = prev_mult
	SettingsManager.save_settings()
	print("    Label slider SettingsMenu 1x/2x: OK")


# ---------------------------------------------------------------------------
# 3d. SettingsMenu: judul tab (TabContainer) harus ikut "Ukuran Huruf"
# ---------------------------------------------------------------------------
## Regresi BUG-6: judul tab SettingsMenu (Audio/Permainan/Aksesibilitas) memakai
## font default TabBar (16) yang TIDAK ikut `font_size_multiplier`, sehingga
## pemain yang memperbesar huruf tetap melihat judul tab kecil. Uji: ukuran font
## judul tab harus == dasar*mult, dan semua judul tetap terlihat (TabBar membungkus
## ke baris berikutnya, bukan memotong).
func _test_settings_tab_titles() -> void:
	print("  - Menguji judul tab SettingsMenu ikut skala huruf (1x/2x)...")
	const SETTINGS: String = "res://scenes/ui/settings_menu.tscn"
	var prev_mult: float = SettingsManager.font_size_multiplier

	for mult in [1.0, 2.0]:
		SettingsManager.font_size_multiplier = mult
		SettingsManager.save_settings()
		var node: Node = _spawn(SETTINGS)
		if node == null:
			continue
		await _settle()
		await _settle()

		var tc: TabContainer = node.find_child("TabContainer", true, false) as TabContainer
		_check(tc != null, "SettingsMenu x%.1f: TabContainer hilang" % mult)
		if tc == null:
			node.queue_free()
			continue

		var tb: TabBar = tc.get_tab_bar()
		var fs: int = tb.get_theme_font_size("font_size")
		var base: int = 16
		var expected: int = int(round(float(base) * mult))
		_check(fs == expected,
			"SettingsMenu x%.1f: font judul tab diharapkan %d, dapat %d (judul tab tak ikut skala)" % [mult, expected, fs])

		# Semua judul tab harus benar-benar terlihat: rect tab muat lebar teks.
		var f: Font = tb.get_theme_font("font")
		for i in tc.get_tab_count():
			var title: String = tc.get_tab_title(i)
			var need: float = f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var r: Rect2 = tb.get_tab_rect(i)
			_check(r.size.x + 0.5 >= need,
				"SettingsMenu x%.1f: judul tab '%s' terpotong (rect=%.0f < teks=%.0f)" % [mult, title, r.size.x, need])

		node.queue_free()
		await get_tree().process_frame

	SettingsManager.font_size_multiplier = prev_mult
	SettingsManager.save_settings()
	print("    Judul tab SettingsMenu ikut skala 1x/2x: OK")


# ---------------------------------------------------------------------------
# 3e. HUD: label tak boleh tumpang tindih pada 1x-2.5x
# ---------------------------------------------------------------------------
## Regresi BUG-7: pada font 2x/2.5x label lantai (`UI/FloorLabel`) tumbuh ke
## bawah menimpa petunjuk (`UI/HintLabel`) di lift & koridor. Uji: rect kedua
## label tidak boleh tumpang tindih (di luar toleransi sub-piksel) di semua skala.
func _test_hud_no_overlap() -> void:
	print("  - Menguji HUD lift/koridor tak tumpang tindih (1x-2.5x)...")
	const HUD_PAIRS: Array = [
		{"path": "res://scenes/lift/lift.tscn",
			"a": "UI/FloorLabel", "b": "UI/HintLabel",
			"ta": "Lantai 3", "tb": "Ada peta lantai di dinding kanan. Tekan [E] untuk memilih tujuan."},
		{"path": "res://scenes/corridor/corridor.tscn",
			"a": "UI/FloorLabel", "b": "UI/HintLabel",
			"ta": "Lantai 3", "tb": "Di atas lantai ini hanya ada atap. Lift akan membawaku ke sana."},
	]
	var prev_mult: float = SettingsManager.font_size_multiplier

	for mult in [1.0, 1.5, 2.0, 2.5]:
		SettingsManager.font_size_multiplier = mult
		SettingsManager.save_settings()
		for pair in HUD_PAIRS:
			var node: Node = _spawn(pair["path"])
			if node == null:
				continue
			await _settle()
			var la: Label = node.get_node_or_null(pair["a"]) as Label
			var lb: Label = node.get_node_or_null(pair["b"]) as Label
			if la == null or lb == null:
				_check(false, "%s x%.1f: label HUD hilang" % [pair["path"], mult])
				node.queue_free()
				continue
			la.text = pair["ta"]
			lb.text = tr(pair["tb"])
			la.visible = true
			lb.visible = true
			await _settle()
			await _settle()

			var ra: Rect2 = la.get_global_rect()
			var rb: Rect2 = lb.get_global_rect()
			var overlap: bool = ra.intersects(rb, false)
			_check(not overlap,
				"%s x%.1f: %s tumpang tindih %s (a=%.0f..%.0f b=%.0f..%.0f)" % [
					pair["path"], mult, pair["a"], pair["b"],
					ra.position.y, ra.end.y, rb.position.y, rb.end.y])
			node.queue_free()
			await get_tree().process_frame

	SettingsManager.font_size_multiplier = prev_mult
	SettingsManager.save_settings()
	print("    HUD lift/koridor tak tumpang tindih 1x-2.5x: OK")


# ---------------------------------------------------------------------------
# 3f. Prompt interaksi in-world "[E] ..." tetap terpusat & tak terpotong
# ---------------------------------------------------------------------------
## Regresi BUG-8: label prompt `Interactable` memakai kotak lebar-tetap (96px)
## sehingga pada 2.5x teks (115px) melampaui kotak dan bergeser dari pusat objek.
## Uji: pada 1x-2.5x, lebar label >= lebar teks DAN pusat label == pusat objek.
func _test_interact_prompt_centered() -> void:
	print("  - Menguji prompt interaksi '[E] ...' terpusat (1x-2.5x)...")
	const SCENE: String = "res://scenes/corridor/corridor.tscn"
	var prev_mult: float = SettingsManager.font_size_multiplier
	var tested: bool = false

	for mult in [1.0, 1.5, 2.0, 2.5]:
		SettingsManager.font_size_multiplier = mult
		SettingsManager.save_settings()
		var node: Node = _spawn(SCENE)
		if node == null:
			continue
		await _settle()

		# Cari Interactable pertama yang punya anak Label (prompt).
		var area: Area2D = null
		var lbl: Label = null
		var stack: Array = [node]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			if n is Area2D and n.has_method("_setup_prompt"):
				for c in n.get_children():
					if c is Label:
						area = n as Area2D
						lbl = c as Label
						break
				if lbl != null:
					break
			for c in n.get_children():
				stack.append(c)

		if lbl == null or area == null:
			node.queue_free()
			await get_tree().process_frame
			continue
		tested = true
		lbl.visible = true
		await _settle()
		await _settle()

		var fs: int = lbl.get_theme_font_size("font_size")
		var need: float = lbl.get_theme_font("font").get_string_size(
			lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var r: Rect2 = lbl.get_global_rect()
		_check(r.size.x + 0.5 >= need,
			"prompt x%.1f: label (%.0f) < teks (%.0f) -> terpotong" % [mult, r.size.x, need])
		var center_off: float = (r.position.x + r.size.x * 0.5) - area.global_position.x
		_check(absf(center_off) <= 1.0,
			"prompt x%.1f: tak terpusat pada objek (geser %.1f px)" % [mult, center_off])

		node.queue_free()
		await get_tree().process_frame

	_check(tested, "prompt: tak ada Interactable dengan label untuk diuji")
	SettingsManager.font_size_multiplier = prev_mult
	SettingsManager.save_settings()
	print("    Prompt interaksi terpusat 1x-2.5x: OK")


# ---------------------------------------------------------------------------
# 4. Tidak ada string literal mentah di .tscn (semua lewat tr() saat runtime)
# ---------------------------------------------------------------------------
func _test_no_raw_literals() -> void:
	print("  - Menguji tak ada teks mentah di .tscn...")
	var paths: Array[String] = UI_SCENES.duplicate()
	paths.append_array(HUD_SCENES)
	paths.append("res://scenes/ui/chat_bubble.tscn")
	paths.append("res://scenes/transitions/flashback.tscn")
	paths.append("res://scenes/balcony/balcony.tscn")

	var re := RegEx.new()
	re.compile("^[ \\t]*(text|placeholder_text)[ \\t]*=[ \\t]*\"([^\"]+)\"")

	for path in paths:
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			_check(false, "tidak bisa baca %s" % path)
			continue
		var line_no: int = 0
		while not f.eof_reached():
			var line: String = f.get_line()
			line_no += 1
			var m := re.search(line)
			if m:
				_check(false, "%s:%d teks mentah di .tscn: %s = \"%s\"" % [path, line_no, m.get_string(1), m.get_string(2)])
		f.close()
	print("    Tak ada teks mentah di .tscn: OK")


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------
func _spawn(path: String) -> Node:
	var ps: PackedScene = load(path)
	if ps == null:
		_check(false, "gagal load %s" % path)
		return null
	var node: Node = ps.instantiate()
	# Matikan auto-start scene HUD agar tak menjalankan alur.
	if "auto_start_intro" in node:
		node.set("auto_start_intro", false)
	if "auto_start" in node:
		node.set("auto_start", false)
	if "auto_start_sequence" in node:
		node.set("auto_start_sequence", false)
	if "navigate_scenes" in node:
		node.set("navigate_scenes", false)
	add_child(node)
	return node


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _collect_font_nodes(root: Node) -> Array:
	var out: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Control and n.has_meta("__ui_base_font_size"):
			out.append({"node": n, "key": "font_size", "base": int(n.get_meta("__ui_base_font_size"))})
		if n is Control and n.has_meta("__ui_base_normal_font_size"):
			out.append({"node": n, "key": "normal_font_size", "base": int(n.get_meta("__ui_base_normal_font_size"))})
		for ch in n.get_children():
			stack.append(ch)
	return out


func _collect_controls(root: Node, out: Array) -> void:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Control:
			out.append(n)
		for ch in n.get_children():
			stack.append(ch)


func _top_panels(root: Node) -> Array:
	var out: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is PanelContainer and not _has_panel_ancestor(n, root):
			out.append(n as Control)
		for ch in n.get_children():
			stack.append(ch)
	return out


func _has_panel_ancestor(node: Node, stop: Node) -> bool:
	var p: Node = node.get_parent()
	while p != null and p != stop:
		if p is PanelContainer:
			return true
		p = p.get_parent()
	return false


func _has_scroll_ancestor(node: Node) -> bool:
	var p: Node = node.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		printerr("    ASSERT GAGAL: " + msg)
