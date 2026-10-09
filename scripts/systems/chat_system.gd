## ChatSystem — Sistem dan UI Chat Percakapan
## Mengelola jendela chat, antrean pesan, indikator mengetik, dan efek pesan dibatalkan.
class_name ChatSystem
extends Control

signal message_displayed(sender: String, text: String)
signal typing_started(sender: String)
signal typing_finished(sender: String)
signal message_cancelled(sender: String)
signal text_submitted(text: String)

const CHAT_BUBBLE_SCENE = preload("res://scenes/ui/chat_bubble.tscn")

@onready var scroll_container: ScrollContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer
@onready var message_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/MessageList
@onready var typing_indicator_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/TypingIndicator
@onready var typing_label: Label = $Panel/MarginContainer/VBoxContainer/TypingIndicator/TypingLabel
@onready var input_row: HBoxContainer = $Panel/MarginContainer/VBoxContainer/InputRow
@onready var line_edit: LineEdit = $Panel/MarginContainer/VBoxContainer/InputRow/LineEdit
@onready var send_button: Button = $Panel/MarginContainer/VBoxContainer/InputRow/SendButton

var _typing_timer: Timer
var _dots_count: int = 1
var _is_typing: bool = false
var _waiting_for_submit: bool = false


func _ready() -> void:
	if typing_indicator_container:
		typing_indicator_container.visible = false
	if input_row:
		input_row.visible = false
		send_button.pressed.connect(_on_send_pressed)
		line_edit.text_submitted.connect(func(_t: String) -> void: _on_send_pressed())


## Meminta pemain mengetik balasan teks bebas (S08)
func prompt_text_input(placeholder_key: String = "S08_INPUT_PROMPT") -> String:
	input_row.visible = true
	line_edit.placeholder_text = tr(placeholder_key)
	line_edit.text = ""
	line_edit.grab_focus()
	_waiting_for_submit = true

	var text: String = await text_submitted
	input_row.visible = false
	_waiting_for_submit = false

	# Tambahkan gelembung pemain ke obrolan
	var bubble: ChatBubble = CHAT_BUBBLE_SCENE.instantiate()
	message_container.add_child(bubble)
	bubble.setup("", text, true)
	_scroll_to_bottom()

	return text


func _on_send_pressed() -> void:
	if not _waiting_for_submit:
		return
	var text: String = line_edit.text.strip_edges()
	if text.is_empty():
		text = "..."
	text_submitted.emit(text)


## Menampilkan pesan biasa dengan simulasi mengetik
func post_message(sender: String, text_key: String, is_player: bool = false) -> void:
	var final_text: String = tr(text_key)
	var char_count: int = final_text.length()

	# Durasi mengetik: 0.04s per karakter, min 0.8s, max 3.0s (MECHANICS_SPEC §1)
	var speed: float = maxf(0.2, SettingsManager.text_speed)
	var duration: float = clampf(float(char_count) * 0.04, 0.8, 3.0) / speed

	await _show_typing(sender, duration)

	var bubble: ChatBubble = CHAT_BUBBLE_SCENE.instantiate()
	message_container.add_child(bubble)
	bubble.setup(sender, final_text, is_player)

	await get_tree().process_frame
	_scroll_to_bottom()

	message_displayed.emit(sender, final_text)


## Efek cemas: lawan bicara atau pemain mengetik, tapi lalu membatalkan pesan
func post_cancelled_message(sender: String, text_key: String, is_player: bool = false) -> void:
	var final_text: String = tr(text_key)
	var speed: float = maxf(0.2, SettingsManager.text_speed)
	var type_duration: float = clampf(float(final_text.length()) * 0.04, 0.8, 2.5) / speed

	await _show_typing(sender, type_duration)

	# Munculkan gelembung draft sementara
	var bubble: ChatBubble = CHAT_BUBBLE_SCENE.instantiate()
	message_container.add_child(bubble)
	bubble.setup(sender, final_text, is_player)
	_scroll_to_bottom()

	# Jeda sejenak sebelum menghapus
	await get_tree().create_timer(0.6 / speed).timeout

	# Hapus teks mundur
	var msg_label: Label = bubble.get_node("PanelContainer/MarginContainer/VBoxContainer/MessageLabel")
	var full_text: String = final_text
	while full_text.length() > 0:
		full_text = full_text.substr(0, full_text.length() - 1)
		msg_label.text = full_text
		await get_tree().create_timer(0.03 / speed).timeout

	bubble.queue_free()
	message_cancelled.emit(sender)


func _show_typing(sender: String, duration: float) -> void:
	_is_typing = true
	typing_indicator_container.visible = true
	typing_started.emit(sender)

	# Animasi titik-titik mengetik
	var elapsed: float = 0.0
	var dot_step: float = 0.3
	var dots: int = 1

	while elapsed < duration and _is_typing:
		AudioManager.play_typing_sfx()
		typing_label.text = "%s sedang mengetik%s" % [sender, ".".repeat(dots)]
		dots = (dots % 3) + 1
		await get_tree().create_timer(dot_step).timeout
		elapsed += dot_step

	typing_indicator_container.visible = false
	_is_typing = false
	typing_finished.emit(sender)


func _scroll_to_bottom() -> void:
	if scroll_container:
		scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)


func clear_messages() -> void:
	for child in message_container.get_children():
		child.queue_free()
	typing_indicator_container.visible = false
	_is_typing = false
