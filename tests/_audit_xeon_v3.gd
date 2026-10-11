## AUDIT xeon v3 — logika keterjangkauan BENAR:
## kontrol dianggap bug HANYA jika TIDAK ADA posisi scroll yang membuatnya
## sepenuhnya masuk viewport (bukan sekadar "di luar saat scroll=max").
extends Node

const MENUS: Array[String] = [
	"res://scenes/ui/content_warning.tscn",
	"res://scenes/main_menu/main_menu.tscn",
	"res://scenes/ui/pause_menu.tscn",
	"res://scenes/ui/help_menu.tscn",
	"res://scenes/ui/settings_menu.tscn",
	"res://scenes/ui/choice_menu.tscn",
]

var _bugs: Array[String] = []


func _ready() -> void:
	TranslationServer.set_locale("id")
	print("=== KETERJANGKAUAN MENU (1x/2x/2.5x) ===")
	for mult in [1.0, 2.0, 2.5]:
		for s in MENUS:
			await _probe(s, mult)
	print("\n=== TEKS KOSONG TERLIHAT (semua scene) ===")
	for s in ["res://scenes/ui/content_warning.tscn", "res://scenes/main_menu/main_menu.tscn",
			"res://scenes/ui/pause_menu.tscn", "res://scenes/ui/help_menu.tscn",
			"res://scenes/ui/settings_menu.tscn", "res://scenes/ui/choice_menu.tscn"]:
		await _empty_scan(s)
	print("\n=== RINGKASAN BUG (%d) ===" % _bugs.size())
	for b in _bugs:
		print("  * ", b)
	get_tree().quit(0)


func _spawn(path: String) -> Node:
	var ps: PackedScene = load(path)
	var n: Node = ps.instantiate()
	for k in ["auto_start_intro", "auto_start", "auto_start_sequence", "navigate_scenes"]:
		if k in n:
			n.set(k, false)
	add_child(n)
	return n


func _settle(f: int = 10) -> void:
	for i in f:
		await get_tree().process_frame


func _probe(path: String, mult: float) -> void:
	SettingsManager.font_size_multiplier = mult
	SettingsManager.save_settings()
	var n := _spawn(path)
	if n.has_method("present_choices"):
		n.present_choices([{"text": "S03_R1_OPT_A"}, {"text": "S03_R1_OPT_B"}, {"text": "S03_R1_OPT_C"}], "normal", "")
	await _settle(12)
	var ctrls: Array = []
	_collect_ctrl(n, ctrls)
	var bad: Array[String] = []
	for c in ctrls:
		if not c.is_visible_in_tree():
			continue
		if c.size.x <= 0.5 or c.size.y <= 0.5:
			bad.append("%s size=%s (0-px)" % [c.get_path(), str(c.size)])
			continue
		var sc: Control = _scroll_ancestor(c, n)
		if sc != null:
			if not await _reachable(c, sc):
				bad.append("%s TAK-TERJANGKAU (scroll tak bisa menampilkan penuh) btn=%s" % [c.get_path(), str(c.get_global_rect())])
		else:
			var br: Rect2 = c.get_global_rect()
			var vr := Rect2(0, 0, 640, 360)
			if br.position.y < -0.5 or br.end.y > vr.end.y + 0.5 or br.position.x < -0.5 or br.end.x > vr.end.x + 0.5:
				bad.append("%s TERPOTONG tanpa scroll: btn=%s viewport=%s" % [c.get_path(), str(br), str(vr)])
	if bad.size() > 0:
		print("  [%s x%.1f] BUG=%d" % [path.get_file(), mult, bad.size()])
		for b in bad:
			print("      ", b)
			_bugs.append("%s x%.1f :: %s" % [path.get_file(), mult, b])
	else:
		print("  [%s x%.1f] ok" % [path.get_file(), mult])
	n.queue_free()
	await get_tree().process_frame
	SettingsManager.font_size_multiplier = 1.0
	SettingsManager.save_settings()


## Benar-benar jangkau: coba setiap scroll 0..max; jika ada yang menampilkan penuh -> true.
func _reachable(c: Control, sc: ScrollContainer) -> bool:
	var bar := sc.get_v_scroll_bar()
	var vmax: int = int(max(0.0, bar.max_value - bar.page))
	# Titik uji: untuk kontrol di content, scroll yang menempatkannya di viewport
	# = posisi kontrol dalam konten dikurangi margin.
	var content_top: float = c.get_global_rect().position.y - sc.get_global_rect().position.y + float(sc.scroll_vertical)
	var candidates: Array[int] = [0, vmax]
	var desired: int = int(round(content_top - 4.0))
	candidates.append(clampi(desired, 0, vmax))
	candidates.append(clampi(int(round(content_top + c.size.y - sc.get_global_rect().size.y + 4.0)), 0, vmax))
	for cv in candidates:
		sc.scroll_vertical = cv
		await get_tree().process_frame
		await get_tree().process_frame
		var sr: Rect2 = sc.get_global_rect()
		var br: Rect2 = c.get_global_rect()
		if br.position.y >= sr.position.y - 1.0 and br.end.y <= sr.end.y + 1.0 \
				and br.position.x >= sr.position.x - 1.0 and br.end.x <= sr.end.x + 1.0:
			sc.scroll_vertical = 0
			await get_tree().process_frame
			return true
	sc.scroll_vertical = 0
	await get_tree().process_frame
	return false


func _collect_ctrl(n: Node, out: Array) -> void:
	if n is Button or n is Label or n is CheckBox:
		out.append(n)
	for ch in n.get_children():
		_collect_ctrl(ch, out)


func _scroll_ancestor(node: Node, stop: Node) -> Control:
	var p: Node = node.get_parent()
	while p != null and p != stop:
		if p is ScrollContainer:
			return p
		p = p.get_parent()
	return null


func _empty_scan(path: String) -> void:
	var n := _spawn(path)
	await _settle(12)
	# Aktifkan semua tab settings agar label di tab non-aktif ikut diperiksa.
	if n is SettingsMenu:
		var tc: TabContainer = n.get_node("MarginContainer/ScrollContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer")
		for i in tc.get_tab_count():
			tc.current_tab = i
			await _settle(4)
	var empties: Array[String] = []
	_walk_text(n, empties)
	if empties.size() > 0:
		print("  [%s] teks kosong terlihat=%d" % [path.get_file(), empties.size()])
		for e in empties:
			print("      ", e)
			_bugs.append("TEKS KOSONG: %s :: %s" % [path.get_file(), e])
	else:
		print("  [%s] teks ok" % path.get_file())
	n.queue_free()
	await get_tree().process_frame


func _walk_text(n: Node, out: Array) -> void:
	if n is Label or n is Button or n is CheckBox:
		var c: Control = n
		if c.is_visible_in_tree():
			var t: String = str(c.get("text")) if "text" in c else ""
			if t.strip_edges().is_empty():
				out.append("%s (kosong)" % c.get_path())
	for ch in n.get_children():
		_walk_text(ch, out)
