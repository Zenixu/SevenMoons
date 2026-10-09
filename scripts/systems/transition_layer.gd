## TransitionLayer — Sistem Transisi Layar
## Mengelola fade to black lambat, cut to black (S06), vignette efek dingin/tertekan,
## dan kontrol opasitas layar.
class_name TransitionLayer
extends CanvasLayer

signal fade_completed()
signal fade_in_completed()

@onready var color_rect: ColorRect = $ColorRect
@onready var vignette_rect: TextureRect = $VignetteRect

var _tween: Tween


func _ready() -> void:
	color_rect.color = Color(0, 0, 0, 0)
	vignette_rect.modulate = Color(1, 1, 1, 0)


## Fade layar ke hitam dengan durasi tertentu
func fade_to_black(duration: float = 2.0) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(color_rect, "color:a", 1.0, duration)
	_tween.finished.connect(func() -> void: fade_completed.emit())


## Fade layar dari hitam ke bening
func fade_from_black(duration: float = 2.0) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(color_rect, "color:a", 0.0, duration)
	_tween.finished.connect(func() -> void: fade_in_completed.emit())


## Langsung hitam total tanpa jeda (dipakai di S06 saat siluet melangkah)
func cut_to_black() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	color_rect.color = Color(0, 0, 0, 1)
	fade_completed.emit()


## Langsung kembali bening
func cut_to_clear() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	color_rect.color = Color(0, 0, 0, 0)


## Memunculkan vignette tepi layar (efek dingin/tertekan)
func set_vignette(visible_ratio: float, duration: float = 1.5) -> void:
	var target_alpha: float = clampf(visible_ratio, 0.0, 1.0)
	var tw := create_tween()
	tw.tween_property(vignette_rect, "modulate:a", target_alpha, duration)
