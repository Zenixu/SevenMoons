## SettingsMenu — UI Layar Pengaturan
## Mengatur audio, kecepatan teks, aksesibilitas, dan opsi lewati adegan sensitif.
## Tersinkronisasi dengan SettingsManager autoload.
class_name SettingsMenu
extends Control

signal closed()

@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var bgm_slider: HSlider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Audio/BgmRow/BgmSlider
@onready var sfx_slider: HSlider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Audio/SfxRow/SfxSlider
@onready var amb_slider: HSlider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Audio/AmbRow/AmbSlider

@onready var text_speed_slider: HSlider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Gameplay/TextSpeedRow/TextSpeedSlider
@onready var skip_sensitive_check: CheckBox = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Gameplay/SkipSensitiveCheck
@onready var no_time_pressure_check: CheckBox = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Gameplay/NoTimePressureCheck

@onready var high_contrast_check: CheckBox = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/A11y/HighContrastCheck
@onready var reduce_flash_check: CheckBox = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/A11y/ReduceFlashCheck

@onready var reset_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonRow/ResetButton
@onready var close_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonRow/CloseButton


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


func _init_labels() -> void:
	title_label.text = tr("SETTINGS_TITLE")
	reset_button.text = tr("SETTINGS_RESET")
	close_button.text = tr("UI_CLOSE")


func _load_values() -> void:
	bgm_slider.value = SettingsManager.volume_bgm
	sfx_slider.value = SettingsManager.volume_sfx
	amb_slider.value = SettingsManager.volume_ambience
	text_speed_slider.value = SettingsManager.text_speed
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
