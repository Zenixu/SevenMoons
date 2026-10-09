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


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_setup_prompt()


func _setup_prompt() -> void:
	_prompt_label = Label.new()
	_prompt_label.text = "[E] " + tr(prompt_text_key)
	_prompt_label.add_theme_font_size_override("font_size", 9)
	_prompt_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.9))
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.position = Vector2(-40, -28)
	_prompt_label.custom_minimum_size = Vector2(80, 16)
	_prompt_label.visible = false
	add_child(_prompt_label)


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
