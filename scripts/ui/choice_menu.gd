## ChoiceMenu — UI Menu Pilihan
## Menampilkan daftar pilihan dialog/tindakan.
## Mendukung mode:
## - "normal": pilihan langsung muncul
## - "convergent": pilihan konvergen (semua menuju alur yang sama)
## - "hesitant": pilihan tertunda dan ragu (muncul bertahap, pilihan jujur lebih lambat & redup)
class_name ChoiceMenu
extends Control

signal choice_made(index: int)

@onready var container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer
@onready var prompt_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PromptLabel
@onready var button_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer

var _options: Array = []
var _mode: String = "normal"
var _buttons: Array[Button] = []
var _is_presenting: bool = false


func _ready() -> void:
	visible = false
	if DialogueRunner.choice_requested.is_connected(present_choices):
		return
	DialogueRunner.choice_requested.connect(present_choices)


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


func _present_immediate(options: Array) -> void:
	for i in options.size():
		var btn: Button = _create_choice_button(i, options[i])
		button_container.add_child(btn)
		_buttons.append(btn)

	if _buttons.size() > 0:
		_buttons[0].grab_focus()


func _present_hesitant(options: Array) -> void:
	_is_presenting = true
	# Di mode hesitant:
	# Pilihan "aman" (awal) muncul lebih cepat dan terang
	# Pilihan "jujur" (belakang) muncul bertahap (jeda 0.8s) dan lebih redup
	for i in options.size():
		if not visible:
			return
		var btn: Button = _create_choice_button(i, options[i])
		button_container.add_child(btn)
		_buttons.append(btn)

		if i == 0:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			btn.grab_focus()
		else:
			btn.modulate = Color(0.7, 0.75, 0.8, 0.0)
			var tw := create_tween()
			tw.tween_property(btn, "modulate:a", 0.75, 0.5)

		# Jeda bertahap antar opsi (MECHANICS_SPEC §2)
		if i < options.size() - 1:
			var delay: float = 1.0 / maxf(0.5, SettingsManager.text_speed)
			await get_tree().create_timer(delay).timeout

	_is_presenting = false


func _create_choice_button(index: int, opt: Variant) -> Button:
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

	var base_font_size: int = 11
	var font_sz: int = int(round(base_font_size * SettingsManager.font_size_multiplier))
	btn.add_theme_font_size_override("font_size", font_sz)

	if SettingsManager.high_contrast:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.0, 0.0, 0.0, 0.95)
		sb.border_color = Color(1.0, 1.0, 1.0, 1.0)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(2)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))

	btn.pressed.connect(func() -> void: _on_button_pressed(index))
	return btn


func _on_button_pressed(index: int) -> void:
	visible = false
	_clear_buttons()
	choice_made.emit(index)
	DialogueRunner.submit_choice(index)


func _clear_buttons() -> void:
	for child in button_container.get_children():
		child.queue_free()
	_buttons.clear()
