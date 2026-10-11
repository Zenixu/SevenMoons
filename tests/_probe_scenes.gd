## Probe runtime seluruh scene — cari error SCRIPT/UI & node 0-px.
## Fokus: (a) scene boot tanpa SCRIPT ERROR, (b) UI penting tampil & berukuran.
extends Node

const SCENES: Array[String] = [
	"res://scenes/ui/content_warning.tscn",
	"res://scenes/main_menu/main_menu.tscn",
	"res://scenes/intro/intro_cutscene.tscn",
	"res://scenes/bedroom/bedroom.tscn",
	"res://scenes/corridor/corridor.tscn",
	"res://scenes/lift/lift.tscn",
	"res://scenes/balcony/balcony.tscn",
	"res://scenes/transitions/flashback.tscn",
	"res://scenes/ui/pause_menu.tscn",
	"res://scenes/ui/help_menu.tscn",
	"res://scenes/ui/settings_menu.tscn",
	"res://scenes/ui/choice_menu.tscn",
]

var _fail: int = 0


func _ready() -> void:
	TranslationServer.set_locale("id")
	print("=== PROBE SCENE SMOKE ===")
	for path in SCENES:
		await _probe(path)
	print("=== PROBE SELESAI (fail=%d) ===" % _fail)
	get_tree().quit(0)


func _probe(path: String) -> void:
	print("\n--- ", path)
	if not ResourceLoader.exists(path):
		print("   !! TIDAK ADA")
		_fail += 1
		return
	var ps: PackedScene = load(path)
	if ps == null:
		print("   !! GAGAL LOAD")
		_fail += 1
		return
	var inst: Node = ps.instantiate()
	if inst == null:
		print("   !! GAGAL INSTANTIATE")
		_fail += 1
		return
	add_child(inst)
	# beberapa frame agar _ready + layout selesai
	for i in 4:
		await get_tree().process_frame

	# Audit node Control berukuran 0 yang seharusnya terlihat
	var zero: Array[String] = []
	_walk(inst, zero)
	for z in zero:
		print("   !! NODE 0-PX terlihat: ", z)
		_fail += 1

	print("   ok (children=%d)" % inst.get_child_count())
	inst.queue_free()
	await get_tree().process_frame


func _walk(n: Node, out: Array[String]) -> void:
	if n is Control:
		var c: Control = n
		if c.is_visible_in_tree() and c.size.x <= 0.5 and c.size.y <= 0.5:
			out.append(n.get_path())
	for ch in n.get_children():
		_walk(ch, out)
