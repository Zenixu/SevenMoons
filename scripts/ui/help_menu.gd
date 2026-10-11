## HelpMenu — Layar Menu Bantuan
## Menampilkan nomor layanan darurat dan kontak konseling kesehatan jiwa.
## Wajib selalu bisa diakses dari Menu Utama dan Menu Jeda (SAFETY_AND_CONTENT.md §5).
##
## Aksesibilitas: teks mengikuti "Ukuran Huruf"/"Kontras Tinggi"; daftar bantuan
## dapat di-scroll agar tidak terpotong saat huruf diperbesar.
class_name HelpMenu
extends Control

signal closed()

const _ROOT := "MarginContainer/ScrollContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer"

@onready var title_label: Label = get_node(_ROOT + "/TitleLabel")
@onready var subtitle_label: Label = get_node(_ROOT + "/SubtitleLabel")
@onready var item1_label: Label = get_node(_ROOT + "/ItemsScroll/ItemsContainer/Item1")
@onready var item2_label: Label = get_node(_ROOT + "/ItemsScroll/ItemsContainer/Item2")
@onready var item3_label: Label = get_node(_ROOT + "/ItemsScroll/ItemsContainer/Item3")
@onready var item4_label: Label = get_node(_ROOT + "/ItemsScroll/ItemsContainer/Item4")
@onready var close_button: Button = get_node(_ROOT + "/CloseButton")


func _ready() -> void:
	title_label.text = tr("HELP_TITLE")
	subtitle_label.text = tr("HELP_SUBTITLE")
	item1_label.text = tr("HELP_ITEM_1")
	item2_label.text = tr("HELP_ITEM_2")
	item3_label.text = tr("HELP_ITEM_3")
	item4_label.text = tr("HELP_ITEM_4")
	close_button.text = tr("UI_CLOSE")

	$MarginContainer/ScrollContainer/CenterContainer/PanelContainer.set_meta("ui_hc", true)
	UITheme.bind(self)

	close_button.pressed.connect(_on_close_pressed)
	close_button.grab_focus()


func _on_close_pressed() -> void:
	visible = false
	closed.emit()


func open() -> void:
	visible = true
	close_button.grab_focus()
