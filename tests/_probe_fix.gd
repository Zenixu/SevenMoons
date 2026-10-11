## Eksperimen: tentukan perbaikan ChoiceMenu yang benar (runtime, tanpa edit file).
extends Node

const CHOICE := preload("res://scenes/ui/choice_menu.tscn")


func _ready() -> void:
	TranslationServer.set_locale("id")
	print("=== EKSPERIMEN FIX CHOICE MENU ===")
	await _try("BASELINE (tak diubah)", func(_cm, _panel, _scroll): pass)
	await _try("FIX A: hapus expand pada ScrollContainer", func(_cm, _panel, scroll):
		scroll.size_flags_vertical = Control.SIZE_FILL)
	await _try("FIX B: PanelContainer custom_minimum_size.y=180", func(_cm, panel, _scroll):
		panel.custom_minimum_size = Vector2(320, 180))
	await _try("FIX C: ScrollContainer custom_minimum_size.y=120", func(_cm, _panel, scroll):
		scroll.custom_minimum_size = Vector2(0, 120))
	print("=== SELESAI ===")
	get_tree().quit(0)


func _try(label: String, mutate: Callable) -> void:
	var cm: Control = CHOICE.instantiate()
	add_child(cm)
	await get_tree().process_frame
	var panel: Control = cm.get_node("CenterContainer/PanelContainer")
	var scroll: Control = cm.get_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsScroll")
	var bc: Control = scroll.get_child(0)
	mutate.call(cm, panel, scroll)
	cm.present_choices([{"text": "S03_R1_OPT_A"}, {"text": "S03_R1_OPT_B"}, {"text": "S03_R1_OPT_C"}], "normal", "")
	for i in 4:
		await get_tree().process_frame
	var clipped := 0
	for i in bc.get_child_count():
		var b: Button = bc.get_child(i)
		var br: Rect2 = b.get_global_rect()
		var sr: Rect2 = scroll.get_global_rect()
		if br.end.y > sr.end.y + 1.0:
			clipped += 1
	print("%-46s panel=%s scroll=%s btn_terpotong=%d" % [label, str(panel.size), str(scroll.size), clipped])
	cm.queue_free()
	await get_tree().process_frame
