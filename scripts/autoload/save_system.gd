## SaveSystem — Autoload
## Simpan/muat progres ke user://saves/ dalam format JSON.
## Slot otomatis di awal tiap scene dan akhir tiap loop.
extends Node

const SAVE_DIR: String = "user://saves/"
const AUTO_SAVE_FILE: String = "autosave.json"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save_game(slot_name: String = AUTO_SAVE_FILE) -> Error:
	var data: Dictionary = _gather_save_data()
	var path: String = SAVE_DIR + slot_name
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: gagal membuka %s untuk menulis" % path)
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("SaveSystem: tersimpan ke %s" % path)
	return OK


func load_game(slot_name: String = AUTO_SAVE_FILE) -> Error:
	var path: String = SAVE_DIR + slot_name
	if not FileAccess.file_exists(path):
		push_warning("SaveSystem: file tidak ditemukan %s" % path)
		return ERR_FILE_NOT_FOUND
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var text: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	var err: Error = json.parse(text)
	if err != OK:
		push_error("SaveSystem: JSON parse error — %s" % json.get_error_message())
		return err
	var data: Dictionary = json.data
	_apply_save_data(data)
	print("SaveSystem: dimuat dari %s" % path)
	return OK


func has_save(slot_name: String = AUTO_SAVE_FILE) -> bool:
	return FileAccess.file_exists(SAVE_DIR + slot_name)


func delete_save(slot_name: String = AUTO_SAVE_FILE) -> Error:
	var path: String = SAVE_DIR + slot_name
	if FileAccess.file_exists(path):
		return DirAccess.remove_absolute(path)
	return OK


func list_saves() -> PackedStringArray:
	var saves: PackedStringArray = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return saves
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			saves.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return saves


func _gather_save_data() -> Dictionary:
	var data: Dictionary = {
		"save_version": 1,
		"timestamp": Time.get_datetime_string_from_system(),
		"flags": FlagStore.get_all_flags(),
	}
	# GameState belum ada di fase ini — akan ditambah nanti
	if Engine.has_singleton("GameState") or has_node("/root/GameState"):
		var gs: Node = get_node_or_null("/root/GameState")
		if gs:
			data["current_loop"] = gs.get("current_loop")
			data["current_scene_id"] = gs.get("current_scene_id")
	return data


func _apply_save_data(data: Dictionary) -> void:
	if data.has("flags") and data["flags"] is Dictionary:
		FlagStore.load_from_dict(data["flags"])
	var gs: Node = get_node_or_null("/root/GameState")
	if gs and data.has("current_loop"):
		gs.set("current_loop", data["current_loop"])
	if gs and data.has("current_scene_id"):
		gs.set("current_scene_id", data["current_scene_id"])
