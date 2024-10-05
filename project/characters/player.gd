class_name PlayerCharacter
extends CustomCharacter

## Lateral movement speed when walking
const _WALK_SPEED := 300.0

## Lateral movement speed when running
const _RUN_SPEED := 400.0

## Time window after leaving the ground during which the player can still jump
var _COYOTE_TIME_MS := 35

@onready var _sprite: PlayerSprite = $%AnimatedSprite2D
@onready var _jump_audio: AudioStreamPlayer2D = $%JumpAudio
@onready var _land_audio: AudioStreamPlayer2D = $%LandAudio

var _interactable: Interactable
var _last_grounded_timestamp := 0.0

func _ready() -> void:
	super._ready()
	_sprite.set_player(self)
	World.register_player(self)

func _process_input() -> void:
	_process_jump_input()
	_process_move_input()
	_process_interact_input()

func _process_jump_input() -> void:
	if Input.is_action_just_pressed("jump") and _can_jump():
		_jump()

func _can_jump() -> bool:
	return _was_recently_grounded(_COYOTE_TIME_MS)

func _was_recently_grounded(time_window: float) -> bool:
	if _last_grounded_timestamp == 0:
		# Player has never been grounded
		return false
	var time_since_grounded := Time.get_ticks_msec() - _last_grounded_timestamp
	return time_since_grounded < time_window

func _move() -> void:
	if is_on_floor():
		_last_grounded_timestamp = Time.get_ticks_msec()
	super._move()

func _jump() -> void:
	super._jump()
	_jump_audio.play()

func _landed() -> void:
	super._landed()
	_land_audio.play()

func _process_move_input() -> void:
	var direction := Input.get_axis("left", "right")
	var speed = _RUN_SPEED if is_running() else _WALK_SPEED
	_apply_move_input(direction, speed)

func _process_interact_input() -> void:
	var direction := Input.get_axis("up", "down")
	if direction < 0.0:
		_attempt_interact()

func _apply_move_input(direction, speed) -> void:
	super._apply_move_input(direction, speed)
	_sprite.flip_h = _facing_left

func is_running() -> bool:
	return Input.is_action_pressed("run")

func set_interactable(interactable: Interactable) -> void:
	_interactable = interactable

func _attempt_interact() -> void:
	if not _interactable:
		return
	_interactable.interact()
