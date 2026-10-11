## KONFIRMASI xeon — (1) bug label SettingsMenu (_set_label path ganda),
## (2) kunci "..." yang benar-benar tampil sebagai opsi pilihan.
extends Node


func _ready() -> void:
	TranslationServer.set_locale("id")
	await _confirm_settings()
	await _confirm_dots()
	get_tree().quit(0)


func _settle(f: int = 10) -> void:
	for i in f:
		await get_tree().process_frame


func _confirm_settings() -> void:
	print("=== KONFIRMASI BUG-5: label SettingsMenu kosong ===")
	SettingsManager.font_size_multiplier = 1.0
	var sm: Node = load("res://scenes/ui/settings_menu.tscn").instantiate()
	add_child(sm)
	await _settle(12)
	var root: String = sm._ROOT
	# Path yang DIPAKAI _set_label = _ROOT + (argumen) ; argumen sudah mengandung _ROOT.
	var doubled: String = root + "/" + root + "/TabContainer/Audio/BgmRow/Label"
	print("  _ROOT                       = ", root)
	print("  path lookup _set_label (ganda) = ", doubled)
	print("  get_node_or_null(ganda)     = ", str(sm.get_node_or_null(doubled)), "  <-- NULL = no-op")
	print("  path yang BENAR             = ", root + "/TabContainer/Audio/BgmRow/Label")
	print("  get_node_or_null(benar)     = ", str(sm.get_node_or_null(root + "/TabContainer/Audio/BgmRow/Label")))
	print("  -- hasil akhir text tiap label --")
	for p in ["/TabContainer/Audio/BgmRow/Label", "/TabContainer/Audio/SfxRow/Label",
			"/TabContainer/Audio/AmbRow/Label", "/TabContainer/Gameplay/TextSpeedRow/Label",
			"/TabContainer/A11y/FontSizeRow/Label"]:
		var n: Label = sm.get_node(root + p)
		print("     %-46s text=%s  (harusnya %s)" % [p.get_file(), JSON.stringify(n.text), JSON.stringify(tr(_key_for(p)))])
	sm.queue_free()
	await get_tree().process_frame


func _key_for(p: String) -> String:
	match p:
		"/TabContainer/Audio/BgmRow/Label": return "SETTINGS_BGM_VOL"
		"/TabContainer/Audio/SfxRow/Label": return "SETTINGS_SFX_VOL"
		"/TabContainer/Audio/AmbRow/Label": return "SETTINGS_AMBIENCE_VOL"
		"/TabContainer/Gameplay/TextSpeedRow/Label": return "SETTINGS_TEXT_SPEED"
		"/TabContainer/A11y/FontSizeRow/Label": return "SETTINGS_FONT_SIZE"
	return "?"


func _confirm_dots() -> void:
	print("\n=== KONFIRMASI BUG-3: kunci id.csv bernilai \"...\" ===")
	var keys: Array[String] = ["S01_N01", "S02_O1_A01", "S03_R1_OPT_C", "S03_R3_OPT_A", "ROOFTOP_WALK_2"]
	for k in keys:
		print("  tr(%-16s) = %s" % [k, JSON.stringify(tr(k))])
	print("  -- tampil sebagai opsi ChoiceMenu? --")
	var cm: Node = load("res://scenes/ui/choice_menu.tscn").instantiate()
	add_child(cm)
	await _settle(4)
	cm.present_choices([{"text": "S03_R1_OPT_A"}, {"text": "S03_R1_OPT_B"}, {"text": "S03_R1_OPT_C"}], "normal", "")
	await _settle(8)
	var bc: Node = cm.get_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsScroll/ButtonContainer")
	for b in bc.get_children():
		print("     tombol pilihan: text=%s visible=%s" % [JSON.stringify(b.text), str(b.is_visible_in_tree())])
	cm.queue_free()
	await get_tree().process_frame
