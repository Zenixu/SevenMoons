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


func _ready() -> void:
	if label:
		label.text = ""


## Menampilkan teks dengan efek mengetik perlahan
func display_thought(text_key_or_literal: String, typing_speed_cps: float = 25.0) -> void:
	var final_text: String = tr(text_key_or_literal)
	_current_text = final_text
	_is_typing = true
	label.text = final_text
	label.visible_characters = 0

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
