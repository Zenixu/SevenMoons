## GameState — Autoload
## Status global: bab/loop aktif, scene aktif.
extends Node

signal scene_changed(scene_id: String)

var current_loop: int = 1
var current_chapter: int = 1
var current_scene_id: String = ""
var play_time_seconds: float = 0.0


func _process(delta: float) -> void:
	play_time_seconds += delta


func change_scene(scene_id: String) -> void:
	current_scene_id = scene_id
	scene_changed.emit(scene_id)


func reset_for_new_loop() -> void:
	current_scene_id = ""
	# Flag tidak di-clear — FlagStore menyimpan memori lintas loop
