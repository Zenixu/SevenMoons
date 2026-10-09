## HelpMenu — Layar Menu Bantuan
## Menampilkan nomor layanan darurat dan kontak konseling kesehatan jiwa.
## Wajib selalu bisa diakses dari Menu Utama dan Menu Jeda (SAFETY_AND_CONTENT.md §5).
class_name HelpMenu
extends Control

signal closed()

@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SubtitleLabel
@onready var item1_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ItemsContainer/Item1
@onready var item2_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ItemsContainer/Item2
@onready var item3_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ItemsContainer/Item3
@onready var item4_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ItemsContainer/Item4
@onready var close_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CloseButton


func _ready() -> void:
	title_label.text = tr("HELP_TITLE")
	subtitle_label.text = tr("HELP_SUBTITLE")
	item1_label.text = tr("HELP_ITEM_1")
	item2_label.text = tr("HELP_ITEM_2")
	item3_label.text = tr("HELP_ITEM_3")
	item4_label.text = tr("HELP_ITEM_4")
	close_button.text = tr("UI_CLOSE")

	close_button.pressed.connect(_on_close_pressed)
	close_button.grab_focus()


func _on_close_pressed() -> void:
	visible = false
	closed.emit()


func open() -> void:
	visible = true
	close_button.grab_focus()
