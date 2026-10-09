## Test reachability: pastikan setiap interactable bisa dijangkau pemain.
## BFS pada grid titik jalan (cek tabrakan player shape vs Walls+Furniture),
## lalu uji apakah ada titik terjangkau yang overlap dengan area interactable.
extends Node

const BEDROOM_SCENE = preload("res://scenes/bedroom/bedroom.tscn")
const CORRIDOR_SCENE = preload("res://scenes/corridor/corridor.tscn")
const STEP := 6


func _ready() -> void:
	print("=== TEST: REACHABILITY INTERACTABLES ===")
	await _check(BEDROOM_SCENE, "Bedroom", Vector2(320, 280), 960.0)
	await get_tree().process_frame
	await get_tree().process_frame
	await _check(CORRIDOR_SCENE, "Corridor", Vector2(200, 265), 1120.0)
	print("=== SELESAI ===")
	get_tree().quit(0)


func _check(scene: PackedScene, name: String, start: Vector2, world_w: float) -> void:
	var inst: Node2D = scene.instantiate()
	if "auto_start_intro" in inst:
		inst.auto_start_intro = false
	if "auto_start" in inst:
		inst.auto_start = false
	if "navigate_scenes" in inst:
		inst.navigate_scenes = false
	add_child(inst)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var space: PhysicsDirectSpaceState2D = inst.get_world_2d().direct_space_state
	var player_shape := RectangleShape2D.new()
	player_shape.size = Vector2(16, 26)
	var player_node: Node = inst.get_node_or_null("Player")
	var exclude: Array = [player_node.get_rid()] if player_node else []

	var blocked: Dictionary = {}
	var x := 0.0
	while x <= world_w:
		var y := 0.0
		while y <= 360.0:
			var p := Vector2(x, y)
			var q := PhysicsShapeQueryParameters2D.new()
			q.shape = player_shape
			q.transform = Transform2D(0.0, p)
			q.collide_with_areas = false
			q.collide_with_bodies = true
			q.exclude = exclude
			var hits: Array = space.intersect_shape(q, 1)
			blocked[p] = hits.size() > 0
			y += STEP
		x += STEP

	# BFS dari start
	var visited: Dictionary = {}
	var startp := Vector2(round(start.x / STEP) * STEP, round(start.y / STEP) * STEP)
	var queue: Array = [startp]
	visited[startp] = true
	while queue.size() > 0:
		var cur: Vector2 = queue.pop_front()
		for d in [Vector2(STEP, 0), Vector2(-STEP, 0), Vector2(0, STEP), Vector2(0, -STEP)]:
			var np: Vector2 = cur + d
			if np.x < 0.0 or np.x > world_w or np.y < 0.0 or np.y > 360.0:
				continue
			if visited.has(np):
				continue
			if blocked.get(np, true):
				continue
			visited[np] = true
			queue.append(np)

	print("  [%s] titik terjangkau: %d" % [name, visited.size()])

	var inter_parent: Node = inst.get_node_or_null("Interactables")
	var all_ok := true
	for child in inter_parent.get_children():
		if not (child is Interactable):
			continue
		var rect: Rect2 = _area_rect(child)
		var ok := false
		for cell in visited.keys():
			var pr := Rect2(cell - Vector2(8, 13), Vector2(16, 26))
			if pr.intersects(rect):
				ok = true
				break
		print("    %-14s %s  rect=%s" % [child.object_id, "OK" if ok else "TIDAK TERJANGKAU", rect])
		if not ok:
			all_ok = false

	assert(all_ok, "[%s] ada interactable yang tidak terjangkau!" % name)
	inst.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _area_rect(area: Area2D) -> Rect2:
	var cs: CollisionShape2D = area.get_node_or_null("CollisionShape2D")
	if cs and cs.shape is RectangleShape2D:
		var pos: Vector2 = cs.global_position
		var half: Vector2 = (cs.shape as RectangleShape2D).size * 0.5
		return Rect2(pos - half, (cs.shape as RectangleShape2D).size)
	return Rect2(area.global_position - Vector2(16, 16), Vector2(32, 32))
