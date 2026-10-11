## ContentWarning — Layar Peringatan Konten
## Ditampilkan pertama kali sebelum game dimulai.
## Sesuai aturan wajib di SAFETY_AND_CONTENT.md §3 dan §4.
##
## Aksesibilitas (MECHANICS_SPEC §9/§10): seluruh teks mengikuti "Ukuran Huruf"
## dan "Kontras Tinggi". Isi peringatan dapat di-scroll sehingga tidak terpotong
## saat huruf diperbesar.
class_name ContentWarning
extends Control

signal warning_acknowledged()
signal help_requested()

## Scene tujuan setelah pemain mengonfirmasi ("Aku mengerti"). Dirutekan sebagai
## scene boot di project.godot sehingga peringatan SELALU tampil sebelum permainan.
const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"

const _ROOT := "MarginContainer/ScrollContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer"

@onready var title_label: Label = get_node(_ROOT + "/TitleLabel")
@onready var desc_label: Label = get_node(_ROOT + "/DescScroll/DescLabel")
@onready var proceed_button: Button = get_node(_ROOT + "/ButtonContainer/ProceedButton")
@onready var help_button: Button = get_node(_ROOT + "/ButtonContainer/HelpButton")
@onready var quit_button: Button = get_node(_ROOT + "/ButtonContainer/QuitButton")
@onready var help_menu: HelpMenu = $HelpMenu


func _ready() -> void:
	title_label.text = tr("CW_TITLE")
	desc_label.text = tr("CW_DESC")
	proceed_button.text = tr("CW_BTN_PROCEED")
	help_button.text = tr("CW_BTN_HELP")
	quit_button.text = tr("CW_BTN_QUIT")

	# Tombol utama menonjol (accent) — hierarki jelas tanpa mengandalkan warna saja
	# (tombol utama juga lebih lebar & muncul pertama saat fokus).
	proceed_button.set_meta("ui_kind", "accent")

	# Aksesibilitas: tandai kotak untuk kontras tinggi, lalu terapkan.
	$MarginContainer/ScrollContainer/CenterContainer/PanelContainer.set_meta("ui_hc", true)
	UITheme.bind(self)

	proceed_button.pressed.connect(_on_proceed_pressed)
	help_button.pressed.connect(_on_help_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	proceed_button.grab_focus()


func _on_proceed_pressed() -> void:
	warning_acknowledged.emit()
	if get_tree() and get_tree().current_scene == self:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_help_pressed() -> void:
	help_requested.emit()
	help_menu.open()


func _on_quit_pressed() -> void:
	get_tree().quit()
