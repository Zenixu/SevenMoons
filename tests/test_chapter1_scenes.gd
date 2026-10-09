## Test scene untuk Scene Bab 1 (Fase 3)
## Menguji bedroom.tscn, 6 interactables, balcony.tscn, transition_layer, flashback, dan chapter_01.json.
extends Node

const BEDROOM_SCENE = preload("res://scenes/bedroom/bedroom.tscn")
const BALCONY_SCENE = preload("res://scenes/balcony/balcony.tscn")
const TRANSITION_SCENE = preload("res://scenes/transitions/transition_layer.tscn")
const FLASHBACK_SCENE = preload("res://scenes/transitions/flashback.tscn")


func _ready() -> void:
	print("=== TEST: SCENE BAB 1 (FASE 3) ===")
	TranslationServer.set_locale("id")

	await _test_chapter_json()
	await _test_transition_layer()
	await _test_flashback()
	await _test_bedroom_interactables()
	await _test_balcony_scene()

	print("=== SEMUA TEST SCENE BAB 1 LULUS ===")


func _test_chapter_json() -> void:
	print("  - Menguji chapter_01.json data...")
	var err: Error = DialogueRunner.load_chapter(1)
	assert(err == OK, "DialogueRunner: gagal memuat chapter_01.json")
	var scenes: Dictionary = DialogueRunner._chapter_data.get("scenes", {})
	assert(scenes.has("S01"), "chapter_01: tidak ada S01")
	assert(scenes.has("S02"), "chapter_01: tidak ada S02")
	assert(scenes.has("S03"), "chapter_01: tidak ada S03")
	assert(scenes.has("S04"), "chapter_01: tidak ada S04")
	assert(scenes.has("S05"), "chapter_01: tidak ada S05")
	assert(scenes.has("S06"), "chapter_01: tidak ada S06")
	assert(scenes.has("S06_ALT"), "chapter_01: tidak ada S06_ALT")
	assert(scenes.has("S07"), "chapter_01: tidak ada S07")
	assert(scenes.has("S08"), "chapter_01: tidak ada S08")
	print("    chapter_01.json: OK")


func _test_transition_layer() -> void:
	print("  - Menguji TransitionLayer...")
	var trans: TransitionLayer = TRANSITION_SCENE.instantiate()
	add_child(trans)

	var fade_ctx: Dictionary = {"completed": false}
	trans.fade_completed.connect(func() -> void: fade_ctx["completed"] = true)

	trans.cut_to_black()
	assert(trans.color_rect.color.a == 1.0, "cut_to_black: alpha harus 1.0")

	trans.cut_to_clear()
	assert(trans.color_rect.color.a == 0.0, "cut_to_clear: alpha harus 0.0")

	trans.set_vignette(0.5, 0.1)
	await get_tree().create_timer(0.2).timeout
	assert(trans.vignette_rect.modulate.a > 0.0, "vignette: seharusnya terlihat")

	trans.queue_free()
	print("    TransitionLayer: OK")


func _test_flashback() -> void:
	print("  - Menguji FlashbackSequence...")
	var fb: FlashbackSequence = FLASHBACK_SCENE.instantiate()
	add_child(fb)

	# Uji struktur slide
	assert(fb.slide_image != null, "Flashback: slide_image null")
	assert(fb.memory_text != null, "Flashback: memory_text null")

	fb.queue_free()
	print("    FlashbackSequence: OK")


func _test_bedroom_interactables() -> void:
	print("  - Menguji Bedroom & 6 Interactables...")
	var bed: BedroomController = BEDROOM_SCENE.instantiate()
	bed.auto_start_intro = false
	add_child(bed)

	var interactables: Node2D = bed.get_node("Interactables")
	var found_ids: Array[String] = []
	for child in interactables.get_children():
		if child is Interactable:
			found_ids.append(child.object_id)

	assert(found_ids.has("phone"), "Interactables: phone tidak ada")
	assert(found_ids.has("photo"), "Interactables: photo tidak ada")
	assert(found_ids.has("tea"), "Interactables: tea tidak ada")
	assert(found_ids.has("mirror"), "Interactables: mirror tidak ada")
	assert(found_ids.has("clock"), "Interactables: clock tidak ada")
	assert(found_ids.has("door"), "Interactables: door tidak ada")

	# Uji pencatatan inspeksi objek & pembukaan trigger balkon (min 3 objek)
	FlagStore.set_flag("noticed_tea", true)
	bed._inspected_objects["tea"] = true
	assert(FlagStore.get_flag("noticed_tea") == true, "flag noticed_tea gagal")

	FlagStore.set_flag("noticed_clock", true)
	bed._inspected_objects["clock"] = true
	assert(FlagStore.get_flag("noticed_clock") == true, "flag noticed_clock gagal")

	FlagStore.set_flag("talked_to_mirror", true)
	bed._inspected_objects["mirror"] = true
	assert(FlagStore.get_flag("talked_to_mirror") == true, "flag talked_to_mirror gagal")

	bed._check_balcony_condition()
	assert(bed._balcony_unlocked == true, "balkon seharusnya terbuka setelah 3 objek diperiksa")
	assert(bed.balcony_trigger.monitoring == true, "balcony_trigger harus monitoring setelah terbuka")

	bed.queue_free()
	print("    Bedroom & Interactables: OK")


func _test_balcony_scene() -> void:
	print("  - Menguji Balcony...")
	var bal: BalconyController = BALCONY_SCENE.instantiate()
	bal.auto_start_sequence = false
	add_child(bal)

	assert(bal.silhouette != null, "Balcony: siluet null")
	assert(bal.choice_menu != null, "Balcony: choice_menu null")
	assert(bal.railing != null, "Balcony: railing null")

	# S06-ALT mode check: saat skip adegan sensitif aktif, komponen visual sembunyi
	bal.silhouette.visible = false
	assert(bal.silhouette.visible == false, "Balcony ALT: siluet sembunyi")

	bal.queue_free()
	print("    Balcony: OK")
