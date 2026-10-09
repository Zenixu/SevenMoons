## ChatBubble — UI Komponen Gelembung Chat
## Menampilkan pesan masuk atau keluar dalam antarmuka ponsel/chat.
class_name ChatBubble
extends MarginContainer

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

	if is_sent_by_player:
		# Pesan pemain di kanan, nuansa biru/cyan gelap
		size_flags_horizontal = Control.SIZE_SHRINK_END
		panel.self_modulate = Color(0.2, 0.4, 0.6, 0.9)
	else:
		# Pesan orang lain di kiri, nuansa abu/gelap
		size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		panel.self_modulate = Color(0.2, 0.22, 0.26, 0.9)
