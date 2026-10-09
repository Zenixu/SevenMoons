## FlagStore — Autoload
## Menyimpan flag/state pilihan pemain selama game berjalan.
## API: set_flag(), get_flag(), has_flag(), clear(), get_all_flags()
## Sinyal: flag_changed(name, value)
extends Node

signal flag_changed(flag_name: String, value: Variant)

var _flags: Dictionary = {}


func set_flag(flag_name: String, value: Variant = true) -> void:
	var old_value: Variant = _flags.get(flag_name)
	_flags[flag_name] = value
	if old_value != value:
		flag_changed.emit(flag_name, value)


func get_flag(flag_name: String, default: Variant = null) -> Variant:
	return _flags.get(flag_name, default)


func has_flag(flag_name: String) -> bool:
	return _flags.has(flag_name)


func remove_flag(flag_name: String) -> void:
	if _flags.has(flag_name):
		_flags.erase(flag_name)
		flag_changed.emit(flag_name, null)


func clear() -> void:
	_flags.clear()


func get_all_flags() -> Dictionary:
	return _flags.duplicate()


func load_from_dict(data: Dictionary) -> void:
	_flags = data.duplicate()
