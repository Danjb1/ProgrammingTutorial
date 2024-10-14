class_name PlayerCharacter
extends CustomCharacter

signal spell_cast(spell: SpellProjectile)

const SpellProjectileScene := preload("res://projectiles/spell_projectile.tscn")

## Lateral movement speed when walking
const _WALK_SPEED := 300.0

## Lateral movement speed when running
const _RUN_SPEED := 400.0

## Speed of a spell projectile
const _SPELL_SPEED := 800.0

## Time window after leaving the ground during which the player can still jump
var _COYOTE_TIME_MS := 35

@onready var _sprite: PlayerSprite = $%AnimatedSprite2D
@onready var _jump_audio: AudioStreamPlayer2D = $%JumpAudio
@onready var _land_audio: AudioStreamPlayer2D = $%LandAudio
@onready var _spell_audio: AudioStreamPlayer2D = $%SpellAudio
@onready var _spell_offset: Node2D = $%SpellOffset

var _interactable: Interactable
var _last_grounded_timestamp := 0.0
var _current_projectile: SpellProjectile

func _ready() -> void:
	super._ready()
	_sprite.set_player(self)

func _process_input() -> void:
	_process_jump_input()
	_process_move_input()
	_process_interact_input()
	_process_spell_input()

func _process_jump_input() -> void:
	if Input.is_action_just_pressed("jump"):
		_attempt_jump()

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

func _attempt_jump() -> void:
	if _can_jump():
		_jump()

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
	elif direction > 0.0:
		_attempt_drop_through()

func _process_spell_input() -> void:
	if Input.is_action_just_pressed("spell"):
		_attempt_spell()

func _apply_move_input(direction, speed) -> void:
	super._apply_move_input(direction, speed)
	_sprite.flip_h = _is_facing_left

func is_running() -> bool:
	return Input.is_action_pressed("run")

func set_interactable(interactable: Interactable) -> void:
	_interactable = interactable

func _attempt_interact() -> void:
	if not _interactable:
		return
	_interactable.interact()

func _attempt_drop_through() -> void:
	if _is_on_drop_through_platform():
		position.y += 1

func _is_on_drop_through_platform() -> bool:
	var found_drop_through_platform := false
	for tile_collision in _last_tile_collisions:
		var is_collision_below_player := tile_collision.collision_point.y > global_position.y
		if not is_collision_below_player:
			continue
		if tile_collision.tile_data.is_collision_polygon_one_way(0, 0):
			# Bit of a hack but this works for now, as the only one-way collisions we have are
			# drop-through platforms
			found_drop_through_platform = true
		else:
			return false
	return found_drop_through_platform

func _attempt_spell() -> void:
	if is_instance_valid(_current_projectile):
		# Only 1 spell at a time!
		return
	# Reset our y-speed if falling
	velocity.y = min(velocity.y, 0)
	_current_projectile = _create_spell_projectile()
	get_tree().root.add_child(_current_projectile)
	_spell_audio.play()
	spell_cast.emit(_current_projectile)

func _create_spell_projectile() -> SpellProjectile:
	var proj := SpellProjectileScene.instantiate()
	proj.global_position = _find_spell_position()
	proj.velocity = Vector2(get_dir_multiplier() * _SPELL_SPEED, 0.0)
	return proj

func _find_spell_position() -> Vector2:
	var offset := _spell_offset.position * _spell_offset.global_scale
	if _is_facing_left:
		offset.x = -offset.x
	return global_position + offset
