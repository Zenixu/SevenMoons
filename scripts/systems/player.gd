## Player — Karakter Arutala
## CharacterBody2D dengan gerakan 2D, animasi 4 arah (idle/walk), dan flag can_move.
## SpriteFrames dibangun saat runtime dari assets/characters/player_sheet.png
## (6 baris x 4 kolom, frame 32x48) agar tidak perlu file .tres terpisah.
class_name PlayerCharacter
extends CharacterBody2D

const SHEET_PATH := "res://assets/characters/player_sheet.png"
const FRAME_W := 32
const FRAME_H := 48
# (nama animasi, baris, jumlah frame)
const ANIM_ROWS := [
	["idle_down", 0, 2], ["walk_down", 1, 4],
	["idle_up", 2, 2], ["walk_up", 3, 4],
	["idle_side", 4, 2], ["walk_side", 5, 4],
]

@export var move_speed: float = 85.0
@export var can_move: bool = true

@onready var sprite: AnimatedSprite2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _facing: String = "down"
var _auto_walking: bool = false


func _ready() -> void:
	add_to_group("player")
	_build_sprite_frames()
	sprite.play("idle_down")


func _build_sprite_frames() -> void:
	var sheet: Texture2D = load(SHEET_PATH)
	if sheet == null:
		push_error("Player: gagal memuat %s" % SHEET_PATH)
		return

	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for row in ANIM_ROWS:
		var anim_name: String = row[0]
		var row_index: int = row[1]
		var count: int = row[2]
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, true)
		frames.set_animation_speed(anim_name, 8.0 if anim_name.begins_with("walk") else 3.0)
		for i in range(count):
			var at := AtlasTexture.new()
			at.atlas = sheet
			at.region = Rect2(i * FRAME_W, row_index * FRAME_H, FRAME_W, FRAME_H)
			frames.add_frame(anim_name, at)
	sprite.sprite_frames = frames
	sprite.centered = true


func _physics_process(_delta: float) -> void:
	if _auto_walking:
		move_and_slide()
		return
	if not can_move:
		velocity = Vector2.ZERO
		_play_idle()
		move_and_slide()
		return

	var direction := Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y -= 1.0

	velocity = direction.normalized() * move_speed
	if direction != Vector2.ZERO:
		_update_facing(direction)
		sprite.play("walk_" + _facing)
	else:
		_play_idle()
	move_and_slide()


func _update_facing(direction: Vector2) -> void:
	# Utamakan sumbu dengan dorongan terbesar; horizontal pakai tampak samping.
	if absf(direction.x) > absf(direction.y):
		_facing = "side"
		sprite.flip_h = direction.x < 0.0
	elif direction.y < 0.0:
		_facing = "up"
		sprite.flip_h = false
	else:
		_facing = "down"
		sprite.flip_h = false


func _play_idle() -> void:
	if sprite.animation != "idle_" + _facing:
		sprite.play("idle_" + _facing)


func set_movement_enabled(enable: bool) -> void:
	can_move = enable
	if not enable:
		velocity = Vector2.ZERO


## Berjalan otomatis menuju titik target (untuk adegan terarah/cutscene).
## Memainkan animasi jalan lalu berhenti tepat di tujuan.
func auto_walk_to(target: Vector2, speed: float = 68.0) -> void:
	_auto_walking = true
	can_move = false
	velocity = Vector2.ZERO
	var max_iter: int = 1200
	while position.distance_to(target) > 3.0 and max_iter > 0:
		max_iter -= 1
		var dir := target - position
		if dir.length() < 0.001:
			break
		dir = dir.normalized()
		_update_facing(dir)
		sprite.play("walk_" + _facing)
		velocity = dir * speed
		move_and_slide()
		await get_tree().physics_frame
	_play_idle()
	_auto_walking = false
