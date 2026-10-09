## Test fungsional lorong apartemen (Fase 5 - Koridor)
extends Node

const CORRIDOR_SCENE = preload("res://scenes/corridor/corridor.tscn")


func _ready() -> void:
	print("=== TEST: LORONG APARTEMEN ===")
	TranslationServer.set_locale("id")
	FlagStore.clear()

	await _test_interactables()
	await _test_elevator_floor_progression()
	await _test_neighbor_knock()
	await _test_stairs_dead_end()
	await _test_floor5_balcony_door()

	print("=== SEMUA TEST LORONG LULUS ===")
	get_tree().quit(0)


func _test_interactables() -> void:
	print("  - Menguji interactables lorong...")
	var c: CorridorController = CORRIDOR_SCENE.instantiate()
	c.auto_start = false
	c.navigate_scenes = false
	add_child(c)
	await get_tree().process_frame

	var found: Array[String] = []
	for child in c.get_node("Interactables").get_children():
		if child is Interactable:
			found.append(child.object_id)

	for want in ["room_door", "stairs_door", "neighbor_a", "neighbor_b", "elevator", "balcony_door"]:
		assert(found.has(want), "lorong: %s tidak ada" % want)

	assert(c.floor_label != null, "lorong: floor_label null")
	assert(c.floor_label.text.contains("3"), "lorong: label lantai awal harus 3")
	c.queue_free()
	print("    Interactables lorong: OK")


func _test_elevator_floor_progression() -> void:
	print("  - Menguji lift: naik lantai 3 -> 4 -> 5...")
	FlagStore.set_flag("corridor_floor", 3)

	# Lantai 3: pilih "naik" -> target lantai 4
	var c: CorridorController = CORRIDOR_SCENE.instantiate()
	c.auto_start = false
	c.navigate_scenes = false
	add_child(c)
	await get_tree().process_frame

	# Tangkap target saat memilih opsi naik
	c.choice_menu.visibility_changed.connect(func() -> void:
		if c.choice_menu.visible:
			get_tree().create_timer(0.02).timeout.connect(func() -> void:
				if is_instance_valid(c) and c.choice_menu.visible:
					c.choice_menu._on_button_pressed(0)
			)
	)

	# Jalankan hanya bagian pemilihan (tanpa change_scene): panggil handler
	await c._handle_elevator()
	await get_tree().process_frame

	# Setelah memilih "naik", flag lantai harus jadi 4
	assert(int(FlagStore.get_flag("corridor_floor")) == 4,
		"lift: setelah naik dari 3, lantai harus 4 (dapat %s)" % FlagStore.get_flag("corridor_floor"))
	c.queue_free()
	print("    Lift naik 3->4: OK")


func _test_neighbor_knock() -> void:
	print("  - Menguji ketuk pintu tetangga (tetap tertutup)...")
	var c: CorridorController = CORRIDOR_SCENE.instantiate()
	c.auto_start = false
	c.navigate_scenes = false
	add_child(c)
	await get_tree().process_frame
	var old_speed: float = SettingsManager.text_speed
	SettingsManager.text_speed = 100.0
	await c._handle_neighbor()
	SettingsManager.text_speed = old_speed
	# Tidak ada flag terbuka; hanya memastikan tidak error
	assert(c.thought_box != null, "tetangga: thought_box null")
	c.queue_free()
	print("    Ketuk pintu tetangga: OK")


func _test_stairs_dead_end() -> void:
	print("  - Menguji tangga (jalan buntu)...")
	var c: CorridorController = CORRIDOR_SCENE.instantiate()
	c.auto_start = false
	c.navigate_scenes = false
	add_child(c)
	await get_tree().process_frame
	var old_speed: float = SettingsManager.text_speed
	SettingsManager.text_speed = 100.0
	await c._handle_stairs()
	SettingsManager.text_speed = old_speed
	assert(c.thought_box != null, "tangga: thought_box null")
	c.queue_free()
	print("    Tangga buntu: OK")


## Lantai 5: pintu balkon menawarkan pilihan; lantai lain menolak.
func _test_floor5_balcony_door() -> void:
	print("  - Menguji pintu balkon lantai 5...")
	var old_speed: float = SettingsManager.text_speed
	SettingsManager.text_speed = 100.0

	# Lantai 3: pintu balkon tidak membuka
	FlagStore.set_flag("corridor_floor", 3)
	var c3: CorridorController = CORRIDOR_SCENE.instantiate()
	c3.auto_start = false
	c3.navigate_scenes = false
	add_child(c3)
	await get_tree().process_frame
	await c3._handle_balcony_door()
	assert(FlagStore.get_flag("reached_floor5_balcony", false) == false,
		"balkon: tidak boleh terbuka di lantai 3")
	c3.queue_free()

	# Lantai 5: pemain memilih "Buka pintu kaca" (opsi 0)
	FlagStore.set_flag("corridor_floor", 5)
	FlagStore.set_flag("reached_floor5_balcony", false)
	var c5: CorridorController = CORRIDOR_SCENE.instantiate()
	c5.auto_start = false
	c5.navigate_scenes = false
	add_child(c5)
	await get_tree().process_frame
	c5.choice_menu.visibility_changed.connect(func() -> void:
		if c5.choice_menu.visible:
			get_tree().create_timer(0.02).timeout.connect(func() -> void:
				if is_instance_valid(c5) and c5.choice_menu.visible:
					c5.choice_menu._on_button_pressed(0)
			)
	)
	await c5._handle_balcony_door()
	assert(FlagStore.get_flag("reached_floor5_balcony", false) == true,
		"balkon: lantai 5 harus bisa menuju balkon")
	c5.queue_free()

	SettingsManager.text_speed = old_speed
	print("    Pintu balkon lantai 5: OK")
