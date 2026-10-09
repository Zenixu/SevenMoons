## IntroCutscene — Pembuka "Bangun" (gaya cutscene komik)
## Mulai dari layar hitam, lalu panel-panel komik muncul satu per satu:
## mata terpejam -> cahaya menembus (kabur) -> dunia masih blur -> jelas.
## Setelah selesai, lanjut ke kamar (bedroom.tscn).
class_name IntroCutscene
extends Control

signal intro_finished()

const BEDROOM_SCENE := "res://scenes/bedroom/bedroom.tscn"

# (tekstur, durasi tampil, blur awal, blur akhir, alpha vignette)
const PANELS: Array[Dictionary] = [
	{"tex": "res://assets/art/intro_panel_1.png", "cap": "INTRO_CAP_1",
	 "dur": 2.6, "blur0": 8.0, "blur1": 5.0, "vig": 0.85},
	{"tex": "res://assets/art/intro_panel_2.png", "cap": "INTRO_CAP_2",
	 "dur": 2.8, "blur0": 6.0, "blur1": 3.0, "vig": 0.6},
	{"tex": "res://assets/art/intro_panel_3.png", "cap": "INTRO_CAP_3",
	 "dur": 2.8, "blur0": 4.5, "blur1": 1.2, "vig": 0.35},
	{"tex": "res://assets/art/intro_panel_4.png", "cap": "INTRO_CAP_4",
	 "dur": 3.2, "blur0": 1.0, "blur1": 0.0, "vig": 0.15},
]

@export var auto_start: bool = true

@onready var panel: TextureRect = $Panel
@onready var caption: Label = $Caption
@onready var skip_label: Label = $SkipLabel
@onready var fade_rect: ColorRect = $FadeRect

var _skipped: bool = false


func _ready() -> void:
	caption.text = ""
	skip_label.text = tr("INTRO_SKIP")
	skip_label.modulate.a = 0.0
	fade_rect.color = Color(0, 0, 0, 1)
	if auto_start:
		await play_intro()
		_go_to_bedroom()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		_skipped = true
		get_viewport().set_input_as_handled()


func _make_blur_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/wake_blur.gdshader")
	return mat


func play_intro() -> void:
	AudioManager.play_rain(3.0)

	for i in PANELS.size():
		if _skipped:
			break
		var p: Dictionary = PANELS[i]
		await _show_panel(p)

	# Pastikan panel terakhir sempat terbaca sebelum ke kamar
	if not _skipped:
		await get_tree().create_timer(1.4).timeout

	# Fade ke hitam singkat, lalu scene kamar mengambil alih
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, 1.0)
	await tw.finished
	intro_finished.emit()


func _show_panel(p: Dictionary) -> void:
	panel.texture = load(p["tex"])
	var mat := _make_blur_material()
	panel.material = mat
	mat.set_shader_parameter("blur_amount", p["blur0"])
	mat.set_shader_parameter("vignette_strength", p["vig"])

	# Panel muncul dari hitam
	panel.modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(panel, "modulate:a", 1.0, 0.7)

	# Caption komik: ketik perlahan
	caption.text = tr(p["cap"])
	caption.modulate.a = 0.0
	var cap_tw := create_tween()
	cap_tw.tween_property(caption, "modulate:a", 1.0, 0.6)

	# "Membuka mata": blur berkurang selama panel tampil
	var blur_tw := create_tween()
	blur_tw.tween_method(func(v: float) -> void:
		if is_instance_valid(mat):
			mat.set_shader_parameter("blur_amount", v),
		p["blur0"], p["blur1"], p["dur"] * 0.9)

	# Petunjuk lewati muncul setelah sebentar
	var skip_tw := create_tween()
	skip_tw.tween_property(skip_label, "modulate:a", 0.55, 0.8)

	await get_tree().create_timer(p["dur"]).timeout

	# Caption keluar
	var cap_out := create_tween()
	cap_out.tween_property(caption, "modulate:a", 0.0, 0.5)
	await cap_out.finished


func _go_to_bedroom() -> void:
	get_tree().change_scene_to_file(BEDROOM_SCENE)
