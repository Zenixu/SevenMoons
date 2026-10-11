## _gate_skip_probe — verifies the "lewati adegan sensitif" option really
## reroutes S06 to the ALT path (SAFETY §3.3). Read-only; restores settings.
## Quits directly from the completion callback so the ALT path's own
## change_scene_to_file() can't outlive the probe.
extends Node

const BALCONY := "res://scenes/balcony/balcony.tscn"

var _scene: Node = null


func _ready() -> void:
	TranslationServer.set_locale("id")
	print("=== GATE SKIP PROBE ===")
	Engine.time_scale = 6.0

	var prev: bool = SettingsManager.skip_sensitive_scenes
	SettingsManager.skip_sensitive_scenes = true

	_scene = (load(BALCONY) as PackedScene).instantiate()
	_scene.auto_start_sequence = true
	add_child(_scene)
	_scene.balcony_scene_completed.connect(_on_done)

	await get_tree().create_timer(45.0).timeout
	print("SKIP path completed = false (timeout)")
	SettingsManager.skip_sensitive_scenes = prev
	Engine.time_scale = 1.0
	get_tree().quit(1)


func _on_done() -> void:
	var cm: Node = _scene.get("choice_menu")
	var cm_visible: bool = (cm != null and cm.visible)
	print("SKIP path completed = true")
	print("SKIP choice_menu.visible = ", cm_visible, " (expected false)")
	SettingsManager.skip_sensitive_scenes = false
	Engine.time_scale = 1.0
	print("=== GATE SKIP PROBE DONE ===")
	get_tree().quit(0)
