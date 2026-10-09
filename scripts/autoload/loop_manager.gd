## LoopManager — Autoload
## Mengatur alur loop 1-7, menerapkan perubahan lingkungan per loop.
## Membaca data/loop_changes.json.
## Sinyal: loop_started(n), loop_ended(n)
extends Node

signal loop_started(loop_number: int)
signal loop_ended(loop_number: int)

const LOOP_CHANGES_PATH: String = "res://data/loop_changes.json"
const MAX_LOOPS: int = 7

var _loop_changes: Dictionary = {}


func _ready() -> void:
	_load_loop_changes()


func _load_loop_changes() -> void:
	if not FileAccess.file_exists(LOOP_CHANGES_PATH):
		push_warning("LoopManager: loop_changes.json belum ada — pakai default kosong")
		return
	var file := FileAccess.open(LOOP_CHANGES_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var err: Error = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("LoopManager: JSON parse error — %s" % json.get_error_message())
		return
	if json.data is Dictionary:
		_loop_changes = json.data


func start_loop(loop_number: int) -> void:
	GameState.current_loop = loop_number
	GameState.reset_for_new_loop()
	_apply_loop_changes(loop_number)
	AudioManager.set_leitmotif_stage(loop_number)
	loop_started.emit(loop_number)
	print("LoopManager: loop %d dimulai" % loop_number)


func end_current_loop() -> void:
	var n: int = GameState.current_loop
	SaveSystem.save_game("loop_%d_end.json" % n)
	loop_ended.emit(n)
	print("LoopManager: loop %d selesai" % n)
	if n < MAX_LOOPS:
		start_loop(n + 1)


func _apply_loop_changes(loop_number: int) -> void:
	var key: String = str(loop_number)
	if not _loop_changes.has(key):
		return
	var changes: Dictionary = _loop_changes[key]
	# Terapkan flag lingkungan dari data
	for flag_name: String in changes.keys():
		FlagStore.set_flag(flag_name, changes[flag_name])


func get_loop_data(loop_number: int) -> Dictionary:
	var key: String = str(loop_number)
	if _loop_changes.has(key):
		return _loop_changes[key]
	return {}


func is_final_loop() -> bool:
	return GameState.current_loop >= MAX_LOOPS
