## AUDIT xeon — Boot smoke + geometri/visibilitas + teks kosong/"..." + sinyal.
## Tujuan: katalogkan bug NYATA (terpotong/0-px/teks kosong) yang lolos suite.
## Tidak mengubah naskah; hanya membaca.
extends Node

const SCENES: Array[String] = [
	"res://scenes/ui/content_warning.tscn",
	"res://scenes/main_menu/main_menu.tscn",
	"res://scenes/intro/intro_cutscene.tscn",
	"res://scenes/bedroom/bedroom.tscn",
	"res://scenes/corridor/corridor.tscn",
	"res://scenes/lift/lift.tscn",
	"res://scenes/balcony/balcony.tscn",
	"res://scenes/transitions/flashback.tscn",
	"res://scenes/ui/pause_menu.tscn",
	"res://scenes/ui/help_menu.tscn",
	"res://scenes/ui/settings_menu.tscn",
	"res://scenes/ui/choice_menu.tscn",
	"res://scenes/ui/chat_ui.tscn",
	"res://scenes/ui/thought_box.tscn",
	"res://scenes/ui/chat_bubble.tscn",
]

const MENUS: Array[String] = [
	"res://scenes/ui/content_warning.tscn",
	"res://scenes/main_menu/main_menu.tscn",
	"res://scenes/ui/pause_menu.tscn",
	"res://scenes/ui/help_menu.tscn",
	"res://scenes/ui/settings_menu.tscn",
	"res://scenes/ui/choice_menu.tscn",
]

var _findings: Array[String] = []


func _ready() -> void:
	TranslationServer.set_locale("id")
	print("=== AUDIT XEON: BOOT SMOKE ===")
	for s in SCENES:
		await _boot(s)
	print("\n=== AUDIT XEON: MENU GEOMETRI (1x/2x/2.5x) ===")
	for mult in [1.0, 2.0, 2.5]:
		for s in MENUS:
			await _menu_geo(s, mult)
	print("\n=== AUDIT XEON: TEKS KOSONG / \"...\" pada UI terlihat ===")
	for s in SCENES:
		await _empty_text(s)
	print("\n=== AUDIT XEON: SINYAL TAK TERSAMBUNG (menu utama) ===")
	await _signals()
	print("\n=== RINGKASAN TEMUAN (%d) ===" % _findings.size())
	for f in _findings:
		print("  * ", f)
	get_tree().quit(0)


func _spawn(path: String) -> Node:
	var ps: PackedScene = load(path)
	if ps == null:
		_findings.append("LOAD GAGAL: " + path)
		return null
	var n: Node = ps.instantiate()
	if "auto_start_intro" in n:
		n.set("auto_start_intro", false)
	if "auto_start" in n:
		n.set("auto_start", false)
	if "auto_start_sequence" in n:
		n.set("auto_start_sequence", false)
	if "navigate_scenes" in n:
		n.set("navigate_scenes", false)
	add_child(n)
	return n


func _settle(frames: int = 6) -> void:
	for i in frames:
		await get_tree().process_frame


func _boot(path: String) -> void:
	var n := _spawn(path)
	if n == null:
		return
	await _settle()
	var zero: Array[String] = []
	_walk_zero(n, zero)
	for z in zero:
		_findings.append("NODE 0-PX terlihat: %s :: %s" % [path.get_file(), z])
	print("  boot %-38s children=%d zero_px=%d" % [path.get_file(), n.get_child_count(), zero.size()])
	n.queue_free()
	await get_tree().process_frame


func _walk_zero(n: Node, out: Array[String]) -> void:
	if n is Control:
		var c: Control = n
		if c.is_visible_in_tree() and c.size.x <= 0.5 and c.size.y <= 0.5:
			out.append(String(c.get_path()))
	for ch in n.get_children():
		_walk_zero(ch, out)


func _menu_geo(path: String, mult: float) -> void:
	SettingsManager.font_size_multiplier = mult
	SettingsManager.save_settings()
	var n := _spawn(path)
	if n == null:
		return
	# choice_menu perlu opsi
	if n.has_method("present_choices"):
		n.present_choices([
			{"text": "S03_R1_OPT_A"}, {"text": "S03_R1_OPT_B"}, {"text": "S03_R1_OPT_C"},
		], "normal", "")
	await _settle(8)
	var clipped: Array[String] = []
	_walk_clip(n, n, clipped)
	print("  [%-26s x%.1f] clipped=%d" % [path.get_file(), mult, clipped.size()])
	for c in clipped:
		_findings.append("TERPOTONG x%.1f: %s :: %s" % [mult, path.get_file(), c])
	n.queue_free()
	await get_tree().process_frame
	SettingsManager.font_size_multiplier = 1.0
	SettingsManager.save_settings()


## Deteksi kontrol (Button/Label) yang keluar dari batas leluhur yang meng-clip
## (PanelContainer/ScrollContainer) meski secara tree terlihat.
func _walk_clip(n: Node, root: Node, out: Array[String]) -> void:
	if n is Control and n.is_visible_in_tree():
		var c: Control = n
		if c is Button or c is Label or c is CheckBox or c is LineEdit:
			if c.size.x <= 0.5 or c.size.y <= 0.5:
				out.append("%s size=%s (0-px)" % [c.get_path(), str(c.size)])
			else:
				var anc: Node = c.get_parent()
				while anc != null and anc != root:
					if anc is PanelContainer or anc is ScrollContainer:
						var ar: Rect2 = (anc as Control).get_global_rect()
						var br: Rect2 = c.get_global_rect()
						if br.end.y > ar.end.y + 1.0 or br.position.y < ar.position.y - 1.0 \
								or br.end.x > ar.end.x + 1.0 or br.position.x < ar.position.x - 1.0:
							out.append("%s di luar %s (btn=%s panel=%s)" % [
								c.get_path(), anc.get_path(), str(br), str(ar)])
						break
					anc = anc.get_parent()
	for ch in n.get_children():
		_walk_clip(ch, root, out)


func _empty_text(path: String) -> void:
	var n := _spawn(path)
	if n == null:
		return
	await _settle(8)
	var empties: Array[String] = []
	_walk_text(n, empties)
	if empties.size() > 0:
		print("  [%s] teks kosong terlihat=%d" % [path.get_file(), empties.size()])
		for e in empties:
			_findings.append("TEKS KOSONG: %s :: %s" % [path.get_file(), e])
	n.queue_free()
	await get_tree().process_frame


func _walk_text(n: Node, out: Array[String]) -> void:
	if n is Label or n is Button or n is CheckBox:
		var c: Control = n
		if c.is_visible_in_tree():
			var t: String = ""
			if "text" in c:
				t = str(c.get("text"))
			if t.strip_edges().is_empty():
				out.append("%s (kosong)" % c.get_path())
	for ch in n.get_children():
		_walk_text(ch, out)


func _signals() -> void:
	var ps: PackedScene = load("res://scenes/main_menu/main_menu.tscn")
	var mm: Node = ps.instantiate()
	add_child(mm)
	await _settle(4)
	var b1: Button = mm.get_node("MarginContainer/ScrollContainer/CenterContainer/VBoxContainer/MenuButtons/StartButton")
	var b2: Button = mm.get_node("MarginContainer/ScrollContainer/CenterContainer/VBoxContainer/MenuButtons/SettingsButton")
	var b3: Button = mm.get_node("MarginContainer/ScrollContainer/CenterContainer/VBoxContainer/MenuButtons/HelpButton")
	var b4: Button = mm.get_node("MarginContainer/ScrollContainer/CenterContainer/VBoxContainer/MenuButtons/QuitButton")
	print("  StartButton.pressed connections =", b1.pressed.get_connections().size())
	print("  SettingsButton.pressed connections =", b2.pressed.get_connections().size())
	print("  HelpButton.pressed connections =", b3.pressed.get_connections().size())
	print("  QuitButton.pressed connections =", b4.pressed.get_connections().size())
	mm.queue_free()
	await get_tree().process_frame
