## ChatBubble — UI Komponen Gelembung Chat
## Menampilkan pesan masuk atau keluar dalam antarmuka ponsel/chat.
##
## Aksesibilitas: huruf mengikuti "Ukuran Huruf"; "Kontras Tinggi" memberi
## kotak hitam + bingkai putih. Arah pesan (kiri/kanan) tetap menjadi pembeda
## NON-WARNA antara pesan pemain dan lawan bicara (MECHANICS_SPEC §10).
class_name ChatBubble
extends MarginContainer

const BASE_MSG_SIZE: int = 12
const BASE_SENDER_SIZE: int = 10

@onready var panel: PanelContainer = $PanelContainer
@onready var sender_label: Label = $PanelContainer/MarginContainer/VBoxContainer/SenderLabel
@onready var message_label: Label = $PanelContainer/MarginContainer/VBoxContainer/MessageLabel

var is_player: bool = false


func setup(sender_name: String, message_text: String, is_sent_by_player: bool) -> void:
	is_player = is_sent_by_player

	if sender_name.is_empty():
		sender_label.visible = false
	else:
		sender_label.visible = true
		sender_label.text = sender_name

	message_label.text = message_text

	# Arah = pembeda utama (bukan warna saja).
	if is_sent_by_player:
		size_flags_horizontal = Control.SIZE_SHRINK_END
	else:
		size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	_apply_style()


func _apply_style() -> void:
	# Pakai dasar idempoten: aman bila `_apply_style` dipanggil ulang (mis. saat
	# pengaturan berubah) tanpa menggandakan skala huruf.
	UITheme.set_base_font_size(message_label, BASE_MSG_SIZE)
	UITheme.set_base_font_size(sender_label, BASE_SENDER_SIZE)

	if SettingsManager.high_contrast:
		var sb := StyleBoxFlat.new()
		sb.bg_color = UITheme.HC_BG
		sb.border_color = UITheme.HC_BORDER
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		panel.add_theme_stylebox_override("panel", sb)
		message_label.add_theme_color_override("font_color", UITheme.HC_TEXT)
		sender_label.add_theme_color_override("font_color", UITheme.HC_ACCENT)
	else:
		panel.add_theme_stylebox_override("panel", UITheme.button_style("accent" if is_player else "normal"))
		message_label.add_theme_color_override("font_color", UITheme.TEXT)
		sender_label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
