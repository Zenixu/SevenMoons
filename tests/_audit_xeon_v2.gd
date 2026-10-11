## AUDIT xeon v2 — bedakan TERPOTONG-TAK-TERJANGKAU (bug) vs bisa-digulir (aman).
## Juga: cek apakah setelah scroll ke bawah, kontrol benar-benar terjangkau.
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
	for mult in [1.0, 2.0, 2.5]:
		for s in MENUS:
			await _probe(s, mult)
	print("\n=== RINGKASAN BUG TAK-TERJANGKAU (%d) ===" % _bugs.size())
	for b in _bugs:
		print("  * ", b)
	# Diagnostik settings_menu
	await _diag_settings()
	get_tree().quit(0)


func _spawn(path: String) -> Node:
	var ps: PackedScene = load(path)
	var n: Node = ps.instantiate()
	if "auto_start_intro" in n:
		n.set("auto_start_intro", false)
	if "auto_start" in n:
		n.set("auto_start", false)
	if "auto_start_sequence" in n:
		n.set("auto_start_sequence", false)
	add_child(n)
	return n


func _settle(frames: int = 8) -> void:
	for i in frames:
		await get_tree().process_frame


func _probe(path: String, mult: float) -> void:
	SettingsManager.font_size_multiplier = mult
	SettingsManager.save_settings()
	var n := _spawn(path)
	if n.has_method("present_choices"):
		n.present_choices([
			{"text": "S03_R1_OPT_A"}, {"text": "S03_R1_OPT_B"}, {"text": "S03_R1_OPT_C"},
		], "normal", "")
	await _settle(10)

	# Kumpulkan semua ScrollContainer di dalam menu ini.
	var scrolls: Array = []
	_collect_scroll(n, scrolls)

	# Kumpulkan kontrol penting (Button/Label/CheckBox) yang terlihat.
	var ctrls: Array = []
	_collect_ctrl(n, ctrls)

	var bad: Array[String] = []
	for c in ctrls:
		if not c.is_visible_in_tree():
			continue
		var br: Rect2 = c.get_global_rect()
		# Cari scroll ancestor
		var sc: Control = _scroll_ancestor(c, n)
		if sc != null:
			# Bisa digulir: geser ke bawah lalu cek apakah kontrol masuk viewport.
			sc.scroll_vertical = 100000
			await get_tree().process_frame
			await get_tree().process_frame
			var sr: Rect2 = sc.get_global_rect()
			var br2: Rect2 = c.get_global_rect()
			var visible_after: bool = br2.position.y >= sr.position.y - 1.0 and br2.end.y <= sr.end.y + 1.0
			sc.scroll_vertical = 0
			await get_tree().process_frame
			if not visible_after:
				# Apakah setidaknya bisa dilihat dengan menggulir? Cek max scroll.
				var vmax: float = sc.get_v_scroll_bar().max_value - sc.get_v_scroll_bar().page
				sc.scroll_vertical = int(max(0.0, vmax))
				await get_tree().process_frame
				var br3: Rect2 = c.get_global_rect()
				var ok: bool = br3.position.y >= sr.position.y - 1.0 and br3.end.y <= sr.end.y + 1.0
				sc.scroll_vertical = 0
				await get_tree().process_frame
				if not ok:
					bad.append("%s TAK-TERJANGKAU (scroll max pun tak cukup): btn=%s scroll=%s" % [
						c.get_path(), str(br3), str(sr)])
		else:
			# Tidak ada scroll ancestor -> harus muat di viewport 640x360.
			if br.end.y > 360.5 or br.position.y < -0.5 or br.end.x > 640.5 or br.position.x < -0.5:
				bad.append("%s TERPOTONG tanpa scroll: btn=%s" % [c.get_path(), str(br)])

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


func _collect_scroll(n: Node, out: Array) -> void:
	if n is ScrollContainer:
		out.append(n)
	for ch in n.get_children():
		_collect_scroll(ch, out)


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


func _diag_settings() -> void:
	print("\n=== DIAG SETTINGS MENU ===")
	SettingsManager.font_size_multiplier = 1.0
	var sm := _spawn("res://scenes/ui/settings_menu.tscn")
	await _settle(10)
	var root_path := "MarginContainer/ScrollContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer"
	for p in ["/TitleLabel", "/TabContainer/Audio/BgmRow/Label", "/TabContainer/Audio/SfxRow/Label",
			"/TabContainer/Gameplay/TextSpeedRow/Label", "/TabContainer/A11y/FontSizeRow/Label",
			"/TabContainer/Gameplay/SkipSensitiveCheck", "/TabContainer/A11y/HighContrastCheck",
			"/ButtonRow/ResetButton", "/ButtonRow/CloseButton"]:
		var node: Node = sm.get_node_or_null(root_path + p)
		if node == null:
			print("  MISSING: ", p)
		else:
			var t: String = str(node.get("text")) if "text" in node else "(no text)"
			print("  %-52s text=%s visible=%s size=%s" % [p, JSON.stringify(t), str(node.is_visible_in_tree()) if node is CanvasItem else "?", str(node.size) if node is Control else "?"])
	print("  tr(SETTINGS_BGM_VOL)=", JSON.stringify(tr("SETTINGS_BGM_VOL")))
	print("  tr(UI_CLOSE)=", JSON.stringify(tr("UI_CLOSE")))
	print("  tab0 title=", JSON.stringify(sm.get_node(root_path + "/TabContainer").get_tab_title(0)))
	sm.queue_free()
	await get_tree().process_frame
