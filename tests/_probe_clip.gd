## Probe umum: apakah tombol/label utama terpotong oleh panel induknya?
## Mengukur tiap Control terhadap batas leluhur yang meng-clip (PanelContainer).
extends Node

const SCENES: Array[String] = [
	"res://scenes/ui/content_warning.tscn",
	"res://scenes/main_menu/main_menu.tscn",
	"res://scenes/ui/pause_menu.tscn",
	"res://scenes/ui/help_menu.tscn",
	"res://scenes/ui/settings_menu.tscn",
	"res://scenes/ui/choice_menu.tscn",
]

var _issues: int = 0


func _ready() -> void:
	TranslationServer.set_locale("id")
	print("=== PROBE CLIP UI ===")
	for s in SCENES:
		await _probe(s, 1.0)
	# uji juga pada font 2x (aksesibilitas)
	print("\n=== ULANGI PADA FONT 2x ===")
	for s in SCENES:
		await _probe(s, 2.0)
	print("\n=== PROBE SELESAI (issues=%d) ===" % _issues)
	get_tree().quit(0)


func _probe(path: String, mult: float) -> void:
	var ps: PackedScene = load(path)
	var inst: Control = ps.instantiate()
	SettingsManager.font_size_multiplier = mult
	add_child(inst)
	# paksa multiplier font
	UITheme.apply(inst)
	# choice_menu perlu opsi dipresentasikan agar tombolnya ada
	if inst.has_method("present_choices"):
		inst.present_choices([
			{"text": "S03_R1_OPT_A"}, {"text": "S03_R1_OPT_B"}, {"text": "S03_R1_OPT_C"},
		], "normal", "")
	for i in 5:
		await get_tree().process_frame

	var clipped: Array[String] = []
	_check_buttons(inst, clipped)
	print("[%s x%.0f] tombol terpotong=%d" % [path.get_file(), mult, clipped.size()])
	for c in clipped:
		print("    CLIP: ", c)
		_issues += 1
	inst.queue_free()
	await get_tree().process_frame


func _check_buttons(n: Node, out: Array[String]) -> void:
	if n is Button and n.is_visible_in_tree():
		var b: Button = n
		if b.size.y <= 0.5 or b.size.x <= 0.5:
			out.append("%s size=%s (0-px)" % [b.get_path(), str(b.size)])
		else:
			# cari leluhur pertama yang meng-clip
			var anc := b.get_parent()
			while anc != null:
				if anc is PanelContainer or anc is ScrollContainer:
					var ar: Rect2 = (anc as Control).get_global_rect()
					var br: Rect2 = b.get_global_rect()
					if br.end.y > ar.end.y + 1.0 or br.end.x > ar.end.x + 1.0:
						out.append("%s di luar %s (btn_y=%.0f..%.0f panel_y=%.0f..%.0f)" % [
							b.get_path(), anc.get_path(), br.position.y, br.end.y, ar.position.y, ar.end.y])
					break
				anc = anc.get_parent()
	for ch in n.get_children():
		_check_buttons(ch, out)
