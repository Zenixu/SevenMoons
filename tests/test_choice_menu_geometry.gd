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
