## Test scene untuk seluruh UI Inti (Fase 2)
## Menguji ThoughtBox, ChatSystem, ChoiceMenu, ContentWarning, SettingsMenu, HelpMenu, MainMenu
extends Node

const THOUGHT_BOX_SCENE = preload("res://scenes/ui/thought_box.tscn")
const CHAT_UI_SCENE = preload("res://scenes/ui/chat_ui.tscn")
const CHOICE_MENU_SCENE = preload("res://scenes/ui/choice_menu.tscn")
const CONTENT_WARNING_SCENE = preload("res://scenes/ui/content_warning.tscn")
const SETTINGS_MENU_SCENE = preload("res://scenes/ui/settings_menu.tscn")
const HELP_MENU_SCENE = preload("res://scenes/ui/help_menu.tscn")
const MAIN_MENU_SCENE = preload("res://scenes/main_menu/main_menu.tscn")


func _ready() -> void:
	print("=== TEST: UI INTI (FASE 2) ===")
	TranslationServer.set_locale("id")

	await _test_thought_box()
	await _test_chat_system()
	await _test_choice_menu()
	await _test_content_warning()
	await _test_help_menu()
	await _test_settings_menu()
	await _test_main_menu()

	print("=== SEMUA TEST UI INTI LULUS ===")


func _test_thought_box() -> void:
	print("  - Menguji ThoughtBox...")
	var tb: ThoughtBox = THOUGHT_BOX_SCENE.instantiate()
	add_child(tb)

	# Uji pengetikan
	var completed_ctx: Dictionary = {"done": false}
	tb.text_completed.connect(func() -> void: completed_ctx["done"] = true)
	tb.display_thought("Hujan di luar belum berhenti.")
	tb.complete_immediately()
	assert(completed_ctx["done"] == true, "ThoughtBox: complete_immediately gagal")
	assert(tb.label.text.contains("Hujan"), "ThoughtBox: teks tidak cocok")

	# Uji penghapusan
	var erased_ctx: Dictionary = {"done": false}
	tb.text_erased.connect(func() -> void: erased_ctx["done"] = true)
	tb.erase_thought(500.0)
	await tb.text_erased
	assert(erased_ctx["done"] == true, "ThoughtBox: text_erased signal gagal dipancarkan")
	assert(tb.label.text == "", "ThoughtBox: erase_thought gagal mengosongkan teks")

	tb.clear()
	tb.queue_free()
	print("    ThoughtBox: OK")


func _test_chat_system() -> void:
	print("  - Menguji ChatSystem...")
	var chat: ChatSystem = CHAT_UI_SCENE.instantiate()
	add_child(chat)

	# Uji pengiriman pesan
	var msg_ctx: Dictionary = {"displayed": false, "sender": "", "text": ""}
	chat.message_displayed.connect(func(s: String, t: String) -> void:
		msg_ctx["displayed"] = true
		msg_ctx["sender"] = s
		msg_ctx["text"] = t
	)

	# Ubah kecepatan teks sementara agar test berjalan cepat
	var old_speed: float = SettingsManager.text_speed
	SettingsManager.text_speed = 10.0

	await chat.post_message("Ibu", "Kamu sudah makan?", false)
	assert(msg_ctx["displayed"] == true, "ChatSystem: post_message gagal memancarkan sinyal")
	assert(msg_ctx["sender"] == "Ibu", "ChatSystem: nama pengirim salah")

	# Uji pesan dibatalkan
	var cancel_ctx: Dictionary = {"cancelled": false}
	chat.message_cancelled.connect(func(_s: String) -> void: cancel_ctx["cancelled"] = true)
	await chat.post_cancelled_message("Arutala", "Aku mau minta tolong...", true)
	assert(cancel_ctx["cancelled"] == true, "ChatSystem: post_cancelled_message gagal memancarkan sinyal")

	SettingsManager.text_speed = old_speed
	chat.clear_messages()
	chat.queue_free()
	print("    ChatSystem: OK")


func _test_choice_menu() -> void:
	print("  - Menguji ChoiceMenu...")
	var menu: ChoiceMenu = CHOICE_MENU_SCENE.instantiate()
	add_child(menu)

	var choice_ctx: Dictionary = {"chosen_index": -1}
	menu.choice_made.connect(func(idx: int) -> void:
		choice_ctx["chosen_index"] = idx
	)

	# Uji mode normal
	var options: Array = [
		{"text": "Pilihan A"},
		{"text": "Pilihan B"}
	]
	menu.present_choices(options, "normal")
	assert(menu.visible == true, "ChoiceMenu: tidak visible")
	assert(menu._buttons.size() == 2, "ChoiceMenu: jumlah tombol salah")

	# Simulasikan klik pilihan 1
	menu._buttons[1].emit_signal("pressed")
	assert(choice_ctx["chosen_index"] == 1, "ChoiceMenu: index pilihan salah")
	assert(menu.visible == false, "ChoiceMenu: seharusnya sembunyi setelah memilih")

	menu.queue_free()
	print("    ChoiceMenu: OK")


func _test_content_warning() -> void:
	print("  - Menguji ContentWarning...")
	var cw: ContentWarning = CONTENT_WARNING_SCENE.instantiate()
	add_child(cw)

	var ack_ctx: Dictionary = {"acked": false}
	cw.warning_acknowledged.connect(func() -> void: ack_ctx["acked"] = true)

	assert(cw.title_label.text == tr("CW_TITLE"), "ContentWarning: judul salah")
	assert(cw.desc_label.text == tr("CW_DESC"), "ContentWarning: deskripsi salah")

	cw.proceed_button.emit_signal("pressed")
	assert(ack_ctx["acked"] == true, "ContentWarning: tombol lanjutkan gagal memancarkan sinyal")

	cw.queue_free()
	print("    ContentWarning: OK")


func _test_help_menu() -> void:
	print("  - Menguji HelpMenu...")
	var hm: HelpMenu = HELP_MENU_SCENE.instantiate()
	add_child(hm)

	assert(hm.title_label.text == tr("HELP_TITLE"), "HelpMenu: judul salah")
	assert(hm.item2_label.text.contains("119"), "HelpMenu: nomor 119 tidak ditemukan")
	assert(hm.item3_label.text.contains("intothelightid.org"), "HelpMenu: Into The Light tidak ditemukan")

	var closed_ctx: Dictionary = {"closed": false}
	hm.closed.connect(func() -> void: closed_ctx["closed"] = true)
	hm.close_button.emit_signal("pressed")
	assert(closed_ctx["closed"] == true, "HelpMenu: tombol tutup gagal memancarkan sinyal")

	hm.queue_free()
	print("    HelpMenu: OK")


func _test_settings_menu() -> void:
	print("  - Menguji SettingsMenu...")
	var sm: SettingsMenu = SETTINGS_MENU_SCENE.instantiate()
	add_child(sm)

	# Uji sinkronisasi nilai
	sm.open()
	sm.bgm_slider.value = 0.4
	sm.bgm_slider.value_changed.emit(0.4)
	assert(is_equal_approx(SettingsManager.volume_bgm, 0.4), "SettingsMenu: sinkron BGM gagal")

	sm.skip_sensitive_check.button_pressed = true
	sm.skip_sensitive_check.toggled.emit(true)
	assert(SettingsManager.skip_sensitive_scenes == true, "SettingsMenu: toggle skip adegan sensitif gagal")

	sm.reset_button.emit_signal("pressed")
	assert(SettingsManager.skip_sensitive_scenes == false, "SettingsMenu: reset gagal")

	sm.queue_free()
	print("    SettingsMenu: OK")


func _test_main_menu() -> void:
	print("  - Menguji MainMenu...")
	var mm: MainMenu = MAIN_MENU_SCENE.instantiate()
	add_child(mm)

	var start_ctx: Dictionary = {"started": false}
	mm.start_game_requested.connect(func() -> void: start_ctx["started"] = true)
	mm.start_button.emit_signal("pressed")
	assert(start_ctx["started"] == true, "MainMenu: start_game_requested gagal")

	mm.settings_button.emit_signal("pressed")
	assert(mm.settings_menu.visible == true, "MainMenu: buka settings modal gagal")

	mm.help_button.emit_signal("pressed")
	assert(mm.help_menu.visible == true, "MainMenu: buka help modal gagal")

	mm.queue_free()
	print("    MainMenu: OK")
