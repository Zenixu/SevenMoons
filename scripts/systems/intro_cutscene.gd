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
	{"tex": "res://assets/ui/intro_panel_1.png", "cap": "INTRO_CAP_1",
	 "dur": 2.6, "blur0": 8.0, "blur1": 5.0, "vig": 0.85},
	{"tex": "res://assets/ui/intro_panel_2.png", "cap": "INTRO_CAP_2",
	 "dur": 2.8, "blur0": 6.0, "blur1": 3.0, "vig": 0.6},
	{"tex": "res://assets/ui/intro_panel_3.png", "cap": "INTRO_CAP_3",
	 "dur": 2.8, "blur0": 4.5, "blur1": 1.2, "vig": 0.35},
	{"tex": "res://assets/ui/intro_panel_4.png", "cap": "INTRO_CAP_4",
	 "dur": 3.2, "blur0": 1.0, "blur1": 0.0, "vig": 0.15},
]

@export var auto_start: bool = true

@onready var monologue_label: Label = $MonologueLabel
@onready var panel: TextureRect = $Panel
@onready var caption: Label = $Caption
@onready var skip_label: Label = $SkipLabel
@onready var fade_rect: ColorRect = $FadeRect

var _skipped: bool = false
var _tick_accum: float = 0.0
var _last_tick_char: int = -1
var _cap_typing: bool = false

# Monolog pembuka (mata masih tertutup) — dipecah per bagian, diketik perlahan.
const MONOLOGUE_CHUNKS: Array[String] = [
	"S01_INTRO_1", "S01_INTRO_2", "S01_INTRO_3",
	"S01_INTRO_4", "S01_INTRO_5", "S01_INTRO_6",
]


func _ready() -> void:
	caption.text = ""
	skip_label.text = tr("INTRO_SKIP")
	skip_label.modulate.a = 0.0
	fade_rect.color = Color(0, 0, 0, 1)
	if monologue_label:
		monologue_label.text = ""
		monologue_label.visible = false
	if auto_start:
		await play_intro()
		_go_to_bedroom()


## Bunyi ketikan caption (huruf demi huruf) selama caption sedang diketik.
func _process(delta: float) -> void:
	if not _cap_typing or caption == null:
		return
	_tick_accum += delta
	if _tick_accum < 0.05:
		return
	_tick_accum = 0.0
	var shown: int = caption.visible_characters
	if shown != _last_tick_char:
		_last_tick_char = shown
		if shown % 2 == 0:
			AudioManager.play_type_tick()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		_skipped = true
		get_viewport().set_input_as_handled()


func _make_blur_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/wake_blur.gdshader")
	return mat


func play_intro() -> void:
	# Mata masih tertutup: hujan pelan saja, tanpa dengung kulkas/jam.
	AudioManager.play_rain_quiet(AudioManager.AMB_RAIN_QUIET_DB, 3.0)

	# Layar mulai HITAM TOTAL, lalu perlahan "membuka mata":
	# tirai hitam memudar sehingga panel pertama (mata terpejam, blur tinggi)
	# muncul perlahan. Ini inti efek "bangun dari gelap".
	# Fase 1: MATA MASIH TERTUTUP — monolog Arutala diketik perlahan,
	# bagian demi bagian, di atas layar yang masih gelap.
	await _play_opening_monologue()

	# Fase 2: perlahan "membuka mata" (tirai hitam memudar) lalu panel komik.
	var open_eyes := create_tween()
	open_eyes.tween_property(fade_rect, "color:a", 0.0, 2.4)

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


## Fase pembuka: monolog panjang, dipotong per bagian, diketik perlahan
## (dengan bunyi ketikan). Layar tetap hitam — mata belum terbuka.
func _play_opening_monologue() -> void:
	if monologue_label == null:
		return
	monologue_label.visible = true
	monologue_label.modulate.a = 1.0
	await get_tree().create_timer(0.6).timeout

	for key in MONOLOGUE_CHUNKS:
		if _skipped:
			break
		monologue_label.text = tr(key)
		monologue_label.visible_characters = 0
		await _type_monologue()
		await get_tree().create_timer(1.5).timeout

	# Monolog selesai — memudar sebelum membuka mata
	var tw := create_tween()
	tw.tween_property(monologue_label, "modulate:a", 0.0, 1.2)
	await tw.finished
	monologue_label.visible = false


## Ketik satu bagian monolog huruf demi huruf sambil memainkan bunyi ketikan.
func _type_monologue() -> void:
	var chars: int = monologue_label.text.length()
	var cps: float = 20.0 * maxf(0.2, SettingsManager.text_speed)
	var step: float = 1.0 / cps
	var accum: float = 0.0
	var shown: int = 0
	monologue_label.visible_characters = 0
	while shown < chars:
		if _skipped:
			break
		accum += get_process_delta_time()
		while accum >= step and shown < chars:
			accum -= step
			shown += 1
			monologue_label.visible_characters = shown
			if shown % 2 == 0:
				AudioManager.play_type_tick()
		await get_tree().process_frame
	monologue_label.visible_characters = chars


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

	# Caption komik: ketik perlahan huruf demi huruf (dengan bunyi ketikan)
	caption.text = tr(p["cap"])
	caption.modulate.a = 1.0
	caption.visible_characters = 0
	_cap_typing = true
	_tick_accum = 0.0
	_last_tick_char = -1
	var chars: int = caption.text.length()
	var cap_speed: float = 22.0 * maxf(0.2, SettingsManager.text_speed)
	var cap_dur: float = clampf(float(chars) / cap_speed, 0.3, 4.5)
	var cap_tw := create_tween()
	cap_tw.tween_property(caption, "visible_characters", chars, cap_dur)
	cap_tw.finished.connect(func() -> void: _cap_typing = false)

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
