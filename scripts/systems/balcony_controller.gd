## BalconyController — Pengendali Adegan Balkon S04, S05, S06, S06-ALT
## Mengelola siluet, tombol pilihan tunggal, timer tunggu (15s & 40s),
## cut to black (S06 tanpa grafis kekerasan), dan alternatif aman (S06-ALT).
class_name BalconyController
extends Node2D

signal balcony_scene_completed()

@onready var silhouette: ColorRect = $Silhouette
@onready var city_backdrop: ColorRect = $CityBackdrop
@onready var railing: ColorRect = $Railing
@onready var moon_glow: ColorRect = $MoonGlow

@onready var thought_box: ThoughtBox = $UI/ThoughtBox
@onready var choice_menu: ChoiceMenu = $UI/ChoiceMenu
@onready var transition_layer: TransitionLayer = $UI/TransitionLayer
@onready var wait_hint_label: Label = $UI/WaitHintLabel

@export var auto_start_sequence: bool = true

var _wait_time: float = 0.0
var _jump_chosen: bool = false
var _is_waiting_for_jump: bool = false


func _ready() -> void:
	wait_hint_label.visible = false
	choice_menu.visible = false

	if auto_start_sequence:
		if SettingsManager.skip_sensitive_scenes:
			_run_s06_alt()
		else:
			_start_s04_and_s05()


func _process(delta: float) -> void:
	if _is_waiting_for_jump and not _jump_chosen:
		_wait_time += delta
		if _wait_time >= 15.0 and _wait_time < 40.0 and not wait_hint_label.visible:
			wait_hint_label.text = tr("S05_WAIT_15")
			wait_hint_label.visible = true
		elif _wait_time >= 40.0 and wait_hint_label.text != tr("S05_WAIT_40"):
			wait_hint_label.text = tr("S05_WAIT_40")
			FlagStore.set_flag("waited_long", true)


func _start_s04_and_s05() -> void:
	transition_layer.set_vignette(0.7, 2.0)
	FlagStore.set_flag("saw_moon_hidden", true)

	# S04 Narasi
	thought_box.display_thought("S04_N01")
	await thought_box.text_completed
	await get_tree().create_timer(1.2).timeout

	thought_box.display_thought("S04_N02")
	await thought_box.text_completed
	await get_tree().create_timer(1.2).timeout

	thought_box.display_thought("S04_A01")
	await thought_box.text_completed
	await get_tree().create_timer(1.5).timeout

	thought_box.display_thought("S04_A02")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	thought_box.display_thought("S04_A03")
	await thought_box.text_completed
	await get_tree().create_timer(1.5).timeout

	thought_box.clear()

	# S05 — Munculkan tombol pilihan tunggal [ Lompat ]
	_is_waiting_for_jump = true
	var opts: Array = [{"text": "S05_BTN_JUMP"}]
	choice_menu.present_choices(opts, "normal")
	await choice_menu.choice_made

	_jump_chosen = true
	_is_waiting_for_jump = false
	wait_hint_label.visible = false

	# S06 — Pelaksanaan adegan (mengikuti aturan keras SAFETY_AND_CONTENT.md §2)
	_run_s06_jump()


func _run_s06_jump() -> void:
	# 1. Siluet bergerak singkat ke kanan (hanya gerak langkah)
	var tw := create_tween()
	tw.tween_property(silhouette, "position:x", silhouette.position.x + 30.0, 0.4)
	await tw.finished

	# 2. LANGSUNG HITAM TOTAL seketika, audio diputus
	transition_layer.cut_to_black()
	AudioManager.stop_bgm(0.0)
	AudioManager.stop_ambience(0.0)

	# 3. Hening 3 detik di layar hitam (tidak ada tampilan jatuh/darah/benturan)
	await get_tree().create_timer(3.0).timeout

	# 4. Denting jam tunggal
	# (SFX ditangani AudioManager jika file ada)
	await get_tree().create_timer(2.0).timeout

	balcony_scene_completed.emit()
	get_tree().change_scene_to_file("res://scenes/transitions/flashback.tscn")


func _run_s06_alt() -> void:
	# Alternatif aman jika "Lewati adegan sensitif" aktif
	silhouette.visible = false
	railing.visible = false
	city_backdrop.visible = false

	thought_box.display_thought("S06_ALT_N01")
	await thought_box.text_completed
	await get_tree().create_timer(1.5).timeout

	transition_layer.fade_to_black(3.0)
	await get_tree().create_timer(3.0).timeout

	thought_box.display_thought("S06_ALT_N02")
	await thought_box.text_completed
	await get_tree().create_timer(2.0).timeout

	thought_box.clear()
	balcony_scene_completed.emit()
	get_tree().change_scene_to_file("res://scenes/transitions/flashback.tscn")
