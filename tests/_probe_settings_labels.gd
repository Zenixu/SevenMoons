## Probe BUG-5: SettingsMenu — 5 label slider harus terisi via lokalisasi.
## Instansiasi settings_menu.tscn, cek kelima label pada font 1x DAN 2x.
extends Node

const SCENE := "res://scenes/ui/settings_menu.tscn"
const _ROOT := "MarginContainer/ScrollContainer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer"

const EXPECTED := [
	{"path": _ROOT + "/TabContainer/Audio/BgmRow/Label", "key": "SETTINGS_BGM_VOL"},
	{"path": _ROOT + "/TabContainer/Audio/SfxRow/Label", "key": "SETTINGS_SFX_VOL"},
	{"path": _ROOT + "/TabContainer/Audio/AmbRow/Label", "key": "SETTINGS_AMBIENCE_VOL"},
	{"path": _ROOT + "/TabContainer/Gameplay/TextSpeedRow/Label", "key": "SETTINGS_TEXT_SPEED"},
	{"path": _ROOT + "/TabContainer/A11y/FontSizeRow/Label", "key": "SETTINGS_FONT_SIZE"},
]

var _fail: int = 0


func _ready() -> void:
	print("=== PROBE BUG-5: SettingsMenu label slider ===")
	TranslationServer.set_locale("id")
	for mult in [1.0, 2.0]:
		SettingsManager.font_size_multiplier = mult
		SettingsManager.save_settings()
		var ps: PackedScene = load(SCENE)
		var node: Node = ps.instantiate()
		add_child(node)
		await get_tree().process_frame
		await get_tree().process_frame
		print("-- font x%.1f --" % mult)
		for e in EXPECTED:
			var lbl: Label = node.get_node_or_null(e["path"]) as Label
			var want: String = tr(e["key"])
			if lbl == null:
				print("  MISSING %s" % e["path"])
				_fail += 1
				continue
			var got: String = lbl.text
			var ok: bool = got != "" and got == want
			print("  %-70s text=\"%s\" (harusnya \"%s\") %s" % [e["path"], got, want, "OK" if ok else "FAIL"])
			if not ok:
				_fail += 1
		node.queue_free()
		await get_tree().process_frame
	SettingsManager.font_size_multiplier = 1.0
	SettingsManager.save_settings()
	if _fail == 0:
		print("=== PROBE BUG-5 LULUS ===")
		get_tree().quit(0)
	else:
		print("=== PROBE BUG-5 GAGAL: %d ===" % _fail)
		get_tree().quit(1)
