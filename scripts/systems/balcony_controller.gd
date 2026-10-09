## BalconyController — Pengendali Adegan Balkon S04, S05, S06, S06-ALT
## Mengelola siluet, tombol pilihan tunggal, timer tunggu (15s & 40s),
## cut to black (S06 tanpa grafis kekerasan), dan alternatif aman (S06-ALT).
class_name BalconyController
extends Node2D

signal balcony_scene_completed()

@onready var silhouette: CanvasItem = $Silhouette
@onready var city_backdrop: CanvasItem = $CityBackdrop
@onready var railing: CanvasItem = $Railing
@onready var moon_glow: CanvasItem = $MoonGlow

@onready var thought_box: ThoughtBox = $UI/ThoughtBox
@onready var choice_menu: ChoiceMenu = $UI/ChoiceMenu
@onready var transition_layer: TransitionLayer = $UI/TransitionLayer
@onready var wait_hint_label: Label = $UI/WaitHintLabel
@onready var player: PlayerCharacter = $Player

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
			_arrive_then_start()


func _process(delta: float) -> void:
	if _is_waiting_for_jump and not _jump_chosen:
		_wait_time += delta
		if _wait_time >= 15.0 and _wait_time < 40.0 and not wait_hint_label.visible:
			wait_hint_label.text = tr("S05_WAIT_15")
			wait_hint_label.visible = true
		elif _wait_time >= 40.0 and wait_hint_label.text != tr("S05_WAIT_40"):
			wait_hint_label.text = tr("S05_WAIT_40")
			FlagStore.set_flag("waited_long", true)


## Jika pemain baru tiba dari lift (lantai 5 = atap): pemain BERJALAN dulu
## ke tengah atap, berhenti sejenak, baru dialog perenungan dimulai.
func _arrive_then_start() -> void:
	if FlagStore.get_flag("rooftop_from_lift", false) and not FlagStore.get_flag("rooftop_arrived", false):
		FlagStore.set_flag("rooftop_arrived", true)
		FlagStore.set_flag("rooftop_from_lift", false)
		AudioManager.play_rain(1.5)
		transition_layer.set_vignette(0.35, 1.5)

		if player:
			player.set_movement_enabled(false)
			player.position = Vector2(74, 300)

		transition_layer.cut_to_black()
		transition_layer.fade_from_black(1.6)
		await get_tree().create_timer(1.2).timeout

		# Berjalan pelan menuju tengah atap
		if player:
			await player.auto_walk_to(Vector2(300, 300), 62.0)
		await get_tree().create_timer(0.6).timeout

		# Berhenti sejenak di tengah — dialog perenungan
		thought_box.display_thought("ROOFTOP_WALK_1")
		await thought_box.text_completed
		await get_tree().create_timer(1.8).timeout

		thought_box.display_thought("ROOFTOP_WALK_2")
		await thought_box.text_completed
		await get_tree().create_timer(1.6).timeout

		thought_box.display_thought("ROOFTOP_WALK_3")
		await thought_box.text_completed
		await get_tree().create_timer(1.8).timeout
		thought_box.clear()
	await _start_s04_and_s05()


func _start_s04_and_s05() -> void:
	transition_layer.set_vignette(0.7, 2.0)
	AudioManager.play_rain(1.0)
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
	# 1. Arutala melangkah ke tepi pagar (hanya gerak langkah, tanpa detail)
	silhouette.visible = false
	if player:
		await player.auto_walk_to(Vector2(598, 300), 58.0)
	else:
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
	AudioManager.play_chime()
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

	AudioManager.fade_out_ambience(2.0)
	transition_layer.fade_to_black(3.0)
	await get_tree().create_timer(3.0).timeout

	thought_box.display_thought("S06_ALT_N02")
	await thought_box.text_completed
	await get_tree().create_timer(2.0).timeout

	thought_box.clear()
	balcony_scene_completed.emit()
	get_tree().change_scene_to_file("res://scenes/transitions/flashback.tscn")
