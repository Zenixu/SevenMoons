## Test fungsional lorong apartemen + lift + alur lantai 5 (atap)
extends Node

const CORRIDOR_SCENE = preload("res://scenes/corridor/corridor.tscn")
const LIFT_SCENE = preload("res://scenes/lift/lift.tscn")


func _ready() -> void:
	print("=== TEST: LORONG APARTEMEN & LIFT ===")
	TranslationServer.set_locale("id")
	FlagStore.clear()

	await _test_interactables()
	await _test_elevator_opens_lift()
	await _test_neighbor_knock()
	await _test_stairs_dead_end()
	await _test_lift_floor_menu()

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

	for want in ["room_door", "stairs_door", "neighbor_a", "neighbor_b", "elevator"]:
		assert(found.has(want), "lorong: %s tidak ada" % want)

	assert(c.floor_label != null, "lorong: floor_label null")
	assert(c.floor_label.text.contains("3"), "lorong: label lantai awal harus 3")
	c.queue_free()
	print("    Interactables lorong: OK")


## Menekan lift harus MEMBUKA scene lift (pemain masuk), bukan langsung ganti lantai.
func _test_elevator_opens_lift() -> void:
	print("  - Menguji lift: masuk ke dalam lift (scene lift)...")
	FlagStore.set_flag("corridor_floor", 3)
	var c: CorridorController = CORRIDOR_SCENE.instantiate()
	c.auto_start = false
	c.navigate_scenes = false
	add_child(c)
	await get_tree().process_frame

	# Panggil handler lift; karena navigate_scenes=false, tidak ganti scene,
	# tapi flag lantai harus tetap 3 (tidak langsung naik).
	await c._handle_elevator()
	await get_tree().process_frame
	assert(int(FlagStore.get_flag("corridor_floor")) == 3,
		"lift: lantai tidak boleh berubah hanya dengan masuk lift")
	c.queue_free()
	print("    Lift membuka scene lift: OK")


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


## Di dalam lift: pilih lantai 5 (atap) harus menandai reached_floor5_balcony.
func _test_lift_floor_menu() -> void:
	print("  - Menguji peta lantai di dalam lift...")
	var old_speed: float = SettingsManager.text_speed
	SettingsManager.text_speed = 100.0

	FlagStore.set_flag("corridor_floor", 3)
	FlagStore.set_flag("reached_floor5_balcony", false)
	var l: LiftController = LIFT_SCENE.instantiate()
	l.auto_start = false
	l.navigate_scenes = false
	add_child(l)
	await get_tree().process_frame

	assert(l.get_node_or_null("Interactables/FloorPanel") != null,
		"lift: panel lantai tidak ada")

	# Pilih opsi ke-3 (lantai 5 = atap)
	l.choice_menu.visibility_changed.connect(func() -> void:
		if l.choice_menu.visible:
			get_tree().create_timer(0.02).timeout.connect(func() -> void:
				if is_instance_valid(l) and l.choice_menu.visible:
					l.choice_menu._on_button_pressed(2)
			)
	)
	await l._open_floor_menu()
	await get_tree().process_frame
	assert(int(FlagStore.get_flag("corridor_floor")) == 5,
		"lift: memilih lantai 5 harus set corridor_floor=5")
	assert(FlagStore.get_flag("reached_floor5_balcony", false) == true,
		"lift: memilih lantai 5 harus menandai reached_floor5_balcony")
	assert(FlagStore.get_flag("rooftop_from_lift", false) == true,
		"lift: harus menandai rooftop_from_lift agar monolog atap tampil")
	l.queue_free()

	SettingsManager.text_speed = old_speed
	print("    Peta lantai lift: OK")
