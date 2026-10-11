## PauseMenu — Menu Jeda (Esc)
## Selalu dapat dipanggil dari scene permainan; berisi Menu Bantuan dan tombol
## keluar TANPA penalti (SAFETY_AND_CONTENT.md §3.2 & §3.4).
##
## Perilaku:
##   - Esc membuka/menutup menu jeda (aksi input `pause`, dipetakan ke Esc).
##   - Saat menu bantuan terbuka, Esc menutupnya lebih dulu (kembali ke jeda).
##   - Node ini `process_mode = ALWAYS` agar tetap menerima input saat tree
##     dijeda; node PAUSABLE lain berhenti (waktu permainan benar-benar berhenti).
##
## Aksesibilitas: seluruh teks lewat `tr()` dan mengikuti "Ukuran Huruf"/
## "Kontras Tinggi" via UITheme; panel dapat di-scroll agar tidak terpotong.
class_name PauseMenu
extends Control

signal resumed()
signal quit_requested()

const _ROOT := "MarginContainer/ScrollContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer"

@onready var title_label: Label = get_node(_ROOT + "/TitleLabel")
@onready var resume_button: Button = get_node(_ROOT + "/Buttons/ResumeButton")
@onready var help_button: Button = get_node(_ROOT + "/Buttons/HelpButton")
@onready var quit_button: Button = get_node(_ROOT + "/Buttons/QuitButton")
@onready var hint_label: Label = get_node(_ROOT + "/HintLabel")
@onready var help_menu: HelpMenu = $HelpMenu


func _ready() -> void:
	# Menu jeda harus tetap berjalan saat tree dijeda.
	process_mode = Node.PROCESS_MODE_ALWAYS

	title_label.text = tr("PAUSE_TITLE")
	resume_button.text = tr("UI_RESUME")
	help_button.text = tr("UI_HELP")
	quit_button.text = tr("UI_QUIT")
	hint_label.text = tr("PAUSE_HINT")

	# Hierarki: "Lanjutkan" paling menonjol.
	resume_button.set_meta("ui_kind", "accent")
	$MarginContainer/ScrollContainer/CenterContainer/PanelContainer.set_meta("ui_hc", true)
	UITheme.bind(self)

	resume_button.pressed.connect(close)
	help_button.pressed.connect(_on_help_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	help_menu.visible = false
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()

	# Esc menutup menu bantuan lebih dulu bila sedang terbuka.
	if help_menu.visible:
		help_menu.visible = false
		help_button.grab_focus()
		return

	if visible:
		close()
	else:
		open()


func open() -> void:
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func close() -> void:
	visible = false
	if help_menu:
		help_menu.visible = false
	if get_tree():
		get_tree().paused = false
	resumed.emit()


func is_open() -> bool:
	return visible


func _on_help_pressed() -> void:
	help_menu.open()


func _on_quit_pressed() -> void:
	if get_tree():
		get_tree().paused = false
	quit_requested.emit()
	get_tree().quit()


## Pengaman: jangan tinggalkan tree dalam keadaan dijeda bila node ini dibuang.
func _exit_tree() -> void:
	var tree := get_tree()
	if tree and tree.paused:
		tree.paused = false
