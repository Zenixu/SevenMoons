## Test scene untuk LoopManager
extends Node

func _ready() -> void:
	print("=== TEST: LoopManager ===")

	# Test initial state
	assert(GameState.current_loop == 1, "default loop salah")

	# Test sinyal
	var loop_ctx: Dictionary = {"started": -1, "ended": -1}
	LoopManager.loop_started.connect(func(n: int) -> void:
		loop_ctx["started"] = n
	)
	LoopManager.loop_ended.connect(func(n: int) -> void:
		loop_ctx["ended"] = n
	)

	# Start loop 1
	LoopManager.start_loop(1)
	assert(loop_ctx["started"] == 1, "signal loop_started gagal")
	assert(GameState.current_loop == 1, "current_loop gagal")

	# Cek loop_changes diterapkan sebagai flag
	# (asumsi loop_changes.json sudah ada dengan key "1")
	var light: Variant = FlagStore.get_flag("light_level")
	print("  - light_level loop 1: %s" % str(light))

	# End loop → otomatis start loop 2
	LoopManager.end_current_loop()
	assert(loop_ctx["ended"] == 1, "signal loop_ended gagal")
	assert(GameState.current_loop == 2, "auto-advance ke loop 2 gagal")
	assert(loop_ctx["started"] == 2, "signal loop_started loop 2 gagal")

	# Cek is_final_loop
	assert(LoopManager.is_final_loop() == false, "is_final_loop salah di loop 2")

	# Test get_loop_data
	var data_7: Dictionary = LoopManager.get_loop_data(7)
	print("  - loop 7 data: %s" % str(data_7))

	# Reset ke loop 1 untuk state bersih
	GameState.current_loop = 1
	FlagStore.clear()

	print("=== SEMUA TEST LoopManager LULUS ===")
