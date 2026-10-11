## SettingsMenu — UI Layar Pengaturan
## Mengatur audio, kecepatan teks, ukuran huruf, aksesibilitas, dan opsi lewati
## adegan sensitif. Tersinkronisasi dengan SettingsManager autoload.
##
## Aksesibilitas (MECHANICS_SPEC §9): menyediakan kontrol "Ukuran Huruf" dan
## "Kontras Tinggi"; semua teks/label lewat lokalisasi (`tr()`).
class_name SettingsMenu
extends Control

signal closed()

const _ROOT := "MarginContainer/ScrollContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer"

@onready var title_label: Label = get_node(_ROOT + "/TitleLabel")
@onready var tab_container: TabContainer = get_node(_ROOT + "/TabContainer")
@onready var bgm_slider: HSlider = get_node(_ROOT + "/TabContainer/Audio/BgmRow/BgmSlider")
@onready var sfx_slider: HSlider = get_node(_ROOT + "/TabContainer/Audio/SfxRow/SfxSlider")
@onready var amb_slider: HSlider = get_node(_ROOT + "/TabContainer/Audio/AmbRow/AmbSlider")

@onready var text_speed_slider: HSlider = get_node(_ROOT + "/TabContainer/Gameplay/TextSpeedRow/TextSpeedSlider")
@onready var skip_sensitive_check: CheckBox = get_node(_ROOT + "/TabContainer/Gameplay/SkipSensitiveCheck")
@onready var no_time_pressure_check: CheckBox = get_node(_ROOT + "/TabContainer/Gameplay/NoTimePressureCheck")

@onready var font_slider: HSlider = get_node(_ROOT + "/TabContainer/A11y/FontSizeRow/FontSlider")
@onready var high_contrast_check: CheckBox = get_node(_ROOT + "/TabContainer/A11y/HighContrastCheck")
@onready var reduce_flash_check: CheckBox = get_node(_ROOT + "/TabContainer/A11y/ReduceFlashCheck")

@onready var reset_button: Button = get_node(_ROOT + "/ButtonRow/ResetButton")
@onready var close_button: Button = get_node(_ROOT + "/ButtonRow/CloseButton")


func _ready() -> void:
	_init_labels()
	_load_values()

	bgm_slider.value_changed.connect(func(val: float) -> void:
		SettingsManager.volume_bgm = val
		SettingsManager.save_settings()
	)
	sfx_slider.value_changed.connect(func(val: float) -> void:
		SettingsManager.volume_sfx = val
		SettingsManager.save_settings()
	)
	amb_slider.value_changed.connect(func(val: float) -> void:
		SettingsManager.volume_ambience = val
		SettingsManager.save_settings()
	)
	text_speed_slider.value_changed.connect(func(val: float) -> void:
		SettingsManager.text_speed = val
		SettingsManager.save_settings()
	)
	font_slider.value_changed.connect(func(val: float) -> void:
		SettingsManager.font_size_multiplier = val
		SettingsManager.save_settings()
	)
	skip_sensitive_check.toggled.connect(func(toggled: bool) -> void:
		SettingsManager.skip_sensitive_scenes = toggled
		SettingsManager.save_settings()
	)
	no_time_pressure_check.toggled.connect(func(toggled: bool) -> void:
		SettingsManager.no_time_pressure = toggled
		SettingsManager.save_settings()
	)
	high_contrast_check.toggled.connect(func(toggled: bool) -> void:
		SettingsManager.high_contrast = toggled
		SettingsManager.save_settings()
	)
	reduce_flash_check.toggled.connect(func(toggled: bool) -> void:
		SettingsManager.reduce_flash = toggled
		SettingsManager.save_settings()
	)

	reset_button.pressed.connect(_on_reset_pressed)
	close_button.pressed.connect(_on_close_pressed)

	$MarginContainer/ScrollContainer/CenterContainer/PanelContainer.set_meta("ui_hc", true)
	UITheme.bind(self)


func _init_labels() -> void:
	title_label.text = tr("SETTINGS_TITLE")

	# Judul tab lewat lokalisasi (sebelumnya nama node hardcoded).
	tab_container.set_tab_title(0, tr("SETTINGS_TAB_AUDIO"))
	tab_container.set_tab_title(1, tr("SETTINGS_TAB_GAMEPLAY"))
	tab_container.set_tab_title(2, tr("SETTINGS_TAB_A11Y"))

	_set_label(_ROOT + "/TabContainer/Audio/BgmRow/Label", "SETTINGS_BGM_VOL")
	_set_label(_ROOT + "/TabContainer/Audio/SfxRow/Label", "SETTINGS_SFX_VOL")
	_set_label(_ROOT + "/TabContainer/Audio/AmbRow/Label", "SETTINGS_AMBIENCE_VOL")
	_set_label(_ROOT + "/TabContainer/Gameplay/TextSpeedRow/Label", "SETTINGS_TEXT_SPEED")
	_set_label(_ROOT + "/TabContainer/A11y/FontSizeRow/Label", "SETTINGS_FONT_SIZE")

	skip_sensitive_check.text = tr("SETTINGS_SKIP_SENSITIVE")
	no_time_pressure_check.text = tr("SETTINGS_NO_TIME_PRESSURE")
	high_contrast_check.text = tr("SETTINGS_HIGH_CONTRAST")
	reduce_flash_check.text = tr("SETTINGS_REDUCE_FLASH")

	reset_button.text = tr("SETTINGS_RESET")
	close_button.text = tr("UI_CLOSE")


func _set_label(path: String, key: String) -> void:
	# BUG-5: pemanggil mengirim path ABSOLUT (sudah berawalan _ROOT), jadi jangan
	# menambahkan _ROOT lagi — dulu `_ROOT + path` menghasilkan `_ROOT + _ROOT + …`
	# → get_node_or_null() = null → label dibiarkan kosong (no-op senyap).
	var node: Label = get_node_or_null(path)
	if node:
		node.text = tr(key)


func _load_values() -> void:
	bgm_slider.value = SettingsManager.volume_bgm
	sfx_slider.value = SettingsManager.volume_sfx
	amb_slider.value = SettingsManager.volume_ambience
	text_speed_slider.value = SettingsManager.text_speed
	font_slider.value = SettingsManager.font_size_multiplier
	skip_sensitive_check.button_pressed = SettingsManager.skip_sensitive_scenes
	no_time_pressure_check.button_pressed = SettingsManager.no_time_pressure
	high_contrast_check.button_pressed = SettingsManager.high_contrast
	reduce_flash_check.button_pressed = SettingsManager.reduce_flash


func _on_reset_pressed() -> void:
	SettingsManager.reset_to_defaults()
	_load_values()


func _on_close_pressed() -> void:
	visible = false
	closed.emit()


func open() -> void:
	_load_values()
	visible = true
	close_button.grab_focus()
