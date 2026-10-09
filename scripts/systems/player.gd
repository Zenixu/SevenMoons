## Player — Karakter Arutala
## CharacterBody2D dengan pergerakan 2D responsif dan flag can_move.
class_name PlayerCharacter
extends CharacterBody2D

@export var move_speed: float = 85.0
@export var can_move: bool = true

@onready var visual: ColorRect = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
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
	move_and_slide()


func set_movement_enabled(enable: bool) -> void:
	can_move = enable
	if not enable:
		velocity = Vector2.ZERO
