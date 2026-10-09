## Flashback — Sistem Kilas Balik S07
## Menampilkan 4 kenangan pudar masa lalu Arutala secara berurutan.
class_name FlashbackSequence
extends Control

signal flashback_finished()

@onready var slide_image: CanvasItem = $CenterContainer/VBoxContainer/SlideFrame/SlideImage
@onready var memory_text: Label = $CenterContainer/VBoxContainer/MemoryText
@onready var whisper_text: Label = $WhisperText

@export var auto_start: bool = true
var _current_slide: int = 0


func _ready() -> void:
	visible = false
	whisper_text.visible = false
	if auto_start and get_tree() and get_tree().current_scene == self:
		await play_sequence()
		get_tree().change_scene_to_file("res://scenes/bedroom/bedroom.tscn")


const SLIDES: Array[Dictionary] = [
	{"text": "S07_FLASH_1", "texture": preload("res://assets/flashbacks/fb_1.png"), "color": Color(0.18, 0.16, 0.22, 1.0)},
	{"text": "S07_FLASH_2", "texture": preload("res://assets/flashbacks/fb_2.png"), "color": Color(0.14, 0.17, 0.22, 1.0)},
	{"text": "S07_FLASH_3", "texture": preload("res://assets/flashbacks/fb_3.png"), "color": Color(0.22, 0.14, 0.16, 1.0)},
	{"text": "S07_FLASH_4", "texture": preload("res://assets/flashbacks/fb_4.png"), "color": Color(0.19, 0.18, 0.15, 1.0)}
]

func play_sequence() -> void:
	visible = true
	AudioManager.play_theme_a_reversed(1.5)

	for i in SLIDES.size():
		var slide: Dictionary = SLIDES[i]
		if slide_image is TextureRect and slide.has("texture"):
			slide_image.texture = slide["texture"]
		elif "color" in slide_image:
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
	AudioManager.stop_bgm(1.5)
	FlagStore.set_flag("saw_flashback_1", true)
	flashback_finished.emit()
