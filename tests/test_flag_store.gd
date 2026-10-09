## Test scene untuk FlagStore
## Jalankan scene ini untuk menguji API FlagStore.
extends Node

func _ready() -> void:
	print("=== TEST: FlagStore ===")

	# Test set & get
	FlagStore.set_flag("test_bool", true)
	assert(FlagStore.get_flag("test_bool") == true, "set_flag/get_flag bool gagal")

	FlagStore.set_flag("test_string", "hello")
	assert(FlagStore.get_flag("test_string") == "hello", "set_flag/get_flag string gagal")

	FlagStore.set_flag("test_int", 42)
	assert(FlagStore.get_flag("test_int") == 42, "set_flag/get_flag int gagal")

	# Test has_flag
	assert(FlagStore.has_flag("test_bool") == true, "has_flag gagal (ada)")
	assert(FlagStore.has_flag("nonexistent") == false, "has_flag gagal (tidak ada)")

	# Test default
	assert(FlagStore.get_flag("nonexistent", "default") == "default", "get_flag default gagal")

	# Test sinyal
	var signal_ctx: Dictionary = {"received": false, "name": "", "value": null}
	FlagStore.flag_changed.connect(func(n: String, v: Variant) -> void:
		signal_ctx["received"] = true
		signal_ctx["name"] = n
		signal_ctx["value"] = v
	)
	FlagStore.set_flag("signal_test", "abc")
	assert(signal_ctx["received"] == true, "signal flag_changed tidak terpancar")
	assert(signal_ctx["name"] == "signal_test", "signal name salah")
	assert(signal_ctx["value"] == "abc", "signal value salah")

	# Test remove
	FlagStore.remove_flag("test_bool")
	assert(FlagStore.has_flag("test_bool") == false, "remove_flag gagal")

	# Test get_all_flags
	var all: Dictionary = FlagStore.get_all_flags()
	assert(all.has("test_string"), "get_all_flags tidak lengkap")

	# Test load_from_dict
	FlagStore.load_from_dict({"loaded": true, "count": 5})
	assert(FlagStore.get_flag("loaded") == true, "load_from_dict gagal")
	assert(FlagStore.has_flag("test_string") == false, "load_from_dict tidak mengganti")

	# Test clear
	FlagStore.clear()
	assert(FlagStore.get_all_flags().size() == 0, "clear gagal")

	print("=== SEMUA TEST FlagStore LULUS ===")
