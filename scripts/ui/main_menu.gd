## MainMenu — Layar Menu Utama
## Menghubungkan Mulai, Pengaturan, Bantuan (hotline), dan Keluar.
##
## Aksesibilitas: judul & tombol mengikuti "Ukuran Huruf"/"Kontras Tinggi".
##   - Whitespace (jarak antar-elemen & margin tepi) dipadatkan lebih cepat
##     daripada pertumbuhan huruf, sehingga pada 1x/2x/2.5x seluruh tombol —
##     termasuk "Keluar" — muat penuh di viewport tanpa terpotong.
##   - ScrollContainer memakai `follow_focus` sebagai jaring pengaman: bila
##     konten tetap lebih tinggi dari viewport (mis. lokalisasi panjang),
##     tombol yang difokus keyboard/controller otomatis di-scroll sampai
##     terlihat penuh.
class_name MainMenu
extends Control

signal start_game_requested()

## Naskah S00 -> S01: "fade hitam 3 detik".
const START_FADE_SECONDS: float = 3.0

## Jarak dasar antar-elemen & margin tepi (pada huruf 1x).
## Nilai margin dasar mempertahankan tampilan asli scene (16 horizontal / 12 vertikal).
const VBOX_SEPARATION_BASE: int = 16
const MENU_SEPARATION_BASE: int = 8
const MARGIN_X_BASE: int = 16
const MARGIN_Y_BASE: int = 12

@onready var margin_container: MarginContainer = $MarginContainer
@onready var scroll_container: ScrollContainer = $MarginContainer/ScrollContainer
@onready var vbox: VBoxContainer = $MarginContainer/ScrollContainer/CenterContainer/VBoxContainer
@onready var menu_buttons: VBoxContainer = $MarginContainer/ScrollContainer/CenterContainer/VBoxContainer/MenuButtons

@onready var title_label: Label = $MarginContainer/ScrollContainer/CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $MarginContainer/ScrollContainer/CenterContainer/VBoxContainer/SubtitleLabel
@onready var start_button: Button = $MarginContainer/ScrollContainer/CenterContainer/VBoxContainer/MenuButtons/StartButton
@onready var settings_button: Button = $MarginContainer/ScrollContainer/CenterContainer/VBoxContainer/MenuButtons/SettingsButton
@onready var help_button: Button = $MarginContainer/ScrollContainer/CenterContainer/VBoxContainer/MenuButtons/HelpButton
@onready var quit_button: Button = $MarginContainer/ScrollContainer/CenterContainer/VBoxContainer/MenuButtons/QuitButton

@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var help_menu: HelpMenu = $HelpMenu
@onready var fade_rect: ColorRect = $FadeRect

var _starting: bool = false


func _ready() -> void:
	_init_labels()

	# Hierarki: tombol Mulai paling menonjol (accent).
	start_button.set_meta("ui_kind", "accent")

	UITheme.bind(self)

	# Aksesibilitas: jarak dipadatkan mengikuti pengali huruf; fokus keyboard
	# menggulir ScrollContainer agar tombol selalu terjangkau (2x–2.5x).
	_apply_responsive_spacing()
	scroll_container.follow_focus = true
	_connect_settings()

	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	help_button.pressed.connect(_on_help_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	settings_menu.visible = false
	help_menu.visible = false

	# Fokus tombol Mulai ditunda satu frame: `follow_focus` baru menggulir
	# setelah tata letak selesai, sehingga menu terbuka dari atas (judul
	# terlihat), bukan langsung meloncat ke tombol.
	start_button.call_deferred("grab_focus")


## Padatkan jarak antar-elemen & margin tepi saat huruf diperbesar.
##
## Ruang layar tetap (640x360) sedangkan teks tumbuh ~linear terhadap pengali,
## jadi whitespace harus menyusut LEBIH CEPAT daripada pertumbuhan huruf
## (≈1/m²) agar seluruh tombol tetap muat penuh — termasuk pada 2.5x (batas
## clamp UITheme). Nilai dasar dipulihkan pada 1x sehingga tampilan normal utuh.
## Idempoten: aman dipanggil berkali-kali (mis. saat pengaturan berubah).
func _apply_responsive_spacing() -> void:
	var m: float = UITheme.multiplier()
	if m < 1.0:
		m = 1.0
	var k: float = 1.0 / (m * m)
	var vsep: int = clampi(int(floor(float(VBOX_SEPARATION_BASE) * k)), 2, VBOX_SEPARATION_BASE)
	var msep: int = clampi(int(floor(float(MENU_SEPARATION_BASE) * k)), 2, MENU_SEPARATION_BASE)
	var mx: int = clampi(int(floor(float(MARGIN_X_BASE) * k)), 2, MARGIN_X_BASE)
	var my: int = clampi(int(floor(float(MARGIN_Y_BASE) * k)), 2, MARGIN_Y_BASE)
	vbox.add_theme_constant_override("separation", vsep)
	menu_buttons.add_theme_constant_override("separation", msep)
	margin_container.add_theme_constant_override("margin_left", mx)
	margin_container.add_theme_constant_override("margin_right", mx)
	margin_container.add_theme_constant_override("margin_top", my)
	margin_container.add_theme_constant_override("margin_bottom", my)


func _connect_settings() -> void:
	var sm: Node = get_node_or_null("/root/SettingsManager")
	if sm == null or not sm.has_signal("settings_changed"):
		return
	var cb := Callable(self, "_apply_responsive_spacing")
	if not sm.is_connected("settings_changed", cb):
		sm.connect("settings_changed", cb)
	tree_exiting.connect(func() -> void:
		if is_instance_valid(sm) and sm.is_connected("settings_changed", cb):
			sm.disconnect("settings_changed", cb)
	)


func _init_labels() -> void:
	title_label.text = tr("MAIN_TITLE")
	subtitle_label.text = tr("MAIN_SUBTITLE")
	start_button.text = tr("UI_START")
	settings_button.text = tr("UI_SETTINGS")
	help_button.text = tr("UI_HELP")
	quit_button.text = tr("UI_QUIT")


func _on_start_pressed() -> void:
	if _starting:
		return
	start_game_requested.emit()
	# Transisi naskah S00 -> S01: "fade hitam 3 detik -> S01".
	# (Hanya saat menu ini scene aktif; pada uji sinyal tetap terpancar murni.)
	if get_tree() == null or get_tree().current_scene != self:
		return
	_starting = true
	start_button.disabled = true
	settings_button.disabled = true
	help_button.disabled = true
	quit_button.disabled = true

	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, START_FADE_SECONDS)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/intro/intro_cutscene.tscn")


func _on_settings_pressed() -> void:
	settings_menu.open()


func _on_help_pressed() -> void:
	help_menu.open()


func _on_quit_pressed() -> void:
	get_tree().quit()
