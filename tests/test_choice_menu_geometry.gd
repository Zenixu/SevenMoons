## Test regresi GEOMETRI ChoiceMenu (BUG-1).
##
## Regresi dari t_691aaaf0: `ButtonsScroll` (ScrollContainer) menyusut jadi 0 px
## sehingga SEMUA tombol pilihan terpotong (pemain tak bisa memilih). Uji alur
## lama hanya memanggil `_on_button_pressed(0)` langsung, tak memeriksa geometri.
##
## Uji ini menginstansiasi scene NYATA + `present_choices` 3 opsi, lalu memastikan
## SETIAP tombol:
##   1. `is_visible_in_tree()` benar, dan
##   2. `btn.get_global_rect().end.y <= scroll.get_global_rect().end.y`
##      (tombol termuat penuh di dalam viewport gulir — tidak terpotong),
## pada skala huruf 1x, 1.5x, 2x, dan 2.5x.
##
## Hanya MEMBACA/INSTANSIASI; tidak mengubah naskah/dialog/urutan.
extends Node

const CHOICE_SCENE = preload("res://scenes/ui/choice_menu.tscn")
const SCALES: Array[float] = [1.0, 1.5, 2.0, 2.5]
# Toleransi sub-piksel untuk pembulatan tata letak Godot.
const EPS: float = 0.5

var _fail: int = 0


func _ready() -> void:
	print("=== TEST: GEOMETRI CHOICEMENU (BUG-1) ===")
	TranslationServer.set_locale("id")

	var old_mult: float = SettingsManager.font_size_multiplier
	SettingsManager.high_contrast = false

	for mult in SCALES:
		await _test_three_options(mult)

	# Kasus 1 & 2 opsi juga harus tampil penuh (pemain tetap bisa memilih).
	await _test_option_count(1)
	await _test_option_count(2)

	# Opsi "diam" (teks "..."): affordance visual NON-TEKS, teks tak berubah.
	await _test_silence_affordance()

	# Panel tidak menutupi Kotak Pikiran (tak tumpang tindih) di semua skala.
	await _test_panel_above_thought_box()

	SettingsManager.font_size_multiplier = old_mult
	SettingsManager.save_settings()

	if _fail == 0:
		print("=== SEMUA TEST GEOMETRI CHOICEMENU LULUS ===")
		get_tree().quit(0)
	else:
		print("=== GAGAL: %d assertion ===" % _fail)
		get_tree().quit(1)


## 3 opsi (kasus S03) pada skala huruf `mult` — tak boleh ada tombol terpotong.
func _test_three_options(mult: float) -> void:
	print("  - 3 opsi pada font %.1fx..." % mult)
	SettingsManager.font_size_multiplier = mult
	SettingsManager.save_settings()

	var cm: ChoiceMenu = CHOICE_SCENE.instantiate()
	add_child(cm)
	await get_tree().process_frame

	var scroll: ScrollContainer = cm.get_node(
		"CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsScroll")
	var bc: VBoxContainer = scroll.get_node("ButtonContainer")

	cm.present_choices([
		{"text": "S03_R1_OPT_A"},
		{"text": "S03_R1_OPT_B"},
		{"text": "S03_R1_OPT_C"},
	], "normal", "")
	# Beri beberapa frame agar tata letak & `call_deferred` selesai.
	for _i in 6:
		await get_tree().process_frame

	_check(bc.get_child_count() == 3, "font %.1fx: harus ada 3 tombol (dapat %d)" % [mult, bc.get_child_count()])
	_check(scroll.size.y > 0.5,
		"font %.1fx: viewport gulir tak boleh 0 px (dapat %.1f)" % [mult, scroll.size.y])

	var scroll_end: float = scroll.get_global_rect().end.y
	for i in bc.get_child_count():
		var btn: Button = bc.get_child(i)
		var btn_end: float = btn.get_global_rect().end.y
		_check(btn.is_visible_in_tree(),
			"font %.1fx: tombol[%d] harus terlihat (is_visible_in_tree)" % [mult, i])
		_check(btn_end <= scroll_end + EPS,
			"font %.1fx: tombol[%d] TERPOTONG (btn_end=%.1f > scroll_end=%.1f)" % [mult, i, btn_end, scroll_end])

	cm.queue_free()
	await get_tree().process_frame


## Sejumlah `n` opsi (1/2) harus tampil penuh pada font 2x (kasus terburuk umum).
func _test_option_count(n: int) -> void:
	print("  - %d opsi pada font 2x..." % n)
	SettingsManager.font_size_multiplier = 2.0
	SettingsManager.save_settings()

	var cm: ChoiceMenu = CHOICE_SCENE.instantiate()
	add_child(cm)
	await get_tree().process_frame

	var scroll: ScrollContainer = cm.get_node(
		"CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsScroll")
	var bc: VBoxContainer = scroll.get_node("ButtonContainer")

	var opts: Array = []
	for i in n:
		opts.append({"text": "S03_R1_OPT_%s" % char(65 + i)})
	cm.present_choices(opts, "normal", "")
	for _i in 6:
		await get_tree().process_frame

	_check(bc.get_child_count() == n, "%d opsi: jumlah tombol harus %d (dapat %d)" % [n, n, bc.get_child_count()])
	var scroll_end: float = scroll.get_global_rect().end.y
	for i in bc.get_child_count():
		var btn: Button = bc.get_child(i)
		_check(btn.is_visible_in_tree(), "%d opsi: tombol[%d] harus terlihat" % [n, i])
		_check(btn.get_global_rect().end.y <= scroll_end + EPS,
			"%d opsi: tombol[%d] TERPOTONG (btn_end=%.1f > scroll_end=%.1f)" % [n, i, btn.get_global_rect().end.y, scroll_end])

	cm.queue_free()
	await get_tree().process_frame


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		printerr("    ASSERT GAGAL: " + msg)


## Opsi "diam" (teks naskah hanya titik-titik, mis. "...") harus:
##   1. TIDAK mengubah teks naskah (tetap "..."),
##   2. mendapat affordance visual NON-TEKS: gaya BEDA (pil) + ikon "bisu",
##   3. tetap tampil penuh (tidak terpotong) di 1x & 2.5x.
## Ini menjaga pemain tidak menyangka tombolnya rusak/bug (lihat
## docs/review/VERIFIKASI_KUNCI_TITIK.md).
func _test_silence_affordance() -> void:
	print("  - Opsi '...' (diam): affordance non-teks pada 1x & 2.5x...")
	for mult in [1.0, 2.5]:
		SettingsManager.font_size_multiplier = mult
		SettingsManager.save_settings()

		var cm: ChoiceMenu = CHOICE_SCENE.instantiate()
		add_child(cm)
		await get_tree().process_frame

		var scroll: ScrollContainer = cm.get_node(
			"CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsScroll")
		var bc: VBoxContainer = scroll.get_node("ButtonContainer")

		cm.present_choices([
			{"text": "S03_R1_OPT_A"},
			{"text": "S03_R1_OPT_B"},
			{"text": "S03_R1_OPT_C"},
		], "normal", "")
		for _i in 6:
			await get_tree().process_frame

		_check(bc.get_child_count() == 3,
			"silence x%.1f: harus 3 tombol (dapat %d)" % [mult, bc.get_child_count()])

		# Tombol[2] = S03_R1_OPT_C = "...". Cari tombol yang teksnya titik-titik.
		var silence_btn: Button = null
		var normal_btn: Button = null
		for i in bc.get_child_count():
			var b: Button = bc.get_child(i)
			if UITheme.is_silence_text(b.text):
				silence_btn = b
			elif normal_btn == null:
				normal_btn = b

		_check(silence_btn != null, "silence x%.1f: tombol '...' tak ditemukan" % mult)
		if silence_btn == null:
			cm.queue_free()
			await get_tree().process_frame
			continue

		# 1) Teks naskah TIDAK diubah (tetap titik-titik).
		_check(UITheme.is_silence_text(silence_btn.text),
			"silence x%.1f: teks tombol diubah (dapat '%s')" % [mult, silence_btn.text])

		# 2) Affordance non-teks: ui_kind "silence" + anak ikon vektor.
		_check(str(silence_btn.get_meta("ui_kind", "")) == "silence",
			"silence x%.1f: ui_kind bukan 'silence' (dapat '%s')" % [mult, str(silence_btn.get_meta("ui_kind", ""))])
		var icon: Node = silence_btn.get_node_or_null("SilenceIcon")
		_check(icon != null, "silence x%.1f: ikon 'bisu' tidak ada" % mult)
		if icon is Control:
			_check((icon as Control).custom_minimum_size.x > 0.0,
				"silence x%.1f: ikon berukuran 0" % mult)

		# 3) Bentuk BEDA dari tombol biasa (pil: radius jauh lebih besar).
		var sb_silence: StyleBoxFlat = silence_btn.get_theme_stylebox("normal") as StyleBoxFlat
		var sb_normal: StyleBoxFlat = normal_btn.get_theme_stylebox("normal") as StyleBoxFlat
		_check(sb_silence != null and sb_normal != null,
			"silence x%.1f: stylebox null" % mult)
		if sb_silence != null and sb_normal != null:
			_check(sb_silence.corner_radius_top_left > sb_normal.corner_radius_top_left,
				"silence x%.1f: bentuk tombol tak beda (radius %d vs %d)" % [
					mult, sb_silence.corner_radius_top_left, sb_normal.corner_radius_top_left])

		# 4) Tetap tampil penuh (tidak terpotong).
		var scroll_end: float = scroll.get_global_rect().end.y
		for i in bc.get_child_count():
			var btn: Button = bc.get_child(i)
			_check(btn.is_visible_in_tree(), "silence x%.1f: tombol[%d] tak terlihat" % [mult, i])
			_check(btn.get_global_rect().end.y <= scroll_end + EPS,
				"silence x%.1f: tombol[%d] TERPOTONG" % [mult, i])

		cm.queue_free()
		await get_tree().process_frame


## Panel ChoiceMenu tidak boleh menutupi area Kotak Pikiran (bawah 100px) pada
## skala huruf apa pun — supaya teks pilihan & monolog batin tak saling tumpang.
func _test_panel_above_thought_box() -> void:
	print("  - Panel ChoiceMenu tidak menutupi Kotak Pikiran (1x-2.5x)...")
	for mult in SCALES:
		SettingsManager.font_size_multiplier = mult
		SettingsManager.save_settings()

		var cm: ChoiceMenu = CHOICE_SCENE.instantiate()
		add_child(cm)
		for _i in 6:
			await get_tree().process_frame

		cm.present_choices([
			{"text": "S03_R1_OPT_A"},
			{"text": "S03_R1_OPT_B"},
			{"text": "S03_R1_OPT_C"},
		], "normal", "LIFT_PANEL_PROMPT")
		for _i in 8:
			await get_tree().process_frame

		var panel: Control = cm.get_node("CenterContainer/PanelContainer")
		var pr: Rect2 = panel.get_global_rect()
		# Kotak Pikiran menempati ~100px bawah (thought_box.tscn).
		var thought_top: float = 360.0 - 100.0
		_check(pr.end.y <= thought_top + EPS,
			"panel x%.1f: menutupi Kotak Pikiran (panel_end=%.0f > %.0f)" % [mult, pr.end.y, thought_top])
		_check(pr.end.y <= 360.5,
			"panel x%.1f: keluar viewport (end=%.0f)" % [mult, pr.end.y])

		cm.queue_free()
		await get_tree().process_frame
