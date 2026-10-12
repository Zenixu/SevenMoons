## ChoiceMenu — UI Menu Pilihan
## Menampilkan daftar pilihan dialog/tindakan.
## Mendukung mode:
## - "normal": pilihan langsung muncul
## - "convergent": pilihan konvergen (semua menuju alur yang sama)
## - "hesitant": pilihan tertunda dan ragu (muncul bertahap, pilihan jujur lebih
##   lambat & lebih redup)
##
## Aksesibilitas: huruf mengikuti "Ukuran Huruf"/"Kontras Tinggi". Pilihan
## "jujur" dibedakan juga lewat BENTUK (kotak tanpa isi / outline-only), bukan
## warna saja (MECHANICS_SPEC §2 & §10).
##
## Pilihan "diam" (teks naskah "...") TIDAK diubah teksnya. Supaya tidak
## disangka tombol rusak, tombolnya diberi affordance visual: bentuk PIL
## (radius penuh) + latar redup + ikon "bisu" (pengeras suara dicoret).
## Panel juga dijaga tetap di area atas agar tidak menutupi Kotak Pikiran
## pada skala huruf besar (1x–2.5x).
class_name ChoiceMenu
extends Control

signal choice_made(index: int)

@onready var container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer
@onready var prompt_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PromptLabel
@onready var buttons_scroll: ScrollContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsScroll
@onready var button_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsScroll/ButtonContainer

const BASE_FONT_SIZE: int = 11
# Tinggi minimum ScrollContainer (px). Konten yang lebih tinggi akan menaikkan
# nilainya saat runtime; ini hanya lantai agar panel tak pernah menciut ke 0.
const MIN_SCROLL_HEIGHT: float = 44.0
# Ukuran dasar ikon "bisu" (px) untuk opsi "diam"; ikut skala huruf saat runtime.
const ICON_BASE_SIZE: int = 14

var _options: Array = []
var _mode: String = "normal"
var _buttons: Array[Button] = []
var _is_presenting: bool = false


func _ready() -> void:
	visible = false
	$CenterContainer/PanelContainer.set_meta("ui_hc", true)
	UITheme.bind(self)
	if DialogueRunner.choice_requested.is_connected(present_choices):
		return
	DialogueRunner.choice_requested.connect(present_choices)
	# Bila skala huruf berubah saat menu terbuka, tinggi tombol ikut berubah:
	# sesuaikan lagi viewport gulir agar tetap tak ada tombol terpotong.
	var sm: Node = UITheme._settings()
	if sm != null and sm.has_signal("settings_changed"):
		sm.connect("settings_changed", _on_settings_changed)


func _on_settings_changed() -> void:
	if visible:
		_fit_scroll_to_content()


func present_choices(options: Array, mode: String = "normal", prompt_text: String = "") -> void:
	_options = options
	_mode = mode
	_buttons.clear()
	_clear_buttons()

	if prompt_text.is_empty():
		prompt_label.visible = false
	else:
		prompt_label.visible = true
		prompt_label.text = tr(prompt_text)

	visible = true

	if mode == "hesitant" and not SettingsManager.no_time_pressure:
		_present_hesitant(options)
	else:
		_present_immediate(options)


## Tinggi maksimum area panel agar tetap berada di atas Kotak Pikiran.
## ChoiceMenu memakai area layar bagian ATAS (lihat offset `CenterContainer` di
## choice_menu.tscn: atas 8px, bawah -112px untuk Kotak Pikiran), jadi tingginya
## dibatasi oleh tinggi CenterContainer itu sendiri.
func _max_panel_height() -> float:
	var cc: Control = get_node_or_null("CenterContainer") as Control
	var h: float = size.y
	if cc != null and cc.size.y > 1.0:
		h = cc.size.y
	return maxf(MIN_SCROLL_HEIGHT, h - 12.0)


## Sesuaikan tinggi viewport gulir dengan konten tombol agar SEMUA opsi tampil
## penuh (tidak terpotong). Konten tetap bisa digulir bila melebihi layar.
func _fit_scroll_to_content() -> void:
	if buttons_scroll == null:
		return
	var content_h: float = button_container.get_combined_minimum_size().y
	# Tinggi maksimum yang boleh dipakai scroll = tinggi panel maks dikurangi
	# prompt + margin + separation, agar panel tak menutupi Kotak Pikiran.
	var overhead: float = 0.0
	if prompt_label != null and prompt_label.visible:
		overhead += prompt_label.get_combined_minimum_size().y
		overhead += 8.0  # separation VBox
	overhead += 24.0     # margin atas+bawah panel
	var max_scroll: float = maxf(MIN_SCROLL_HEIGHT, _max_panel_height() - overhead)
	buttons_scroll.custom_minimum_size = Vector2(0, clampf(content_h, MIN_SCROLL_HEIGHT, max_scroll))


func _present_immediate(options: Array) -> void:
	for i in options.size():
		var btn: Button = _create_choice_button(i, options[i])
		button_container.add_child(btn)
		_buttons.append(btn)

	if _buttons.size() > 0:
		_buttons[0].grab_focus()

	_fit_scroll_to_content()
	# Konten tombol baru terukur penuh setelah satu frame tata letak; sesuaikan lagi.
	call_deferred("_fit_scroll_to_content")


func _present_hesitant(options: Array) -> void:
	_is_presenting = true
	# Di mode hesitant:
	# Pilihan "aman" (awal) muncul lebih cepat dan terang.
	# Pilihan "jujur" (belakang) muncul bertahap (jeda) dan lebih redup —
	# dibedakan juga lewat bentuk kotak (outline-only), bukan warna saja.
	for i in options.size():
		if not visible:
			return
		var btn: Button = _create_choice_button(i, options[i], i > 0)
		button_container.add_child(btn)
		_buttons.append(btn)

		if i == 0:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			btn.grab_focus()
		else:
			btn.modulate = Color(1.0, 1.0, 1.0, 0.0)
			var tw := create_tween()
			tw.tween_property(btn, "modulate:a", 0.85, 0.5)

		# Jeda bertahap antar opsi (MECHANICS_SPEC §2)
		if i < options.size() - 1:
			var delay: float = 1.0 / maxf(0.5, SettingsManager.text_speed)
			await get_tree().create_timer(delay).timeout

	_fit_scroll_to_content()
	_is_presenting = false


func _create_choice_button(index: int, opt: Variant, is_honest: bool = false) -> Button:
	var btn := Button.new()
	var text_key: String = ""
	if opt is Dictionary:
		text_key = opt.get("text", "")
	elif opt is String:
		text_key = opt

	btn.text = tr(text_key)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.custom_minimum_size = Vector2(280, 32)
	btn.focus_mode = FOCUS_ALL

	# Ukuran huruf DASAR idempoten (aman bila `apply()` berjalan lagi saat
	# pengaturan berubah, tanpa menggandakan skala).
	UITheme.set_base_font_size(btn, BASE_FONT_SIZE)

	# Opsi "diam" (teks naskah hanya titik-titik, mis. "..."): jangan ubah teks,
	# tapi beri affordance visual NON-TEKS supaya tidak tampak seperti tombol rusak.
	var is_silence: bool = UITheme.is_silence_text(btn.text)

	# Pilihan jujur: kotak outline-only (bentuk beda), bukan hanya lebih redup.
	# Pilihan "diam": bentuk PIL + ikon bisu (lihat _apply_button_style).
	var kind: String = "normal"
	if is_silence:
		kind = "silence"
	elif is_honest:
		kind = "honest"
	btn.set_meta("ui_kind", kind)

	if is_silence:
		_add_silence_affordance(btn)

	_apply_button_style(btn, kind)
	btn.pressed.connect(func() -> void: _on_button_pressed(index))
	return btn


## Tambahkan ikon "bisu" (vektor, bukan huruf) sebagai anak tombol "diam",
## sehingga tombol tak hanya berisi "..." yang mudah disangka teks hilang.
func _add_silence_affordance(btn: Button) -> void:
	var icon_size: int = maxi(10, int(round(float(ICON_BASE_SIZE) * UITheme.multiplier())))
	var icon: Control = UITheme.make_silence_icon(icon_size)
	icon.anchor_left = 0.0
	icon.anchor_top = 0.5
	icon.anchor_right = 0.0
	icon.anchor_bottom = 0.5
	icon.offset_left = 10.0
	icon.offset_right = 10.0 + float(icon_size)
	icon.offset_top = -float(icon_size) * 0.5
	icon.offset_bottom = float(icon_size) * 0.5
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon)
	# Beri sedikit ruang kiri supaya ikon tidak menimpa teks di tengah.
	btn.add_theme_constant_override("h_separation", 6)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER


func _apply_button_style(btn: Button, kind: String) -> void:
	# Gaya langsung (tombol dibuat runtime, di luar sapuan UITheme.bind saat _ready).
	if SettingsManager.high_contrast:
		var sb: StyleBoxFlat = UITheme.button_style_hc(kind)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_color_override("font_color", UITheme.HC_TEXT)
	else:
		btn.add_theme_stylebox_override("normal", UITheme.button_style(kind))
		btn.add_theme_stylebox_override("hover", UITheme.button_style("accent"))
		btn.add_theme_stylebox_override("pressed", UITheme.button_style("accent"))
		if kind == "silence":
			btn.add_theme_color_override("font_color", UITheme.SILENCE_TEXT)


func _on_button_pressed(index: int) -> void:
	visible = false
	_clear_buttons()
	choice_made.emit(index)
	DialogueRunner.submit_choice(index)


func _clear_buttons() -> void:
	for child in button_container.get_children():
		child.queue_free()
	_buttons.clear()
