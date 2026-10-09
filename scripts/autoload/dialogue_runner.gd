## DialogueRunner — Autoload
## Membaca chapter_XX.json dan menjalankan step secara berurutan.
## Tipe step: narration, line, pause, choice, set_flag, ui, sfx, bgm, vfx,
##            next_scene, chat_message, text_input
## Sinyal: step_started, step_finished, chapter_finished
extends Node

signal step_started(step: Dictionary)
signal step_finished(step: Dictionary)
signal scene_started(scene_id: String)
signal scene_finished(scene_id: String)
signal chapter_finished(chapter: int)
signal choice_requested(options: Array, mode: String)
signal text_input_requested(prompt_key: String)

var _chapter_data: Dictionary = {}
var _current_scene_id: String = ""
var _current_step_index: int = 0
var _steps: Array = []
var _running: bool = false
var _waiting_for_input: bool = false


# --- Memuat bab ---

func load_chapter(chapter_number: int) -> Error:
	var path: String = "res://data/chapters/chapter_%02d.json" % chapter_number
	if not FileAccess.file_exists(path):
		push_error("DialogueRunner: file tidak ditemukan — %s" % path)
		return ERR_FILE_NOT_FOUND
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var json := JSON.new()
	var err: Error = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("DialogueRunner: JSON error — %s" % json.get_error_message())
		return err
	_chapter_data = json.data
	print("DialogueRunner: chapter %d dimuat" % chapter_number)
	return OK


# --- Menjalankan scene ---

func start_scene(scene_id: String) -> void:
	if not _chapter_data.has("scenes"):
		push_error("DialogueRunner: chapter data belum dimuat")
		return
	var scenes: Dictionary = _chapter_data["scenes"]
	if not scenes.has(scene_id):
		push_error("DialogueRunner: scene '%s' tidak ditemukan" % scene_id)
		return

	_current_scene_id = scene_id
	_current_step_index = 0
	var scene_data: Dictionary = scenes[scene_id]
	_steps = scene_data.get("steps", [])

	GameState.change_scene(scene_id)
	scene_started.emit(scene_id)

	# Terapkan setting scene (bgm, ambience)
	_apply_scene_settings(scene_data)

	_running = true
	_advance()


func _apply_scene_settings(scene_data: Dictionary) -> void:
	# BGM
	if scene_data.has("bgm") and scene_data["bgm"] != null:
		var bgm_path: String = "res://assets/audio/bgm/%s" % scene_data["bgm"]
		if ResourceLoader.exists(bgm_path):
			AudioManager.play_bgm(load(bgm_path))
	elif scene_data.has("bgm") and scene_data["bgm"] == null:
		AudioManager.stop_bgm()

	# Ambience
	if scene_data.has("ambience") and scene_data["ambience"] != null:
		var amb_path: String = "res://assets/audio/ambience/%s" % scene_data["ambience"]
		if ResourceLoader.exists(amb_path):
			AudioManager.play_ambience(load(amb_path))


# --- Langkah demi langkah ---

func _advance() -> void:
	if not _running:
		return
	if _current_step_index >= _steps.size():
		_finish_scene()
		return

	var step: Dictionary = _steps[_current_step_index]
	step_started.emit(step)
	await _execute_step(step)

	if not _waiting_for_input:
		step_finished.emit(step)
		_current_step_index += 1
		_advance()


func _execute_step(step: Dictionary) -> void:
	var step_type: String = step.get("type", "")
	match step_type:
		"narration", "line", "chat_message":
			# UI mendengarkan step_started lalu menampilkan teks
			# Jeda otomatis berdasarkan panjang teks
			var text_key: String = step.get("text", "")
			var pause: float = step.get("pause_after", 0.0)
			var char_count: int = tr(text_key).length()
			var typing_delay: float = clampf(char_count * 0.04, 0.8, 3.0) / SettingsManager.text_speed
			await get_tree().create_timer(typing_delay + pause).timeout

		"pause":
			var duration: float = step.get("duration", 1.0)
			await get_tree().create_timer(duration).timeout

		"choice":
			_waiting_for_input = true
			var options: Array = step.get("options", [])
			var mode: String = step.get("mode", "normal")
			choice_requested.emit(options, mode)
			# UI memanggil submit_choice() saat pemain memilih

		"set_flag":
			var flag_name: String = step.get("flag", "")
			var flag_value: Variant = step.get("value", true)
			if flag_name != "":
				FlagStore.set_flag(flag_name, flag_value)

		"ui":
			# Aksi UI generik — ditangani oleh listener
			pass

		"sfx":
			var sfx_path: String = "res://assets/audio/sfx/%s" % step.get("file", "")
			if ResourceLoader.exists(sfx_path):
				AudioManager.play_sfx(load(sfx_path))

		"bgm":
			var action: String = step.get("action", "play")
			if action == "stop":
				AudioManager.stop_bgm()
			elif step.has("file"):
				var bgm_path: String = "res://assets/audio/bgm/%s" % step["file"]
				if ResourceLoader.exists(bgm_path):
					AudioManager.play_bgm(load(bgm_path))

		"vfx":
			# Visual effect — ditangani oleh scene yang mendengarkan step_started
			pass

		"next_scene":
			var target: String = step.get("target", "")
			if target != "":
				_finish_scene()
				start_scene(target)
				return

		"text_input":
			_waiting_for_input = true
			var prompt_key: String = step.get("prompt", "")
			text_input_requested.emit(prompt_key)

		_:
			push_warning("DialogueRunner: tipe step tidak dikenal '%s'" % step_type)


# --- Input dari UI ---

func submit_choice(option_index: int) -> void:
	if not _waiting_for_input:
		return
	_waiting_for_input = false
	var step: Dictionary = _steps[_current_step_index]
	var options: Array = step.get("options", [])
	if option_index >= 0 and option_index < options.size():
		var chosen: Dictionary = options[option_index]
		if chosen.has("set_flag") and chosen["set_flag"] != null:
			var flag_data: Variant = chosen["set_flag"]
			if flag_data is Dictionary:
				for key: String in flag_data.keys():
					FlagStore.set_flag(key, flag_data[key])
			elif flag_data is String:
				FlagStore.set_flag(flag_data, true)

	step_finished.emit(step)
	_current_step_index += 1

	# Cek next dari choice
	if step.has("next"):
		_finish_scene()
		start_scene(step["next"])
	else:
		_advance()


func submit_text_input(text: String) -> void:
	if not _waiting_for_input:
		return
	_waiting_for_input = false
	var step: Dictionary = _steps[_current_step_index]
	var flag_name: String = step.get("store_as", "player_input")
	FlagStore.set_flag(flag_name, text)

	step_finished.emit(step)
	_current_step_index += 1
	_advance()


# --- Selesai ---

func _finish_scene() -> void:
	_running = false
	scene_finished.emit(_current_scene_id)
	SaveSystem.save_game()  # autosave di tiap pergantian scene


func stop() -> void:
	_running = false
	_waiting_for_input = false
