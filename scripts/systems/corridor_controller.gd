## CorridorController — Pengendali Lorong Apartemen (lantai 3-5)
## Pemain keluar dari kamar, berkeliling lorong: pintu tetangga (tidak bisa
## dibuka, hanya bisa diketuk), tangga turun (jalan buntu), dan lift untuk
## naik lantai satu-satu (3 -> 4 -> 5) dengan dialog tiap lantai.
##
## Lantai 5: pemain keluar lift di ujung kanan, lalu HARUS BERJALAN ke tengah
## lorong. Saat tiba di pintu kaca atap, barulah cutscene menuju rooftop
## (adegan S04-S06) dipicu.
class_name CorridorController
extends Node2D

@onready var player: PlayerCharacter = $Player
@onready var thought_box: ThoughtBox = $UI/ThoughtBox
@onready var choice_menu: ChoiceMenu = $UI/ChoiceMenu
@onready var transition_layer: TransitionLayer = $UI/TransitionLayer
@onready var floor_label: Label = $UI/FloorLabel
@onready var hint_label: Label = $UI/HintLabel
@onready var interactables_parent: Node2D = $Interactables
@onready var roof_trigger: Area2D = $RoofTrigger

@export var auto_start: bool = true
@export var navigate_scenes: bool = true

const FLOOR_MIN := 3
const FLOOR_MAX := 5
const BEDROOM_SCENE := "res://scenes/bedroom/bedroom.tscn"
const CORRIDOR_SCENE := "res://scenes/corridor/corridor.tscn"
const BALCONY_SCENE := "res://scenes/balcony/balcony.tscn"

# Dialog tiap lantai (lebih dari satu baris, bukan cuma satu-dua kata)
const FLOOR_INTRO: Dictionary = {
	3: ["CORRIDOR_F3_INTRO", "CORRIDOR_F3_INTRO2", "CORRIDOR_F3_INTRO3"],
	4: ["CORRIDOR_F4_ARRIVE", "CORRIDOR_F4_ARRIVE2", "CORRIDOR_F4_ARRIVE3"],
	5: ["CORRIDOR_F5_ARRIVE", "CORRIDOR_F5_ARRIVE2", "CORRIDOR_F5_ARRIVE3"],
}

# Cutscene singkat saat tiba di pintu kaca atap (lantai 5)
const ROOF_CUTSCENE: Array[String] = [
	"CORRIDOR_F5_ROOF_1",
	"CORRIDOR_F5_ROOF_2",
	"CORRIDOR_F5_ROOF_3",
]

var _floor: int = 3
var _is_busy: bool = false
var _roof_entered: bool = false


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

	# Trigger atap hanya aktif di lantai 5
	roof_trigger.monitoring = (_floor == FLOOR_MAX)
	roof_trigger.body_entered.connect(_on_roof_trigger_entered)

	if auto_start:
		_announce_floor()


## Taruh pemain dekat pintu kamar (baru keluar) atau dekat lift (baru naik).
func _place_player() -> void:
	var from_elevator: bool = FlagStore.get_flag("corridor_from_elevator", false)
	if from_elevator:
		# Keluar lift di ujung kanan lorong; harus berjalan ke tengah (x~580)
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

	# Petunjuk halus khusus lantai 5: dorong pemain berjalan ke tengah
	if _floor == FLOOR_MAX:
		hint_label.text = tr("CORRIDOR_F5_HINT")
		hint_label.visible = true

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
		"balcony_door":
			await _handle_balcony_door()

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
	AudioManager.play_typing_sfx()
	await _say("CORRIDOR_NEIGHBOR_KNOCK", 1.4)
	await _say("CORRIDOR_NEIGHBOR_KNOCK2", 1.0)
	thought_box.clear()


## Pintu kaca atap: di lantai 5 hanya menampilkan deskripsi (cutscene dipicu
## saat pemain berjalan ke tengah). Di lantai lain sekadar catatan.
func _handle_balcony_door() -> void:
	if _floor != FLOOR_MAX:
		await _say("CORRIDOR_BALCONY_F5_OTHER", 0.9)
		thought_box.clear()
		return
	await _say("CORRIDOR_BALCONY_F5_DOOR", 0.9)
	thought_box.clear()


## Berjalan ke tengah lorong di lantai 5 -> cutscene atap -> rooftop.
func _on_roof_trigger_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if _floor != FLOOR_MAX or _roof_entered or _is_busy:
		return
	_roof_entered = true
	roof_trigger.monitoring = false
	await _start_rooftop_cutscene()


func _start_rooftop_cutscene() -> void:
	_is_busy = true
	player.set_movement_enabled(false)
	hint_label.visible = false

	# Hentikan langkah, hadapkan pemain ke pintu kaca
	player.velocity = Vector2.ZERO

	# Efek dramatis: vignette menguat + hujan sedikit lebih keras
	transition_layer.set_vignette(0.45, 1.5)
	AudioManager.play_rain(1.5)

	await get_tree().create_timer(0.6).timeout

	# Dialog cutscene (beberapa baris, bukan satu-dua kata)
	for line in ROOF_CUTSCENE:
		thought_box.display_thought(line)
		await thought_box.text_completed
		await get_tree().create_timer(1.5).timeout
	thought_box.clear()

	FlagStore.set_flag("reached_floor5_balcony", true)

	# Jeda hening, lalu fade ke rooftop
	await get_tree().create_timer(0.8).timeout
	_is_busy = false
	await _go_to(BALCONY_SCENE)


func _handle_elevator() -> void:
	await _say("CORRIDOR_LIFT", 0.8)

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
		await _say("CORRIDOR_LIFT_STAY_RES", 1.0)
		thought_box.clear()
		return

	# Naik/turun satu lantai: dialog singkat di dalam lift
	await _say("CORRIDOR_LIFT_MOVE", 1.2)
	FlagStore.set_flag("corridor_floor", target)
	FlagStore.set_flag("corridor_from_elevator", true)
	await _go_to(CORRIDOR_SCENE)


func _go_to(scene_path: String) -> void:
	thought_box.clear()
	if not navigate_scenes:
		return
	transition_layer.fade_to_black(1.0)
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file(scene_path)
