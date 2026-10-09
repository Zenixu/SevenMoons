## Test scene untuk SaveSystem
extends Node

func _ready() -> void:
	print("=== TEST: SaveSystem ===")

	# Setup: bersihkan save lama
	SaveSystem.delete_save("test_save.json")

	# Test has_save sebelum menyimpan
	assert(SaveSystem.has_save("test_save.json") == false, "has_save awal gagal")

	# Atur flag lalu simpan
	FlagStore.clear()
	FlagStore.set_flag("test_flag", "value_A")
	FlagStore.set_flag("inspected_phone", true)
	var err: Error = SaveSystem.save_game("test_save.json")
	assert(err == OK, "save_game gagal: %s" % error_string(err))

	# Verifikasi file ada
	assert(SaveSystem.has_save("test_save.json") == true, "has_save setelah simpan gagal")

	# Bersihkan flag lalu muat
	FlagStore.clear()
	assert(FlagStore.get_all_flags().size() == 0, "clear gagal")
	err = SaveSystem.load_game("test_save.json")
	assert(err == OK, "load_game gagal: %s" % error_string(err))
	assert(FlagStore.get_flag("test_flag") == "value_A", "flag tidak termuat")
	assert(FlagStore.get_flag("inspected_phone") == true, "flag bool tidak termuat")

	# Test list_saves
	var saves: PackedStringArray = SaveSystem.list_saves()
	assert(saves.size() >= 1, "list_saves kosong")

	# Cleanup
	SaveSystem.delete_save("test_save.json")
	assert(SaveSystem.has_save("test_save.json") == false, "delete_save gagal")

	print("=== SEMUA TEST SaveSystem LULUS ===")
