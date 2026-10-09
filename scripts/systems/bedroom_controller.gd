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

@onready var interactables_parent: Node2D = $Interactables
@onready var balcony_trigger: Area2D = $BalconyTrigger

@export var auto_start_intro: bool = true

var _inspected_objects: Dictionary = {}
var _is_interacting: bool = false
var _balcony_unlocked: bool = false


func _ready() -> void:
	clock_label.visible = false
	balcony_trigger.monitoring = false
	balcony_trigger.body_entered.connect(_on_balcony_trigger_entered)

	for child in interactables_parent.get_children():
		if child is Interactable:
			child.player_interacted.connect(_on_object_interacted)

	# Mulai dari S01 (intro) jika diizinkan
	if auto_start_intro:
		_start_s01_intro()


func _start_s01_intro() -> void:
	player.set_movement_enabled(false)
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
		exploration_completed.emit()
		# Pindah ke balkon
		if get_tree().change_scene_to_file("res://scenes/balcony/balcony.tscn") != OK:
			push_warning("Balkon scene belum aktif secara file swap")
