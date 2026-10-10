## CorridorController — Pengendali Lorong Apartemen (lantai 3-4)
## Pemain keluar dari kamar, berkeliling lorong: pintu tetangga (tidak bisa
## dibuka, hanya bisa diketuk), tangga turun (jalan buntu), dan LIFT.
##
## Menekan lift TIDAK lagi langsung memindah lantai: pemain MASUK ke dalam
## lift (scene lift.tscn) lalu memilih lantai dari peta di dalamnya.
## Lantai 5 = atap gedung (langsung ke rooftop, bukan lorong berpintu).
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
const FLOOR_MAX := 4
const BEDROOM_SCENE := "res://scenes/bedroom/bedroom.tscn"
const CORRIDOR_SCENE := "res://scenes/corridor/corridor.tscn"
const LIFT_SCENE := "res://scenes/lift/lift.tscn"

# Dialog tiap lantai (lebih dari satu baris, bukan cuma satu-dua kata)
const FLOOR_INTRO: Dictionary = {
	3: ["CORRIDOR_F3_INTRO", "CORRIDOR_F3_INTRO2", "CORRIDOR_F3_INTRO3"],
	4: ["CORRIDOR_F4_ARRIVE", "CORRIDOR_F4_ARRIVE2", "CORRIDOR_F4_ARRIVE3"],
}

var _floor: int = 3
var _is_busy: bool = false


func _ready() -> void:
	_floor = int(FlagStore.get_flag("corridor_floor", FLOOR_MIN))
	_floor = clampi(_floor, FLOOR_MIN, FLOOR_MAX)
	_update_floor_visuals()
	_place_player()

	transition_layer.cut_to_black()
	transition_layer.fade_from_black(1.5)
	AudioManager.play_rain(2.0)
	AudioManager.stop_clock_tick(0.5)

	for child in interactables_parent.get_children():
		if child is Interactable:
			child.player_interacted.connect(_on_object_interacted)

	if auto_start:
		_announce_floor()


## Taruh pemain dekat pintu kamar (baru keluar) atau dekat lift (baru naik).
func _place_player() -> void:
	var from_elevator: bool = FlagStore.get_flag("corridor_from_elevator", false)
	if from_elevator:
		# Keluar lift di ujung kanan lorong
		player.position = Vector2(880, 268)
		FlagStore.set_flag("corridor_from_elevator", false)
	else:
		player.position = Vector2(150, 268)


func _update_floor_visuals() -> void:
	floor_label.text = "%s %d" % [tr("CORRIDOR_FLOOR"), _floor]
	hint_label.visible = false


func _announce_floor() -> void:
	player.set_movement_enabled(false)
	await get_tree().create_timer(0.6).timeout

	var seen_key: String = "corridor_seen_%d" % _floor
	var lines: Array = FLOOR_INTRO.get(_floor, [])
	if not FlagStore.get_flag(seen_key, false) and not lines.is_empty():
		FlagStore.set_flag(seen_key, true)
		for line in lines:
			thought_box.display_thought(line)
			await thought_box.text_completed
			await get_tree().create_timer(1.3).timeout
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


func _say(key: String, wait: float = 1.0) -> void:
	thought_box.display_thought(key)
	await thought_box.text_completed
	await get_tree().create_timer(wait).timeout


func _handle_room_door() -> void:
	if _floor == FLOOR_MIN:
		await _say("CORRIDOR_ROOM_DOOR", 0.8)
		thought_box.clear()
		FlagStore.set_flag("corridor_from_elevator", false)
		await _go_to(BEDROOM_SCENE)
	else:
		await _say("CORRIDOR_ROOM_OTHER", 0.8)
		thought_box.clear()


func _handle_stairs() -> void:
	await _say("CORRIDOR_STAIRS", 1.0)
	await _say("CORRIDOR_STAIRS_RES", 1.2)
	thought_box.clear()


func _handle_neighbor() -> void:
	await _say("CORRIDOR_NEIGHBOR", 0.9)
	AudioManager.play_knock()
	await get_tree().create_timer(0.5).timeout
	AudioManager.play_knock()
	await _say("CORRIDOR_NEIGHBOR_KNOCK", 1.4)
	await _say("CORRIDOR_NEIGHBOR_KNOCK2", 1.0)
	thought_box.clear()


## Lift: pemain MASUK ke dalam lift. Di dalam, pemain memilih lantai dari peta.
func _handle_elevator() -> void:
	await _say("CORRIDOR_LIFT", 0.8)
	thought_box.clear()
	FlagStore.set_flag("corridor_floor", _floor)
	await _go_to(LIFT_SCENE)


func _go_to(scene_path: String) -> void:
	thought_box.clear()
	if not navigate_scenes:
		return
	transition_layer.fade_to_black(1.0)
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file(scene_path)
