class_name PlayerCharacter
extends CustomCharacter

## Lateral movement speed when walking
const _WALK_SPEED = 300.0

## Lateral movement speed when running
const _RUN_SPEED = 400.0

@onready var _sprite: PlayerSprite = $%AnimatedSprite2D

func _ready() -> void:
	super._ready()
	_sprite.set_player(self)
	World.register_player(self)

func _process_input() -> void:
	_process_jump_input()
	_process_move_input()

func _process_jump_input() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		_jump()

func _process_move_input() -> void:
	var direction := Input.get_axis("left", "right")
	var speed = _RUN_SPEED if is_running() else _WALK_SPEED
	_apply_move_input(direction, speed)

func _apply_move_input(direction, speed) -> void:
	super._apply_move_input(direction, speed)
	_sprite.flip_h = _facing_left

func is_running() -> bool:
	return Input.is_action_pressed("run")
