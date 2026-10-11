## AUDIT xeon v5 — scene gameplay/HUD pada font 2.5x: 0-px, kontrol terpotong,
## dan teks kosong yang SEHARUSNYA terisi (label statis di .tscn).
extends Node

const GAMEPLAY: Array[String] = [
	"res://scenes/intro/intro_cutscene.tscn",
	"res://scenes/bedroom/bedroom.tscn",
	"res://scenes/corridor/corridor.tscn",
	"res://scenes/lift/lift.tscn",
	"res://scenes/balcony/balcony.tscn",
	"res://scenes/transitions/flashback.tscn",
	"res://scenes/ui/thought_box.tscn",
	"res://scenes/ui/chat_ui.tscn",
]

var _bugs: Array[String] = []


func _ready() -> void:
	TranslationServer.set_locale("id")
	for mult in [1.0, 2.0, 2.5]:
		SettingsManager.font_size_multiplier = mult
		SettingsManager.save_settings()
		for s in GAMEPLAY:
			await _probe(s, mult)
	SettingsManager.font_size_multiplier = 1.0
	SettingsManager.save_settings()
	print("\n=== RINGKASAN (%d) ===" % _bugs.size())
	for b in _bugs:
		print("  * ", b)
	get_tree().quit(0)


func _settle(f: int = 10) -> void:
	for i in f:
		await get_tree().process_frame


func _probe(path: String, mult: float) -> void:
	var ps: PackedScene = load(path)
	if ps == null:
		_bugs.append("LOAD GAGAL %s" % path)
		return
	var n: Node = ps.instantiate()
	for k in ["auto_start_intro", "auto_start", "auto_start_sequence", "navigate_scenes"]:
		if k in n:
			n.set(k, false)
	add_child(n)
	await _settle(14)
	var issues: Array[String] = []
	_walk(n, n, issues, mult)
	if issues.size() > 0:
		print("  [%s x%.1f] isu=%d" % [path.get_file(), mult, issues.size()])
		for i in issues:
			print("      ", i)
			_bugs.append("%s x%.1f :: %s" % [path.get_file(), mult, i])
	else:
		print("  [%s x%.1f] ok" % [path.get_file(), mult])
	n.queue_free()
	await get_tree().process_frame


func _walk(n: Node, root: Node, out: Array[String], mult: float) -> void:
	if n is Control:
		var c: Control = n
		if c.is_visible_in_tree():
			if c.size.x <= 0.5 or c.size.y <= 0.5:
				out.append("%s 0-px size=%s" % [c.get_path(), str(c.size)])
			# Kontrol di dalam container yang meng-clip, tanpa scroll ancestor -> cek viewport.
			if (c is Button or c is Label or c is CheckBox) and not _has_scroll_ancestor(c, root):
				var br: Rect2 = c.get_global_rect()
				var vr := Rect2(0, 0, 640, 360)
				if br.end.y > vr.end.y + 0.5 or br.position.y < -0.5 or br.end.x > vr.end.x + 0.5 or br.position.x < -0.5:
					out.append("%s KELUAR VIEWPORT rect=%s" % [c.get_path(), str(br)])
	for ch in n.get_children():
		_walk(ch, root, out, mult)


func _has_scroll_ancestor(node: Node, stop: Node) -> bool:
	var p: Node = node.get_parent()
	while p != null and p != stop:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false
