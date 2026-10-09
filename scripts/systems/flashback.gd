## Flashback — Sistem Kilas Balik S07
## Menampilkan 4 kenangan pudar masa lalu Arutala secara berurutan.
class_name FlashbackSequence
extends Control

signal flashback_finished()

@onready var slide_image: ColorRect = $CenterContainer/VBoxContainer/SlideFrame/SlideImage
@onready var memory_text: Label = $CenterContainer/VBoxContainer/MemoryText
@onready var whisper_text: Label = $WhisperText

var _current_slide: int = 0


func _ready() -> void:
	visible = false
	whisper_text.visible = false


func play_sequence() -> void:
	visible = true
	var slides: Array[Dictionary] = [
		{"text": "S07_FLASH_1", "color": Color(0.18, 0.16, 0.22, 1.0)},
		{"text": "S07_FLASH_2", "color": Color(0.14, 0.17, 0.22, 1.0)},
		{"text": "S07_FLASH_3", "color": Color(0.22, 0.14, 0.16, 1.0)},
		{"text": "S07_FLASH_4", "color": Color(0.19, 0.18, 0.15, 1.0)}
	]

	for i in slides.size():
		var slide: Dictionary = slides[i]
		slide_image.color = slide["color"]
		memory_text.text = tr(slide["text"])
		
		# Fade in
		modulate.a = 0.0
		var tw_in := create_tween()
		tw_in.tween_property(self, "modulate:a", 1.0, 0.8)
		await tw_in.finished

		await get_tree().create_timer(2.2).timeout

		# Fade out
		var tw_out := create_tween()
		tw_out.tween_property(self, "modulate:a", 0.0, 0.8)
		await tw_out.finished

	# Bisikan Arutala penutup S07
	whisper_text.visible = true
	whisper_text.text = tr("S07_A01")
	var tw_w1 := create_tween()
	tw_w1.tween_property(whisper_text, "modulate:a", 0.6, 1.0)
	await tw_w1.finished
	await get_tree().create_timer(1.0).timeout

	whisper_text.text = tr("S07_A02")
	await get_tree().create_timer(1.5).timeout

	var tw_end := create_tween()
	tw_end.tween_property(whisper_text, "modulate:a", 0.0, 1.0)
	await tw_end.finished

	visible = false
	whisper_text.visible = false
	FlagStore.set_flag("saw_flashback_1", true)
	flashback_finished.emit()
