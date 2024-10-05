class_name CustomCharacter
extends CharacterBody2D
## Base character class.

## Helper class used to store parameters required for a jump.
class JumpParams:
	var gravity_scale := 0.0
	var jump_speed := 0.0

## Signal emitted when the character jumps.
signal character_jumped(character: CustomCharacter)

## Signal emitted when the character lands.
signal character_landed(character: CustomCharacter)

const _PHYSICS_STARTUP_DELAY = 2
const _SPAWN_FLOOR_TEST_DISTANCE = 5.0

################################################################################
@export_category("Physics")
################################################################################

## Backwards speed applied when no move input is being applied
@export var deceleration := 300.0

################################################################################
@export_category("Jump")
################################################################################

## Apex height when jumping
@export var jump_height := 135.0

## Time to reach apex when jumping
@export var jump_time := 0.5

################################################################################

var _was_grounded := false
var _gravity_scale := 1.0
var _facing_left := false
var _last_teleport_timestamp := 0
var _jump_params: JumpParams

func _ready() -> void:
	call_deferred("_deferred_ready")

func _deferred_ready() -> void:
	# Wait a while before enabling physics, to allow TileMap initialization.
	# See: https://github.com/godotengine/godot/issues/67679
	# We do this in a deferred callback so as not to stall the `ready` function.
	set_physics_process(false)
	for i in _PHYSICS_STARTUP_DELAY:
		await get_tree().physics_frame
	set_physics_process(true)
	_post_spawn_physics()

func _post_spawn_physics():
	_jump_params = _calc_jump_params(jump_height, jump_time)
	_gravity_scale = _jump_params.gravity_scale
	# If we are spawning on a floor then we should snap to it, to prevent any
	# extraneous "landed" events being fired later.
	var floor_test_vector := Vector2.DOWN * _SPAWN_FLOOR_TEST_DISTANCE
	var collision := move_and_collide(floor_test_vector, true, 0.08, true)
	if collision:
		# We are on a floor!
		# It is necessary to call `move_and_slide` at least once in order for
		# `is_on_floor` to return the correct result.
		velocity = floor_test_vector
		move_and_slide()

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_process_input()
	_move()

## Applies gravity to our current velocity.
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += _get_scaled_gravity() * delta

## Override this to set the current move input before movement is attempted.
func _process_input() -> void:
	pass

## Applies the given move input to our current velocity.
func _apply_move_input(direction: float, speed: float) -> void:
	if direction:
		velocity.x = direction * speed
		_facing_left = direction < 0.0
	else:
		_decelerate()

## Applies deceleration to lateral velocity
func _decelerate() -> void:
	velocity.x = move_toward(velocity.x, 0, deceleration)

## Moves according to our current velocity.
func _move() -> void:
	_was_grounded = is_on_floor()
	var collided := move_and_slide()
	if collided:
		var collision = get_last_slide_collision()
		_process_collision(collision)

func _process_collision(collision: KinematicCollision2D) -> void:
	var tilemap := collision.get_collider() as TileMapLayer
	if tilemap:
		var tile_coords := tilemap.get_coords_for_body_rid(collision.get_collider_rid())
		var tile_data := tilemap.get_cell_tile_data(tile_coords)
		_process_tile_collision(collision, tile_coords, tile_data)
	if is_on_floor() and not _was_grounded:
		_landed()

func _process_tile_collision(
		_collision: KinematicCollision2D,
		_tile_coords: Vector2i,
		tile_data: TileData) -> bool:
	if tile_data.get_custom_data("instakill") as bool:
		_suppress_landing()
		kill()
		return true
	return false

func _suppress_landing() -> void:
	_was_grounded = true

func kill() -> void:
	# TODO: Death
	pass

## Calculates the jump parameters required to reach the given height in the given time.
func _calc_jump_params(p_jump_height: float, p_jump_time: float) -> JumpParams:
	var jump_params := JumpParams.new()

	# From equations of motion:
	#   s = ut + 0.5 * a * t^2
	# rearranged for a:
	#   a = 2 * s / t^2 - ut
	# where:
	#   s = apex height
	#   t = fall duration (same as time to reach apex)
	#   u = initial velocity (0)
	var desired_gravity = 2.0 * p_jump_height / pow(p_jump_time, 2.0)
	jump_params.gravity_scale = desired_gravity / get_gravity().length()
	
	# From equations of motion:
	#   v = u + at
	# where:
	#   u = 0 (initial speed)
	#   a = gravity
	#   t = time to reach apex
	jump_params.jump_speed = desired_gravity * p_jump_time

	return jump_params

## Launches the character upwards based on our jump parameters.
func _jump() -> void:
	_gravity_scale = _jump_params.gravity_scale
	velocity.y = -_jump_params.jump_speed
	character_jumped.emit(self)

## Called whenever the character becomes grounded.
func _landed() -> void:
	_gravity_scale = _jump_params.gravity_scale
	character_landed.emit(self)

## Teleports to the given position.
func teleport(pos: Vector2) -> void:
	_last_teleport_timestamp = Time.get_ticks_msec()
	global_position = pos

## Determines if this character has teleported within the given time window.
func has_recently_teleported(time_window: int) -> bool:
	if _last_teleport_timestamp == 0:
		return false
	var time_since_teleport = Time.get_ticks_msec() - _last_teleport_timestamp
	return time_since_teleport < time_window

## Gets the gravity vector, with the current gravity scale applied.
func _get_scaled_gravity() -> Vector2:
	return get_gravity() * _gravity_scale
