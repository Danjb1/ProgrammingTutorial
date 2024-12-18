class_name CustomCharacter
extends CharacterBody2D
## Base character class.

## Helper class used to store parameters required for a jump.
class JumpParams:
	var gravity_scale := 0.0
	var jump_speed := 0.0
	var jump_time := 0.0

## Helper class used to store data about a tile collision.
class TileCollision:
	var tilemap: TileMapLayer
	var collision: KinematicCollision2D
	var collision_point: Vector2
	var tile_coords: Vector2i
	var tile_data: TileData

	func _init(
			p_tilemap: TileMapLayer,
			p_collision: KinematicCollision2D,
			p_collision_point: Vector2,
			p_tile_coords: Vector2i,
			p_tile_data: TileData):
		tilemap = p_tilemap
		collision = p_collision
		collision_point = p_collision_point
		tile_coords = p_tile_coords
		tile_data = p_tile_data

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

## Apex height when jumping (pixels)
@export var jump_height := 135.0

## Time to reach apex when jumping (seconds)
@export var jump_time := 0.5

################################################################################

var _was_grounded := false
var _gravity_scale := 1.0
var _is_facing_left := false
var _last_teleport_timestamp := 0
var _jump_params: JumpParams
var _last_tile_collisions: Array[TileCollision]
var _collision_sampling_points: Array[Vector2]
var _collision_probe_depth := 0.1

func _ready() -> void:
	_collision_sampling_points = _find_collision_sampling_points()
	set_physics_process(false)
	if not Engine.is_editor_hint():
		call_deferred("_deferred_ready")

## Gets all points around the character - in local space - at which to check for tile collisions.
## This will need to be reworked for characters larger than 1 tile,
## or character with complex shapes.
func _find_collision_sampling_points() -> Array[Vector2]:
	var shape_owner := shape_owner_get_owner(0) as Node2D
	var shape_offset = shape_owner.position
	var shape := shape_owner_get_shape(0, 0)
	var bounds := shape.get_rect()
	return [
		shape_offset + bounds.position,                             # top-left
		shape_offset + bounds.position + Vector2(bounds.size.x, 0), # top-right
		shape_offset + bounds.position + bounds.size,               # bottom-right
		shape_offset + bounds.position + Vector2(0, bounds.size.y)  # bottom-left
	]

func _deferred_ready() -> void:
	# Wait a while before enabling physics, to allow TileMap initialization.
	# See: https://github.com/godotengine/godot/issues/67679
	# We do this in a deferred callback so as not to stall the `ready` function.
	for i in _PHYSICS_STARTUP_DELAY:
		await get_tree().physics_frame
	set_physics_process(true)
	_post_spawn_physics()

func _post_spawn_physics():
	_jump_params = _calc_jump_params_for_time(jump_height, jump_time)
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
	var prev_velocity := velocity
	_apply_gravity(delta)
	_process_input()
	_move(delta)
	if prev_velocity.y <= 0.0 and velocity.y > 0.0:
		_reached_jump_apex()

## Applies gravity to our current velocity.
func _apply_gravity(delta: float) -> void:
	velocity += _get_scaled_gravity() * delta

## Override this to set the current move input before movement is attempted.
func _process_input() -> void:
	pass

## Applies the given move input to our current velocity.
func _apply_move_input(direction: float, speed: float) -> void:
	if direction:
		velocity.x = direction * speed
		_is_facing_left = direction < 0.0
	else:
		_decelerate()

## Applies deceleration to lateral velocity.
func _decelerate() -> void:
	velocity.x = move_toward(velocity.x, 0, deceleration)

## Moves according to our current velocity.
func _move(_delta: float) -> void:
	_prepare_move()
	var collided := move_and_slide()
	if collided:
		var collision = get_last_slide_collision()
		_process_collision(collision)
	if is_on_floor() and not _was_grounded:
		_landed()

func _prepare_move() -> void:
	_was_grounded = is_on_floor()
	_last_tile_collisions.clear()

func _process_collision(collision: KinematicCollision2D) -> void:
	var tilemap := collision.get_collider() as TileMapLayer
	if tilemap:
		_process_collision_with_tilemap(collision, tilemap)

func _process_collision_with_tilemap(collision: KinematicCollision2D, tilemap: TileMapLayer):
	_last_tile_collisions = _find_tile_collisions(collision, tilemap)
	for tile_collision in _last_tile_collisions:
		_process_tile_collision(tile_collision)
	
func _find_tile_collisions(
		collision: KinematicCollision2D,
		tilemap: TileMapLayer) -> Array[TileCollision]:
	var tile_collisions: Array[TileCollision] = []
	for local_point in _collision_sampling_points:
		var global_point = to_global(local_point)
		var collision_point = global_point - collision.get_normal() * _collision_probe_depth
		var point_in_tilemap = tilemap.to_local(collision_point)
		var tile_coords := tilemap.local_to_map(point_in_tilemap)
		var tile_data := tilemap.get_cell_tile_data(tile_coords)
		if not tile_data:
			continue
		var tile_collision := TileCollision.new(
				tilemap, collision, collision_point, tile_coords, tile_data)
		tile_collisions.push_back(tile_collision)
	return tile_collisions

func _process_tile_collision(tile_collision: TileCollision) -> bool:
	if tile_collision.tile_data.get_custom_data("instakill") as bool:
		_suppress_landing()
		kill()
		return true
	return false

func _suppress_landing() -> void:
	_was_grounded = true

func kill() -> void:
	queue_free()

## Calculates the jump parameters required to reach the given height in the given time.
func _calc_jump_params_for_time(
		apex_height: float,
		p_jump_time: float) -> JumpParams:
	var jump_params := JumpParams.new()
	jump_params.jump_time = p_jump_time

	# From equations of motion:
	#   s = ut + 0.5 * a * t^2
	# rearranged for a:
	#   a = (2 * s - ut) / t^2
	# where:
	#   s = apex height
	#   t = fall duration (same as time to reach apex)
	#   u = initial speed (0)
	var desired_gravity = 2.0 * apex_height / pow(p_jump_time, 2.0)
	jump_params.gravity_scale = desired_gravity / get_gravity().length()

	# From equations of motion:
	#   v = u + at
	# where:
	#   u = initial speed (0)
	#   a = gravity
	#   t = time to reach apex (seconds)
	jump_params.jump_speed = -desired_gravity * p_jump_time

	return jump_params

## Calculates the jump parameters required to reach the given height with some initial speed.
## Initial speed should be negative for upwards motion.
func _calc_jump_params_for_speed(
		apex_height: float,
		initial_speed: float) -> JumpParams:
	var jump_params := JumpParams.new()
	jump_params.jump_speed = initial_speed

	# From equations of motion:
	#   (1) s = ut - at^2 / 2
	#   (2) v = u + at
	#
	#   t = -u/a
	#
	# Substituting into (1) and rearranging gives:
	#   a = -u^2 / 2s
	#
	# where:
	#   u = initial speed
	#   s = apex height
	var desired_gravity := pow(initial_speed, 2.0) / (2 * apex_height)
	jump_params.gravity_scale = desired_gravity / get_gravity().length()

	# From equations of motion:
	#   v = u + at
	#
	# Rearranged for t:
	#   t = (v - u) / a
	#
	# where:
	#   v = 0 (velocity at apex)
	#   u = initial speed
	#   a = gravity
	jump_params.jump_time = 0.0 if (desired_gravity == 0.0) else initial_speed / desired_gravity;

	return jump_params

## Launches the character upwards based on our jump parameters.
func _jump() -> void:
	_apply_jump_params(_jump_params)
	character_jumped.emit(self)

func _apply_jump_params(jump_params: JumpParams) -> void:
	_gravity_scale = jump_params.gravity_scale
	velocity.y = jump_params.jump_speed

func _reached_jump_apex() -> void:
	pass

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

func get_dir_multiplier() -> float:
	return -1.0 if _is_facing_left else 1.0
