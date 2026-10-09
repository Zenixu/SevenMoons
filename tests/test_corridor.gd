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
	await _test_floor5_rooftop_flow()

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


## Lantai 5: pemain keluar lift, BERJALAN ke tengah, lalu cutscene rooftop.
func _test_floor5_rooftop_flow() -> void:
	print("  - Menguji alur lantai 5: jalan ke tengah -> cutscene rooftop...")
	var old_speed: float = SettingsManager.text_speed
	SettingsManager.text_speed = 100.0

	# Lantai 3: trigger atap tidak boleh aktif
	FlagStore.set_flag("corridor_floor", 3)
	var c3: CorridorController = CORRIDOR_SCENE.instantiate()
	c3.auto_start = false
	c3.navigate_scenes = false
	add_child(c3)
	await get_tree().process_frame
	assert(c3.roof_trigger.monitoring == false,
		"atap: trigger harus mati di lantai 3")
	await c3._handle_balcony_door()
	assert(FlagStore.get_flag("reached_floor5_balcony", false) == false,
		"atap: tidak boleh terbuka di lantai 3")
	c3.queue_free()
	await get_tree().process_frame

	# Lantai 5: trigger atap aktif, dan baru memicu saat pemain menyentuhnya
	FlagStore.set_flag("corridor_floor", 5)
	FlagStore.set_flag("reached_floor5_balcony", false)
	FlagStore.set_flag("corridor_seen_5", true)   # lewati intro lantai
	FlagStore.set_flag("corridor_from_elevator", true)   # baru naik lift
	var c5: CorridorController = CORRIDOR_SCENE.instantiate()
	c5.auto_start = false
	c5.navigate_scenes = false
	add_child(c5)
	await get_tree().process_frame
	assert(c5.roof_trigger.monitoring == true,
		"atap: trigger harus aktif di lantai 5")
	# Pemain muncul di dekat lift (kanan), bukan di tengah
	assert(c5.player.position.x > 700.0,
		"atap: pemain lantai 5 harus mulai dekat lift (kanan)")
	# Jalan ke tengah: pindahkan pemain ke area trigger, lalu picu
	c5.player.position = Vector2(580, 268)
	await c5._on_roof_trigger_entered(c5.player)
	assert(FlagStore.get_flag("reached_floor5_balcony", false) == true,
		"atap: cutscene lantai 5 harus memicu perjalanan ke rooftop")
	c5.queue_free()

	SettingsManager.text_speed = old_speed
	print("    Alur rooftop lantai 5: OK")
