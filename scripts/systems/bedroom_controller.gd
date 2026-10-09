## BedroomController — Pengendali Eksplorasi Kamar S01 & S02
## Mengelola 6 objek interaktif, memori inspeksi, pembatasan gerak saat berdialog,
## dan membuka pintu balkon setelah minimal 3 objek diperiksa.
class_name BedroomController
extends Node2D

signal exploration_completed()

@onready var player: PlayerCharacter = $Player
@onready var thought_box: ThoughtBox = $UI/ThoughtBox
@onready var choice_menu: ChoiceMenu = $UI/ChoiceMenu
@onready var transition_layer: TransitionLayer = $UI/TransitionLayer
@onready var clock_label: Label = $UI/ClockLabel
@onready var chat_ui: ChatSystem = $UI/ChatUI
@onready var loop_counter_label: Label = $UI/LoopCounterLabel

@onready var interactables_parent: Node2D = $Interactables
@onready var balcony_trigger: Area2D = $BalconyTrigger
@onready var tea_node: Node2D = $Interactables/Tea
@onready var photo_node: Node2D = $Interactables/Photo

const CORRIDOR_SCENE := "res://scenes/corridor/corridor.tscn"

@export var auto_start_intro: bool = true

var _inspected_objects: Dictionary = {}
var _is_interacting: bool = false
var _balcony_unlocked: bool = false


func _ready() -> void:
	clock_label.visible = false
	if chat_ui:
		chat_ui.visible = false
	if loop_counter_label:
		loop_counter_label.visible = false
	balcony_trigger.monitoring = false
	balcony_trigger.body_entered.connect(_on_balcony_trigger_entered)

	for child in interactables_parent.get_children():
		if child is Interactable:
			child.player_interacted.connect(_on_object_interacted)

	# Cek apakah ini kembalian dari flashback (S08)
	if FlagStore.get_flag("saw_flashback_1", false) and not FlagStore.get_flag("received_mystery_message", false):
		_start_s08_sequence()
	elif FlagStore.get_flag("visited_corridor", false):
		# Kembali dari lorong: lewati intro, taruh pemain dekat pintu
		player.position = Vector2(90, 250)
		clock_label.text = "02:47"
		clock_label.visible = true
		player.set_movement_enabled(true)
	elif auto_start_intro:
		_start_s01_intro()


func _start_s01_intro() -> void:
	player.set_movement_enabled(false)
	AudioManager.play_rain(2.0)
	transition_layer.cut_to_black()
	transition_layer.fade_from_black(4.0)

	await get_tree().create_timer(1.0).timeout
	thought_box.display_thought("S01_N01")
	await thought_box.text_completed
	await get_tree().create_timer(1.5).timeout

	thought_box.display_thought("S01_N02")
	await thought_box.text_completed
	await get_tree().create_timer(1.5).timeout

	thought_box.display_thought("S01_N03")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	# Munculkan jam 02:47
	clock_label.text = "02:47"
	clock_label.visible = true
	FlagStore.set_flag("ui_clock_visible", true)

	thought_box.display_thought("S01_A01")
	await thought_box.text_completed
	await get_tree().create_timer(1.2).timeout

	thought_box.display_thought("S01_A02")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	thought_box.clear()
	player.set_movement_enabled(true)


func _on_object_interacted(obj_id: String) -> void:
	if _is_interacting:
		return

	_is_interacting = true
	player.set_movement_enabled(false)
	_inspected_objects[obj_id] = true

	match obj_id:
		"phone":
			await _handle_phone()
		"photo":
			await _handle_photo()
		"tea":
			await _handle_tea()
		"mirror":
			await _handle_mirror()
		"clock":
			await _handle_clock()
		"door":
			await _handle_door()

	_check_balcony_condition()
	player.set_movement_enabled(true)
	_is_interacting = false


func _handle_phone() -> void:
	AudioManager.play_vibrate()
	FlagStore.set_flag("checked_phone", true)
	thought_box.display_thought("S02_O1_N01")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	thought_box.display_thought("S02_O1_N02")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	thought_box.display_thought("S02_O1_PREVIEW")
	await thought_box.text_completed
	await get_tree().create_timer(1.2).timeout

	thought_box.display_thought("S02_O1_A02")
	await thought_box.text_completed
	await get_tree().create_timer(0.8).timeout

	# Pilihan
	var opts: Array = [
		{"text": "S02_O1_OPT_A"},
		{"text": "S02_O1_OPT_B"}
	]
	choice_menu.present_choices(opts, "normal")
	var idx: int = await choice_menu.choice_made

	if idx == 0:
		FlagStore.set_flag("tried_open_message", true)
		thought_box.display_thought("S02_O1_RES_A")
	else:
		FlagStore.set_flag("avoided_message", true)
		thought_box.display_thought("S02_O1_RES_B")

	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout
	thought_box.clear()


func _handle_photo() -> void:
	thought_box.display_thought("S02_O2_N01")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	thought_box.display_thought("S02_O2_N02")
	await thought_box.text_completed
	await get_tree().create_timer(0.8).timeout

	var opts: Array = [
		{"text": "S02_O2_OPT_A"},
		{"text": "S02_O2_OPT_B"}
	]
	choice_menu.present_choices(opts, "normal")
	var idx: int = await choice_menu.choice_made

	if idx == 0:
		FlagStore.set_flag("turned_photo", true)
		thought_box.display_thought("S02_O2_RES_A")
	else:
		FlagStore.set_flag("left_photo", true)
		thought_box.display_thought("S02_O2_RES_B")

	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout
	thought_box.clear()


func _handle_tea() -> void:
	FlagStore.set_flag("noticed_tea", true)
	thought_box.display_thought("S02_O3_N01")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	thought_box.display_thought("S02_O3_A01")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	thought_box.display_thought("S02_O3_A02")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout
	thought_box.clear()


func _handle_mirror() -> void:
	FlagStore.set_flag("talked_to_mirror", true)
	thought_box.display_thought("S02_O4_N01")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	thought_box.display_thought("S02_O4_A01")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	thought_box.display_thought("S02_O4_N02")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout
	thought_box.clear()


func _handle_clock() -> void:
	FlagStore.set_flag("noticed_clock", true)
	thought_box.display_thought("S02_O5_N01")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	thought_box.display_thought("S02_O5_A01")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	thought_box.display_thought("S02_O5_A02")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout
	thought_box.clear()


func _handle_door() -> void:
	thought_box.display_thought("S02_O6_N01")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	thought_box.display_thought("S02_O6_N02")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	thought_box.display_thought("S02_O6_A01")
	await thought_box.text_completed
	await get_tree().create_timer(0.8).timeout

	var opts: Array = [
		{"text": "S02_O6_OPT_A"},
		{"text": "S02_O6_OPT_B"}
	]
	choice_menu.present_choices(opts, "normal")
	var idx: int = await choice_menu.choice_made

	if idx == 0:
		FlagStore.set_flag("tried_door", true)
		thought_box.display_thought("S02_O6_RES_A")
		await thought_box.text_completed
		await get_tree().create_timer(1.0).timeout
		thought_box.clear()
		# Keluar ke lorong apartemen
		FlagStore.set_flag("visited_corridor", true)
		player.set_movement_enabled(false)
		transition_layer.fade_to_black(1.2)
		await get_tree().create_timer(1.2).timeout
		get_tree().change_scene_to_file(CORRIDOR_SCENE)
		return
	else:
		thought_box.display_thought("S02_O6_RES_B")

	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout
	thought_box.clear()


func _check_balcony_condition() -> void:
	if not _balcony_unlocked and _inspected_objects.size() >= 3:
		_balcony_unlocked = true
		balcony_trigger.monitoring = true
		thought_box.display_thought("UI_PROMPT_BALCONY")


func _on_balcony_trigger_entered(body: Node2D) -> void:
	if body.is_in_group("player") and _balcony_unlocked:
		balcony_trigger.monitoring = false
		player.set_movement_enabled(false)
		await start_s03_monologue()
		exploration_completed.emit()
		get_tree().change_scene_to_file("res://scenes/balcony/balcony.tscn")


## S03 — Percakapan dengan Diri Sendiri (monolog interaktif 4 putaran)
func start_s03_monologue() -> void:
	player.set_movement_enabled(false)
	transition_layer.set_vignette(0.4, 2.0)
	AudioManager.play_theme_a(2.0)

	# Putaran 1
	thought_box.display_thought("S03_R1_VOICE")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	var r1_opts: Array = [
		{"text": "S03_R1_OPT_A"},
		{"text": "S03_R1_OPT_B"},
		{"text": "S03_R1_OPT_C"}
	]
	choice_menu.present_choices(r1_opts, "hesitant")
	await choice_menu.choice_made

	thought_box.display_thought("S03_R1_RES")
	await thought_box.text_completed
	await get_tree().create_timer(1.2).timeout

	# Putaran 2
	thought_box.display_thought("S03_R2_VOICE")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	var r2_opts: Array = [
		{"text": "S03_R2_OPT_A"},
		{"text": "S03_R2_OPT_B"},
		{"text": "S03_R2_OPT_C"}
	]
	choice_menu.present_choices(r2_opts, "convergent")
	await choice_menu.choice_made

	thought_box.display_thought("S03_R2_RES")
	await thought_box.text_completed
	await get_tree().create_timer(1.2).timeout

	# Putaran 3 (celah kecil)
	thought_box.display_thought("S03_R3_VOICE")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	var r3_opts: Array = [
		{"text": "S03_R3_OPT_A"},
		{"text": "S03_R3_OPT_B"},
		{"text": "S03_R3_OPT_C"}
	]
	choice_menu.present_choices(r3_opts, "convergent")
	var r3_choice: int = await choice_menu.choice_made

	if r3_choice == 0:
		thought_box.display_thought("S03_R3_RES_A")
		await thought_box.text_completed
		await get_tree().create_timer(1.0).timeout

	# Ponsel bergetar halus
	FlagStore.set_flag("heard_phone_buzz", true)
	AudioManager.play_vibrate()
	thought_box.display_thought("S03_R3_RES_COMMON")
	await thought_box.text_completed
	await get_tree().create_timer(1.5).timeout

	# Putaran 4 (penutup monolog)
	thought_box.display_thought("S03_R4_A01")
	await thought_box.text_completed
	await get_tree().create_timer(1.5).timeout

	thought_box.display_thought("S03_R4_A02")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout

	# Efek teks terhapus (anxiety backspace)
	thought_box.erase_thought(40.0)
	await thought_box.text_erased
	await get_tree().create_timer(0.6).timeout

	# Teks pengganti
	thought_box.display_thought("S03_R4_N01")
	await thought_box.text_completed
	await get_tree().create_timer(1.5).timeout

	thought_box.clear()
	AudioManager.stop_bgm(1.0)


## S08 — Bangun Lagi (hook akhir Bab 1)
func _start_s08_sequence() -> void:
	player.set_movement_enabled(false)

	# 1. Terapkan perubahan lingkungan berdasarkan flag Loop 1
	if FlagStore.get_flag("noticed_tea", false) and tea_node:
		tea_node.position += Vector2(14, -6)
	if FlagStore.get_flag("turned_photo", false) and photo_node:
		photo_node.rotation_degrees = -12.0

	transition_layer.cut_to_black()
	transition_layer.fade_from_black(3.0)
	AudioManager.play_rain(2.0)

	# 2. Jam muncul
	clock_label.text = "02:47"
	clock_label.visible = true

	await get_tree().create_timer(1.2).timeout
	thought_box.display_thought("S08_N01")
	await thought_box.text_completed
	await get_tree().create_timer(1.5).timeout

	thought_box.display_thought("S08_N02")
	await thought_box.text_completed
	await get_tree().create_timer(1.5).timeout

	# 3. Ponsel bergetar, nomor tak dikenal
	AudioManager.play_vibrate()
	thought_box.display_thought("S08_N03")
	await thought_box.text_completed
	await get_tree().create_timer(1.2).timeout
	thought_box.clear()

	# 4. Antarmuka chat nomor tak dikenal
	chat_ui.visible = true
	await chat_ui.post_message("???", "S08_MSG_1")
	await get_tree().create_timer(1.5).timeout

	await chat_ui.post_message("???", "S08_MSG_2")
	await get_tree().create_timer(2.0).timeout

	await chat_ui.post_message("???", "S08_MSG_3")
	await get_tree().create_timer(1.0).timeout

	# 5. Input balasan pemain
	var reply: String = await chat_ui.prompt_text_input("S08_INPUT_PROMPT")
	FlagStore.set_flag("loop1_player_reply", reply)

	# 6. Balasan tetap nomor tak dikenal
	await get_tree().create_timer(1.0).timeout
	await chat_ui.post_message("???", "S08_MSG_REPLY")
	FlagStore.set_flag("received_mystery_message", true)

	await get_tree().create_timer(2.0).timeout
	chat_ui.visible = false

	# 7. Label Loop Counter "LOOP 2/7" & Satu nada hangat
	AudioManager.play_warm_note(0.5)
	loop_counter_label.text = tr("S08_LOOP_LABEL")
	loop_counter_label.visible = true
	var tw_label := create_tween()
	tw_label.tween_property(loop_counter_label, "modulate:a", 0.0, 3.0)

	# 8. Fade out & selesaikan loop 1
	AudioManager.stop_bgm(3.0)
	AudioManager.stop_ambience(3.0)
	transition_layer.fade_to_black(3.0)
	await get_tree().create_timer(3.0).timeout

	LoopManager.end_current_loop()
