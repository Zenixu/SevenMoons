## LiftController — Pengendali Interior Lift
## Pemain MASUK ke dalam lift lebih dulu (bukan langsung pindah lantai), lalu
## memilih tujuan dari PETA LANTAI di dinding: lantai 3, 4, atau 5 (atap).
## Lantai 5 membawa pemain langsung ke atap gedung (rooftop).
class_name LiftController
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
const FLOOR_MAX := 4          # lantai lorong tertinggi
const ROOF_FLOOR := 5         # lantai atap
const CORRIDOR_SCENE := "res://scenes/corridor/corridor.tscn"
const ROOFTOP_SCENE := "res://scenes/balcony/balcony.tscn"

var _current_floor: int = 3
var _is_busy: bool = false


func _ready() -> void:
	_current_floor = int(FlagStore.get_flag("corridor_floor", FLOOR_MIN))
	_current_floor = clampi(_current_floor, FLOOR_MIN, ROOF_FLOOR)

	player.position = Vector2(320, 300)
	_update_floor_label()

	transition_layer.cut_to_black()
	transition_layer.fade_from_black(1.2)
	AudioManager.play_rain(1.5)

	for child in interactables_parent.get_children():
		if child is Interactable:
			child.player_interacted.connect(_on_object_interacted)

	if auto_start:
		await _enter_lift()


func _update_floor_label() -> void:
	var shown: int = ROOF_FLOOR if _current_floor >= ROOF_FLOOR else _current_floor
	floor_label.text = "%s %d" % [tr("CORRIDOR_FLOOR"), shown]


func _enter_lift() -> void:
	player.set_movement_enabled(false)
	await get_tree().create_timer(0.5).timeout

	thought_box.display_thought("LIFT_ENTER")
	await thought_box.text_completed
	await get_tree().create_timer(1.0).timeout
	thought_box.clear()

	player.set_movement_enabled(true)
	hint_label.text = tr("LIFT_HINT")
	hint_label.visible = true

	# Beri jeda singkat agar pemain sempat "masuk", lalu buka peta lantai
	await get_tree().create_timer(1.4).timeout
	await _open_floor_menu()


func _on_object_interacted(obj_id: String) -> void:
	if _is_busy:
		return
	if obj_id == "floor_panel":
		await _open_floor_menu()


func _open_floor_menu() -> void:
	if _is_busy:
		return
	_is_busy = true
	hint_label.visible = false
	player.set_movement_enabled(false)

	await _say("LIFT_PANEL", 0.8)

	var opts: Array = [
		{"text": "LIFT_FLOOR_3"},
		{"text": "LIFT_FLOOR_4"},
		{"text": "LIFT_FLOOR_5"},
	]
	var targets: Array = [3, 4, ROOF_FLOOR]

	choice_menu.present_choices(opts, "normal")
	var idx: int = await choice_menu.choice_made
	var target: int = targets[idx]

	if target == _current_floor:
		await _say("LIFT_SAME_FLOOR", 1.0)
		thought_box.clear()
		player.set_movement_enabled(true)
		_is_busy = false
		return

	# Pintu besi menutup, lantai bergeser
	await _say("CORRIDOR_LIFT_MOVE", 1.2)
	thought_box.clear()

	if target == ROOF_FLOOR:
		FlagStore.set_flag("corridor_floor", ROOF_FLOOR)
		FlagStore.set_flag("reached_floor5_balcony", true)
		FlagStore.set_flag("rooftop_from_lift", true)
		await _go_to(ROOFTOP_SCENE)
	else:
		FlagStore.set_flag("corridor_floor", target)
		FlagStore.set_flag("corridor_from_elevator", true)
		await _go_to(CORRIDOR_SCENE)

	# Jika navigate_scenes=false (mode uji), pulihkan keadaan
	player.set_movement_enabled(true)
	_is_busy = false


func _say(key: String, wait: float = 1.0) -> void:
	thought_box.display_thought(key)
	await thought_box.text_completed
	await get_tree().create_timer(wait).timeout


func _go_to(scene_path: String) -> void:
	thought_box.clear()
	if not navigate_scenes:
		return
	transition_layer.fade_to_black(1.0)
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file(scene_path)
