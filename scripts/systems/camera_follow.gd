## CameraFollow — Kamera mengikuti pemain secara horizontal.
## Layar masih bergerak ke kiri/kanan mengikuti arah karakter, tetapi berhenti
## di tepi ruangan (limit) agar tidak ada area kosong di luar latar.
class_name CameraFollow
extends Camera2D

@export var target_path: NodePath
@export var follow_horizontal: bool = true
@export var follow_vertical: bool = false
@export var smooth: float = 6.0
@export var fixed_y: float = 180.0

var _target: Node2D


func _ready() -> void:
	_target = get_node_or_null(target_path)
	if _target == null:
		# Fallback: cari node di grup "player"
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_target = players[0]
	# Posisikan langsung agar tidak ada "loncat" di awal
	if _target:
		var p := _target.global_position
		global_position = Vector2(p.x if follow_horizontal else global_position.x,
			p.y if follow_vertical else fixed_y)
	else:
		global_position.y = fixed_y


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var desired := global_position
	if follow_horizontal:
		desired.x = _target.global_position.x
	if follow_vertical:
		desired.y = _target.global_position.y
	else:
		desired.y = fixed_y
	global_position = global_position.lerp(desired, clampf(smooth * delta, 0.0, 1.0))
