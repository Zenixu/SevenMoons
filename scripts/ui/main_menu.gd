## MainMenu — Layar Menu Utama
## Menghubungkan Mulai, Pengaturan, Bantuan (hotline), dan Keluar.
class_name MainMenu
extends Control

signal start_game_requested()

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/SubtitleLabel
@onready var start_button: Button = $CenterContainer/VBoxContainer/MenuButtons/StartButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/MenuButtons/SettingsButton
@onready var help_button: Button = $CenterContainer/VBoxContainer/MenuButtons/HelpButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/MenuButtons/QuitButton

@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var help_menu: HelpMenu = $HelpMenu


func _ready() -> void:
	_init_labels()

	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	help_button.pressed.connect(_on_help_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	settings_menu.visible = false
	help_menu.visible = false

	start_button.grab_focus()


func _init_labels() -> void:
	title_label.text = "ARUTALA"
	subtitle_label.text = "Tujuh Malam Sebelum Fajar"
	start_button.text = tr("UI_START")
	settings_button.text = tr("UI_SETTINGS")
	help_button.text = tr("UI_HELP")
	quit_button.text = tr("UI_QUIT")


func _on_start_pressed() -> void:
	start_game_requested.emit()
	if get_tree() and get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://scenes/bedroom/bedroom.tscn")


func _on_settings_pressed() -> void:
	settings_menu.open()


func _on_help_pressed() -> void:
	help_menu.open()


func _on_quit_pressed() -> void:
	get_tree().quit()
