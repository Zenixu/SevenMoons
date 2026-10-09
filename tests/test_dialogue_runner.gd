## Test scene untuk DialogueRunner
## Memuat chapter test mini dan menjalankan step.
extends Node

const TEST_CHAPTER_PATH: String = "res://tests/test_chapter.json"

func _ready() -> void:
	print("=== TEST: DialogueRunner ===")

	# Buat chapter test kecil
	_create_test_chapter()

	# Test load
	var err: Error = DialogueRunner.load_chapter(0)  # chapter_00.json tidak ada
	assert(err != OK, "load chapter tidak ada seharusnya error")

	# Muat file test langsung
	_load_test_chapter()

	# Hubungkan sinyal
	var runner_ctx: Dictionary = {"scenes_started": [], "steps_count": 0}
	DialogueRunner.scene_started.connect(func(sid: String) -> void:
		runner_ctx["scenes_started"].append(sid)
	)
	DialogueRunner.step_started.connect(func(_step: Dictionary) -> void:
		runner_ctx["steps_count"] += 1
	)

	# Jalankan scene test
	DialogueRunner.start_scene("TEST_01")

	# Tunggu beberapa frame agar step berjalan
	await get_tree().create_timer(1.0).timeout

	assert(runner_ctx["scenes_started"].size() >= 1, "scene_started tidak dipancarkan")
	assert(runner_ctx["steps_count"] >= 1, "step_started tidak dipancarkan")
	print("  - scenes started: %s" % str(runner_ctx["scenes_started"]))
	print("  - steps executed: %d" % runner_ctx["steps_count"])

	# Cek flag yang di-set dari step
	assert(FlagStore.get_flag("test_narration_done") == true, "flag dari set_flag step gagal")

	FlagStore.clear()
	print("=== SEMUA TEST DialogueRunner LULUS ===")


func _create_test_chapter() -> void:
	var data: Dictionary = {
		"chapter": 99,
		"loop": 1,
		"scenes": {
			"TEST_01": {
				"steps": [
					{"type": "narration", "text": "TEST_NARRATION", "pause_after": 0.0},
					{"type": "set_flag", "flag": "test_narration_done", "value": true},
					{"type": "pause", "duration": 0.1}
				]
			}
		}
	}
	var file := FileAccess.open(TEST_CHAPTER_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _load_test_chapter() -> void:
	var file := FileAccess.open(TEST_CHAPTER_PATH, FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_as_text())
	file.close()
	# Inject langsung ke DialogueRunner
	DialogueRunner._chapter_data = json.data
