## ContentWarning — Layar Peringatan Konten
## Ditampilkan pertama kali sebelum game dimulai.
## Sesuai aturan wajib di SAFETY_AND_CONTENT.md §3 dan §4.
class_name ContentWarning
extends Control

signal warning_acknowledged()
signal help_requested()

@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var desc_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/DescLabel
@onready var proceed_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/ProceedButton
@onready var help_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/HelpButton
@onready var quit_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/QuitButton
@onready var help_menu: HelpMenu = $HelpMenu


func _ready() -> void:
	title_label.text = tr("CW_TITLE")
	desc_label.text = tr("CW_DESC")
	proceed_button.text = tr("CW_BTN_PROCEED")
	help_button.text = tr("CW_BTN_HELP")
	quit_button.text = tr("CW_BTN_QUIT")

	proceed_button.pressed.connect(_on_proceed_pressed)
	help_button.pressed.connect(_on_help_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	proceed_button.grab_focus()


func _on_proceed_pressed() -> void:
	warning_acknowledged.emit()
	if get_tree() and get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _on_help_pressed() -> void:
	help_requested.emit()


func _on_quit_pressed() -> void:
	get_tree().quit()
