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

## Time for which jump must be held to achieve a max-height jump
var _MAX_JUMP_HOLD_TIME_MS := 300

## Height of the player's jump if the jump key is released immediately
var _MIN_JUMP_HEIGHT := 68.0

@onready var _sprite: PlayerSprite = $%AnimatedSprite2D
@onready var _jump_audio: AudioStreamPlayer2D = $%JumpAudio
@onready var _land_audio: AudioStreamPlayer2D = $%LandAudio
@onready var _spell_audio: AudioStreamPlayer2D = $%SpellAudio
@onready var _spell_offset: Node2D = $%SpellOffset
@onready var _unlock_audio: AudioStreamPlayer2D = $%UnlockAudio

var _interactable: Interactable
var _last_grounded_timestamp := 0.0
var _jump_started_timestamp := 0.0
var _current_projectile: SpellProjectile
var _inventory := Inventory.new()
var _has_reached_jump_apex := false

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
		_jump_pressed()
	if Input.is_action_just_released("jump"):
		_jump_released()

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

func _jump_pressed() -> void:
	if _can_jump():
		_jump()

func _jump() -> void:
	super._jump()
	_has_reached_jump_apex = false
	_jump_audio.play()
	_jump_started_timestamp = Time.get_ticks_msec()

func _jump_released() -> void:
	if velocity.y >= 0.0:
		# Player is already descending
		return
	var jump_held_time := Time.get_ticks_msec() - _jump_started_timestamp
	if jump_held_time < _MAX_JUMP_HOLD_TIME_MS:
		_terminate_jump_early(jump_held_time)

func _terminate_jump_early(jump_held_time: float) -> void:
	# We need to adjust our jump arc so that we don't reach our max jump height.
	# This is needed to support variable-height jumps.
	var jump_progress := jump_held_time / _MAX_JUMP_HOLD_TIME_MS
	var current_height := _calc_jump_height(_jump_params, jump_held_time)
	# We know that desired height is somewhere between current height and max height.
	# We use jump_progress to determine how far into this range to aim for.
	var desired_height := remap(jump_progress, 0.0, 1.0, current_height, jump_height)
	desired_height = max(desired_height, _MIN_JUMP_HEIGHT)
	assert(current_height > 0.0 and current_height < desired_height)
	var remaining_height := desired_height - current_height
	#var remaining_time_ms := _MAX_JUMP_HOLD_TIME_MS - jump_held_time
	#var remaining_time := remaining_time_ms / 1000.0
	var new_jump_params := _calc_jump_params_for_speed(remaining_height, velocity.y)
	_apply_jump_params(new_jump_params)

## Calculates the height of a jump after the elapsed time.
func _calc_jump_height(jump_params: JumpParams, time_ms: float) -> float:
	# From equations of motion:
	#   s = ut + 0.5 * a * t^2
	# where:
	#   u = initial y-speed in px per second
	#   t = time in seconds
	#   a = acceleration (gravity) in px per second squared
	var time_s := time_ms / 1000.0
	var gravity := get_gravity().length() * jump_params.gravity_scale
	var displacement = jump_params.jump_speed * time_s + 0.5 * gravity * pow(time_s, 2)
	# We are interested in the height, which is negative displacement (since -y is up)
	return -displacement

func _reached_jump_apex() -> void:
	if _has_reached_jump_apex:
		return
	# Our variable jump height can mess with our gravity scale.
	# Once we've passed the apex, we need to reset it to the default.
	_gravity_scale = _jump_params.gravity_scale
	# If our gravity scale was set very high, we might now be falling way too fast.
	# Reset our vertical velocity for good measure.
	velocity.y = 0
	_has_reached_jump_apex = true

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

func _process_tile_collision(tile_collision: TileCollision) -> bool:
	var result := super._process_tile_collision(tile_collision)
	if result:
		return true
	if tile_collision.tile_data.get_custom_data("lock_id") as int:
		_try_unlock_door(tile_collision)
		return true
	return false

func _try_unlock_door(tile_collision: TileCollision) -> void:
	var lock_id := tile_collision.tile_data.get_custom_data("lock_id") as int
	if not _inventory.has_key(lock_id):
		return
	tile_collision.tilemap.set_cell(tile_collision.tile_coords, -1)
	_unlock_audio.play()
	_inventory.add_keys(lock_id, -1)

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

func get_inventory() -> Inventory:
	return _inventory
