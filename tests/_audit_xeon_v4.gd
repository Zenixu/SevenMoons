## AUDIT xeon v4 — (a) label settings per-tab, (b) apakah teks tinggi bisa digulir
## sampai bawah (bukan sekadar "tak muat sekaligus").
extends Node


func _ready() -> void:
	TranslationServer.set_locale("id")
	await _settings_labels()
	await _scroll_bottom_reachable()
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


func _settings_labels() -> void:
	print("=== LABEL SETTINGS PER-TAB (font 1x) ===")
	SettingsManager.font_size_multiplier = 1.0
	var sm := _spawn("res://scenes/ui/settings_menu.tscn")
	await _settle(12)
	var root := "MarginContainer/ScrollContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer"
	var tc: TabContainer = sm.get_node(root + "/TabContainer")
	var rows := {
		0: ["/TabContainer/Audio/BgmRow/Label", "/TabContainer/Audio/SfxRow/Label", "/TabContainer/Audio/AmbRow/Label"],
		1: ["/TabContainer/Gameplay/TextSpeedRow/Label", "/TabContainer/Gameplay/SkipSensitiveCheck", "/TabContainer/Gameplay/NoTimePressureCheck"],
		2: ["/TabContainer/A11y/FontSizeRow/Label", "/TabContainer/A11y/HighContrastCheck", "/TabContainer/A11y/ReduceFlashCheck"],
	}
	for i in rows.keys():
		tc.current_tab = i
		await _settle(6)
		print("  -- tab %d (%s) --" % [i, tc.get_tab_title(i)])
		for p in rows[i]:
			var node: Node = sm.get_node_or_null(root + p)
			if node == null:
				print("     MISSING ", p)
			else:
				var t: String = str(node.get("text"))
				print("     %-48s visible=%-5s text=%s" % [p.get_file(), str(node.is_visible_in_tree()), JSON.stringify(t)])
	print("  TabContainer titles:", JSON.stringify(tc.get_tab_title(0)), JSON.stringify(tc.get_tab_title(1)), JSON.stringify(tc.get_tab_title(2)))
	# Cek apa yang sebenarnya di-resolve _set_label
	print("  _ROOT =", JSON.stringify(sm._ROOT))
	print("  node di _ROOT+_ROOT (bug?) ada? ", sm.get_node_or_null(sm._ROOT + "/TabContainer/Audio/BgmRow/Label") != null)
	sm.queue_free()
	await get_tree().process_frame


func _scroll_bottom_reachable() -> void:
	print("\n=== TEKS TINGGI: bisakah digulir sampai BAWAH? ===")
	for mult in [1.0, 2.0, 2.5]:
		SettingsManager.font_size_multiplier = mult
		SettingsManager.save_settings()
		for path in ["res://scenes/ui/content_warning.tscn", "res://scenes/ui/help_menu.tscn"]:
			var n := _spawn(path)
			await _settle(12)
			var scrolls: Array = []
			_collect_scroll(n, scrolls)
			for sco in scrolls:
				var sc: ScrollContainer = sco
				var bar: VScrollBar = sc.get_v_scroll_bar()
				var vmax: float = max(0.0, bar.max_value - bar.page)
				var child_h: float = 0.0
				for ch in sc.get_children():
					if ch is Control:
						child_h = max(child_h, (ch as Control).size.y)
				var needed: float = max(0.0, child_h - sc.size.y)
				var ok: bool = vmax + 1.0 >= needed
				print("  [%s x%.1f] %s viewport_h=%.0f child_h=%.0f vmax=%.0f needed=%.0f -> %s" % [
					path.get_file(), mult, sc.name, sc.size.y, child_h, vmax, needed, "OK" if ok else "TAK-BISA-GULIR-PENUH"])
			n.queue_free()
			await get_tree().process_frame
		SettingsManager.font_size_multiplier = 1.0
		SettingsManager.save_settings()


func _collect_scroll(n: Node, out: Array) -> void:
	if n is ScrollContainer:
		out.append(n)
	for ch in n.get_children():
		_collect_scroll(ch, out)
