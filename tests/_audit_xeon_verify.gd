## VERIFIKASI xeon — status BUG-1 (ChoiceMenu) & BUG-2 (MainMenu QuitButton) di HEAD.
extends Node


func _ready() -> void:
	TranslationServer.set_locale("id")
	for mult in [1.0, 1.5, 2.0, 2.5]:
		await _check_main_menu(mult)
		await _check_choice(mult)
	get_tree().quit(0)


func _settle(f: int = 10) -> void:
	for i in f:
		await get_tree().process_frame


func _check_main_menu(mult: float) -> void:
	SettingsManager.font_size_multiplier = mult
	SettingsManager.save_settings()
	var mm: Node = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	add_child(mm)
	await _settle(12)
	var sc: ScrollContainer = mm.get_node("MarginContainer/ScrollContainer")
	var qb: Button = mm.get_node("MarginContainer/ScrollContainer/CenterContainer/VBoxContainer/MenuButtons/QuitButton")
	var sb: Button = mm.get_node("MarginContainer/ScrollContainer/CenterContainer/VBoxContainer/MenuButtons/StartButton")
	var bar: VScrollBar = sc.get_v_scroll_bar()
	var vmax: int = int(max(0.0, bar.max_value - bar.page))
	# Gulir ke bawah, cek QuitButton masuk penuh.
	sc.scroll_vertical = vmax
	await _settle(4)
	var sr: Rect2 = sc.get_global_rect()
	var qr: Rect2 = qb.get_global_rect()
	var reachable: bool = qr.position.y >= sr.position.y - 1.0 and qr.end.y <= sr.end.y + 1.0
	print("[main_menu x%.1f] vmax=%d scroll_h=%.0f | QuitButton rect=%s in_scroll=%s | StartButton rect=%s" % [
		mult, vmax, sc.size.y, str(qr), "TERLIHAT" if reachable else "TERPOTONG", str(sb.get_global_rect())])
	mm.queue_free()
	await get_tree().process_frame


func _check_choice(mult: float) -> void:
	SettingsManager.font_size_multiplier = mult
	SettingsManager.save_settings()
	var cm: Node = load("res://scenes/ui/choice_menu.tscn").instantiate()
	add_child(cm)
	cm.present_choices([{"text": "S03_R1_OPT_A"}, {"text": "S03_R1_OPT_B"}, {"text": "S03_R1_OPT_C"}], "normal", "")
	await _settle(10)
	var sc: ScrollContainer = cm.get_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsScroll")
	var bc: Node = sc.get_node("ButtonContainer")
	var panel: Control = cm.get_node("CenterContainer/PanelContainer")
	var bad := 0
	var sr: Rect2 = sc.get_global_rect()
	for b in bc.get_children():
		var br: Rect2 = b.get_global_rect()
		var ok: bool = br.position.y >= sr.position.y - 1.0 and br.end.y <= sr.end.y + 1.0
		if not ok:
			bad += 1
	print("[choice_menu x%.1f] panel=%s scroll_h=%.0f buttons=%d terpotong=%d" % [
		mult, str(panel.size), sc.size.y, bc.get_child_count(), bad])
	cm.queue_free()
	await get_tree().process_frame
	SettingsManager.font_size_multiplier = 1.0
	SettingsManager.save_settings()
