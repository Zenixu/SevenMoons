## CorridorController — Pengendali Lorong Apartemen (lantai 3-5)
## Pemain keluar dari kamar, berkeliling lorong: pintu tetangga (tidak bisa
## dibuka, hanya bisa diketuk), tangga turun (jalan buntu), dan lift untuk
## naik lantai satu-satu (3 -> 4 -> 5) dengan dialog tiap lantai.
class_name CorridorController
extends Node2D

@onready var player: PlayerCharacter = $Player
@onready var thought_box: ThoughtBox = $UI/ThoughtBox
@onready var choice_menu: ChoiceMenu = $UI/ChoiceMenu
@onready var transition_layer: TransitionLayer = $UI/TransitionLayer
@onready var floor_label: Label = $UI/FloorLabel
@onready var hint_label: Label = $UI/HintLabel
@onready var interactables_parent: Node2D = $Interactables

@export var auto_start: bool = true
@export var navigate_scenes: bool = true

const FLOOR_MIN := 3
const FLOOR_MAX := 5
const BEDROOM_SCENE := "res://scenes/bedroom/bedroom.tscn"
const CORRIDOR_SCENE := "res://scenes/corridor/corridor.tscn"

var _floor: int = 3
var _is_busy: bool = false


func _ready() -> void:
	_floor = int(FlagStore.get_flag("corridor_floor", FLOOR_MIN))
	_floor = clampi(_floor, FLOOR_MIN, FLOOR_MAX)
	_update_floor_visuals()

	transition_layer.cut_to_black()
	transition_layer.fade_from_black(1.5)
	AudioManager.play_rain(2.0)

	for child in interactables_parent.get_children():
		if child is Interactable:
			child.player_interacted.connect(_on_object_interacted)

	if auto_start:
		_announce_floor()


func _update_floor_visuals() -> void:
	floor_label.text = "%s %d" % [tr("CORRIDOR_FLOOR"), _floor]
	hint_label.visible = false


func _announce_floor() -> void:
	player.set_movement_enabled(false)
	await get_tree().create_timer(0.6).timeout

	var key: String = ""
	var seen_key: String = "corridor_seen_%d" % _floor
	if not FlagStore.get_flag(seen_key, false):
		FlagStore.set_flag(seen_key, true)
		if _floor == FLOOR_MIN:
			key = "CORRIDOR_F3_INTRO"
		elif _floor == 4:
			key = "CORRIDOR_F4_ARRIVE"
		else:
			key = "CORRIDOR_F5_ARRIVE"

	if not key.is_empty():
		thought_box.display_thought(key)
		await thought_box.text_completed
		await get_tree().create_timer(1.2).timeout
		thought_box.clear()

	player.set_movement_enabled(true)


func _on_object_interacted(obj_id: String) -> void:
	if _is_busy:
		return
	_is_busy = true
	player.set_movement_enabled(false)

	match obj_id:
		"room_door":
			await _handle_room_door()
		"stairs_door":
			await _handle_stairs()
		"neighbor_a", "neighbor_b":
			await _handle_neighbor()
		"elevator":
			await _handle_elevator()

	player.set_movement_enabled(true)
	_is_busy = false


func _handle_room_door() -> void:
	if _floor == FLOOR_MIN:
		thought_box.display_thought("CORRIDOR_ROOM_DOOR")
		await thought_box.text_completed
		await get_tree().create_timer(0.8).timeout
		thought_box.clear()
		await _go_to(BEDROOM_SCENE)
	else:
		thought_box.display_thought("CORRIDOR_ROOM_OTHER")
		await thought_box.text_completed
		await get_tree().create_timer(0.8).timeout
		thought_box.clear()


func _handle_stairs() -> void:
	thought_box.display_thought("CORRIDOR_STAIRS")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout
	thought_box.display_thought("CORRIDOR_STAIRS_RES")
	await thought_box.text_completed
	await get_tree().create_timer(1.2).timeout
	thought_box.clear()


func _handle_neighbor() -> void:
	thought_box.display_thought("CORRIDOR_NEIGHBOR")
	await thought_box.text_completed
	await get_tree().create_timer(0.9).timeout
	AudioManager.play_typing_sfx()
	thought_box.display_thought("CORRIDOR_NEIGHBOR_KNOCK")
	await thought_box.text_completed
	await get_tree().create_timer(1.4).timeout
	thought_box.display_thought("CORRIDOR_NEIGHBOR_KNOCK2")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout
	thought_box.clear()


func _handle_elevator() -> void:
	thought_box.display_thought("CORRIDOR_LIFT")
	await thought_box.text_completed
	await get_tree().create_timer(0.8).timeout

	var opts: Array = []
	var targets: Array = []
	if _floor > FLOOR_MIN:
		opts.append({"text": "CORRIDOR_LIFT_DOWN"})
		targets.append(_floor - 1)
	if _floor < FLOOR_MAX:
		opts.append({"text": "CORRIDOR_LIFT_UP"})
		targets.append(_floor + 1)
	if opts.is_empty():
		opts.append({"text": "CORRIDOR_LIFT_STAY"})
		targets.append(_floor)

	choice_menu.present_choices(opts, "normal")
	var idx: int = await choice_menu.choice_made
	var target: int = targets[idx]

	if target == _floor:
		thought_box.display_thought("CORRIDOR_LIFT_STAY_RES")
		await thought_box.text_completed
		await get_tree().create_timer(1.0).timeout
		thought_box.clear()
		return

	# Naik/turun satu lantai: dialog singkat di dalam lift
	thought_box.display_thought("CORRIDOR_LIFT_MOVE")
	await thought_box.text_completed
	FlagStore.set_flag("corridor_floor", target)
	await _go_to(CORRIDOR_SCENE)


func _go_to(scene_path: String) -> void:
	thought_box.clear()
	if not navigate_scenes:
		return
	transition_layer.fade_to_black(1.0)
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file(scene_path)
