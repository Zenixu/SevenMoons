## Interactable — Komponen Objek Interaktif
## Area2D yang mendeteksi pemain di sekitarnya dan memancarkan sinyal saat tombol aksi ditekan.
## MECHANICS_SPEC §7: id, prompt_text, highlight halus.
class_name Interactable
extends Area2D

signal player_interacted(object_id: String)

@export var object_id: String = ""
@export var prompt_text_key: String = "UI_INTERACT"
@export var is_enabled: bool = true

var _player_in_range: bool = false
var _prompt_label: Label
var _sprite_or_rect: CanvasItem

const BASE_PROMPT_FONT: int = 9
# Jarak vertikal label prompt dari titik objek (px).
const PROMPT_OFFSET_Y: float = -28.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_setup_prompt()

	if not SettingsManager.settings_changed.is_connected(_apply_accessibility):
		SettingsManager.settings_changed.connect(_apply_accessibility)


func _setup_prompt() -> void:
	_prompt_label = Label.new()
	_prompt_label.text = "[E] " + tr(prompt_text_key)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.visible = false
	# Garis tepi gelap agar teks tetap terbaca di atas latar apa pun
	# (tanpa mengandalkan warna saja).
	_prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_prompt_label.add_theme_constant_override("outline_size", 3)
	add_child(_prompt_label)
	_apply_accessibility()


## Petunjuk interaksi ikut "Ukuran Huruf"/"Kontras Tinggi" (MECHANICS_SPEC §9/§10).
## Label dipusatkan pada objek: lebarnya diukur dari teks yang sudah di-scale, lalu
## posisinya digeser `-lebar/2`. Ini menjaga prompt tetap di tengah (dan tak
## terpotong) pada 1x–2.5x, alih-alih kotak lebar-tetap yang melenceng saat teks
## membesar.
func _apply_accessibility() -> void:
	if _prompt_label == null:
		return
	var mult: float = UITheme.multiplier()
	var font_sz: int = int(round(float(BASE_PROMPT_FONT) * mult))
	_prompt_label.add_theme_font_size_override("font_size", font_sz)
	if SettingsManager.high_contrast:
		_prompt_label.add_theme_color_override("font_color", UITheme.HC_TEXT)
	else:
		_prompt_label.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0, 0.95))
	_recenter_prompt(font_sz)


## Ukur lebar teks prompt pada ukuran font saat ini, lalu pusatkan label pada objek.
func _recenter_prompt(font_sz: int) -> void:
	var font: Font = _prompt_label.get_theme_font("font")
	var text_w: float = font.get_string_size(
		_prompt_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz).x
	var w: float = maxf(text_w + 8.0, 32.0)
	_prompt_label.custom_minimum_size = Vector2(w, 0)
	_prompt_label.size = Vector2(w, _prompt_label.size.y)
	_prompt_label.position = Vector2(-w * 0.5, PROMPT_OFFSET_Y)


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range or not is_enabled:
		return

	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		get_viewport().set_input_as_handled()
		interact()


func interact() -> void:
	if not is_enabled:
		return
	player_interacted.emit(object_id)


func _on_body_entered(body: Node2D) -> void:
	if not is_enabled:
		return
	if body.is_in_group("player"):
		_player_in_range = true
		if _prompt_label:
			_prompt_label.visible = true
		_set_highlight(true)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		if _prompt_label:
			_prompt_label.visible = false
		_set_highlight(false)


func _set_highlight(enable: bool) -> void:
	var visual: CanvasItem = get_node_or_null("Visual")
	if visual:
		visual.self_modulate = Color(1.3, 1.3, 1.4, 1.0) if enable else Color(1.0, 1.0, 1.0, 1.0)
