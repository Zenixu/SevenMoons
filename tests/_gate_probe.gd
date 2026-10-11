## _gate_probe — GATE runtime probe (read-only). Verifies the actual boot chain:
##   1. run/main_scene == content_warning.tscn and it instantiates as ContentWarning.
##   2. ContentWarning "Aku mengerti" routes to main_menu.
##   3. Every gameplay scene carries a PauseMenu with HelpMenu + Quit.
## Prints a compact report; never modifies game data.
extends Node

const CW := "res://scenes/ui/content_warning.tscn"
const MM := "res://scenes/main_menu/main_menu.tscn"
const GAMEPLAY := [
	"res://scenes/bedroom/bedroom.tscn",
	"res://scenes/corridor/corridor.tscn",
	"res://scenes/lift/lift.tscn",
	"res://scenes/balcony/balcony.tscn",
	"res://scenes/intro/intro_cutscene.tscn",
	"res://scenes/transitions/flashback.tscn",
]


func _ready() -> void:
	TranslationServer.set_locale("id")
	print("=== GATE PROBE ===")

	# 1. Boot scene
	var f := FileAccess.open("res://project.godot", FileAccess.READ)
	var main_scene := ""
	while f and not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.begins_with("run/main_scene="):
			main_scene = line.split("=", true, 1)[1].strip_edges().trim_prefix("\"").trim_suffix("\"")
	if f:
		f.close()
	print("BOOT main_scene = ", main_scene)
	var cw = load(CW).instantiate()
	print("BOOT instantiates as ContentWarning = ", cw is ContentWarning)
	print("BOOT CW.MAIN_MENU_SCENE = ", ContentWarning.MAIN_MENU_SCENE)
	cw.free()

	# 2. pause action
	print("PAUSE action registered = ", InputMap.has_action("pause"))
	var esc := false
	if InputMap.has_action("pause"):
		for ev in InputMap.action_get_events("pause"):
			if ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_ESCAPE:
				esc = true
	print("PAUSE mapped to Esc = ", esc)

	# 3. gameplay scenes have PauseMenu + HelpMenu + Quit
	for p in GAMEPLAY:
		var n: Node = (load(p) as PackedScene).instantiate()
		if "auto_start_intro" in n:
			n.set("auto_start_intro", false)
		if "auto_start" in n:
			n.set("auto_start", false)
		if "auto_start_sequence" in n:
			n.set("auto_start_sequence", false)
		if "navigate_scenes" in n:
			n.set("navigate_scenes", false)
		add_child(n)
		await get_tree().process_frame
		var pm = _find_pause(n)
		var has_help := false
		var has_quit := false
		if pm != null:
			has_help = pm.get("help_menu") != null
			has_quit = pm.get("quit_button") != null
		print("SCENE ", p.get_file(), " PauseMenu=", pm != null, " HelpMenu=", has_help, " Quit=", has_quit)
		n.queue_free()
		await get_tree().process_frame

	print("=== GATE PROBE DONE ===")
	get_tree().quit(0)


func _find_pause(root: Node):
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is PauseMenu:
			return n
		for ch in n.get_children():
			stack.append(ch)
	return null
