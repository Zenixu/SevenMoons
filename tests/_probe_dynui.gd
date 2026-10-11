## Probe UI dinamis: chat_ui (MessageList) & thought_box — cek tinggi 0 / terpotong.
extends Node

const CHAT := preload("res://scenes/ui/chat_ui.tscn")
const THOUGHT := preload("res://scenes/ui/thought_box.tscn")


func _ready() -> void:
	TranslationServer.set_locale("id")
	print("=== PROBE UI DINAMIS ===")

	# --- ThoughtBox ---
	var tb: Control = THOUGHT.instantiate()
	add_child(tb)
	await get_tree().process_frame
	if tb.has_method("show_text"):
		tb.show_text("S02_O1_A02")
	elif tb.has_method("show"):
		tb.show()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	print("[ThoughtBox] visible=", tb.visible, " size=", tb.size)
	var rtl := tb.get_node_or_null("PanelContainer/MarginContainer/ScrollContainer/RichTextLabel")
	if rtl: print("  RichTextLabel size=", rtl.size, " visible_in_tree=", rtl.is_visible_in_tree())
	tb.queue_free()
	await get_tree().process_frame

	# --- ChatUI ---
	var ch: Control = CHAT.instantiate()
	add_child(ch)
	await get_tree().process_frame
	# coba API umum
	for m in ["add_message", "append_message", "add_bubble", "push_message"]:
		if ch.has_method(m):
			print("  chat method tersedia:", m)
	# tambah beberapa pesan via signal/step bila ada
	var list := ch.get_node_or_null("Panel/MarginContainer/VBoxContainer/ScrollContainer/MessageList")
	var scroll := ch.get_node_or_null("Panel/MarginContainer/VBoxContainer/ScrollContainer")
	if list and scroll:
		# buat 4 bubble palsu
		for i in 4:
			var lbl := Label.new()
			lbl.text = "Pesan uji %d — teks cukup panjang untuk menguji tinggi." % i
			list.add_child(lbl)
		await get_tree().process_frame
		await get_tree().process_frame
		print("[ChatUI] scroll size=", scroll.size, " list size=", list.size, " min=", list.get_combined_minimum_size())
		print("  list children=", list.get_child_count())

	print("=== PROBE SELESAI ===")
	get_tree().quit(0)
