## Probe runtime ChoiceMenu — ukur tiap node & uji 3 opsi (kasus nyata S03).
extends Node

const CHOICE := preload("res://scenes/ui/choice_menu.tscn")


func _ready() -> void:
	TranslationServer.set_locale("id")
	print("=== PROBE CHOICE MENU v2 ===")
	var cm := CHOICE.instantiate()
	add_child(cm)
	await get_tree().process_frame
	await get_tree().process_frame

	# 3 opsi seperti S03 (convergent) — pakai kunci NYATA
	var opts: Array = [
		{"text": "S03_R1_OPT_A"},
		{"text": "S03_R1_OPT_B"},
		{"text": "S03_R1_OPT_C"},
	]
	cm.present_choices(opts, "normal", "")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var panel: Control = cm.get_node("CenterContainer/PanelContainer")
	var vbox: Control = cm.get_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer")
	var scroll: Control = cm.get_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsScroll")
	var bc: Control = cm.get_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsScroll/ButtonContainer")
	print("panel  size=", panel.size, " min=", panel.get_combined_minimum_size())
	print("vbox   size=", vbox.size, " min=", vbox.get_combined_minimum_size())
	print("scroll size=", scroll.size, " min=", scroll.get_combined_minimum_size())
	print("bc     size=", bc.size, " min=", bc.get_combined_minimum_size())
	print("bc children=", bc.get_child_count())
	var total_btn := 0.0
	for i in bc.get_child_count():
		var b: Button = bc.get_child(i)
		total_btn += b.custom_minimum_size.y
		print("  btn[%d] text='%s' size=%s visible_in_tree=%s" % [i, b.text, str(b.size), str(b.is_visible_in_tree())])
	print("tinggi total tombol = ", total_btn, " + separation = ", (bc.get_child_count()-1)*6)
	print(">>> scroll viewport height = ", scroll.size.y, " ; isi butuh = ", total_btn + (bc.get_child_count()-1)*6)

	# Apakah tombol terlihat penuh? bandingkan rect global tombol dgn panel
	for i in bc.get_child_count():
		var b: Button = bc.get_child(i)
		var gr := b.get_global_rect()
		var pr := panel.get_global_rect()
		var clipped := gr.end.y > pr.end.y + 0.5
		print("  btn[%d] global_y=%.1f..%.1f  panel_y=%.1f..%.1f  TERPOTONG=%s" % [i, gr.position.y, gr.end.y, pr.position.y, pr.end.y, str(clipped)])

	print("=== PROBE SELESAI ===")
	get_tree().quit(0)
