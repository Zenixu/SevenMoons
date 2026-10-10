## ThoughtBox — UI Kotak Pikiran
## Menampilkan monolog batin Arutala.
## Mendukung efek typewriter, hapus huruf per huruf (efek kecemasan),
## dan jeda sesuai spesifikasi.
class_name ThoughtBox
extends Control

signal text_completed()
signal text_erased()

@onready var panel_container: PanelContainer = $PanelContainer
@onready var label: RichTextLabel = $PanelContainer/MarginContainer/RichTextLabel

var _current_text: String = ""
var _is_typing: bool = false
var _is_erasing: bool = false
var _tween: Tween
var _tick_accum: float = 0.0
var _last_tick_char: int = -1


func _ready() -> void:
	if label:
		label.text = ""
	if panel_container:
		panel_container.visible = false   # kotak latar sembunyi saat tak ada teks
	set_process(true)
	_apply_accessibility()
	if not SettingsManager.settings_changed.is_connected(_apply_accessibility):
		SettingsManager.settings_changed.connect(_apply_accessibility)


## Tampilkan/sembunyikan kotak latar agar tidak mengganggu saat berjalan & idle.
func _set_panel_visible(show: bool) -> void:
	if panel_container == null:
		return
	if show:
		panel_container.visible = true
		panel_container.modulate = Color(1, 1, 1, 1)
	else:
		panel_container.visible = false


## Bunyi ketikan: satu tick tiap beberapa karakter yang muncul (bukan tiap
## frame), agar tidak berisik namun tetap terasa seperti menulis.
func _process(delta: float) -> void:
	if not _is_typing or label == null:
		return
	_tick_accum += delta
	if _tick_accum < 0.045:
		return
	_tick_accum = 0.0
	var shown: int = label.visible_characters
	if shown != _last_tick_char:
		_last_tick_char = shown
		if shown % 2 == 0:
			AudioManager.play_type_tick()


func _apply_accessibility() -> void:
	if not is_inside_tree() or label == null:
		return
	var base_size: int = 11
	var font_sz: int = int(round(base_size * SettingsManager.font_size_multiplier))
	label.add_theme_font_size_override("normal_font_size", font_sz)

	if SettingsManager.high_contrast:
		label.add_theme_color_override("default_color", Color(1.0, 1.0, 1.0, 1.0))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.0, 0.0, 0.0, 0.96)
		sb.border_color = Color(1.0, 1.0, 1.0, 1.0)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(3)
		panel_container.add_theme_stylebox_override("panel", sb)
	else:
		label.remove_theme_color_override("default_color")
		panel_container.remove_theme_stylebox_override("panel")


## Menampilkan teks dengan efek mengetik perlahan
func display_thought(text_key_or_literal: String, typing_speed_cps: float = 25.0) -> void:
	var final_text: String = tr(text_key_or_literal)
	_current_text = final_text
	_is_typing = true
	_tick_accum = 0.0
	_last_tick_char = -1
	label.text = final_text
	label.visible_characters = 0
	_set_panel_visible(true)

	if _tween and _tween.is_valid():
		_tween.kill()

	var speed_multiplier: float = maxf(0.2, SettingsManager.text_speed)
	var duration: float = float(final_text.length()) / (typing_speed_cps * speed_multiplier)
	duration = clampf(duration, 0.5, 8.0)

	_tween = create_tween()
	_tween.tween_property(label, "visible_characters", final_text.length(), duration)
	_tween.finished.connect(_on_typing_finished)


func _on_typing_finished() -> void:
	_is_typing = false
	text_completed.emit()


## Efek ragu/cemas: menghapus teks yang baru diketik huruf demi huruf
func erase_thought(erase_speed_cps: float = 35.0) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	_is_erasing = true
	var current_chars: int = label.visible_characters
	if current_chars <= 0:
		_is_erasing = false
		label.text = ""
		text_erased.emit()
		return

	var speed_multiplier: float = maxf(0.2, SettingsManager.text_speed)
	var duration: float = float(current_chars) / (erase_speed_cps * speed_multiplier)
	duration = clampf(duration, 0.3, 4.0)

	_tween = create_tween()
	_tween.tween_property(label, "visible_characters", 0, duration)
	_tween.finished.connect(_on_erasing_finished)


func _on_erasing_finished() -> void:
	_is_erasing = false
	label.text = ""
	_set_panel_visible(false)
	text_erased.emit()


## Langsung menyelesaikan efek pengetikan jika pemain menekan tombol
func complete_immediately() -> void:
	if _is_typing and _tween and _tween.is_valid():
		_tween.kill()
		label.visible_characters = _current_text.length()
		_is_typing = false
		text_completed.emit()


func clear() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_is_typing = false
	_is_erasing = false
	_current_text = ""
	label.text = ""
	label.visible_characters = 0
	_set_panel_visible(false)
