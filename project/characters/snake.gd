@tool
extends CustomCharacter

@export var speed := 175.0

@export var is_invulnerable := false:
	set(value):
		is_invulnerable = value
		if not _sprite:
			return
		_refresh_sprite()

@export var should_start_facing_left := true:
	set(value):
		should_start_facing_left = value
		_set_initial_direction()

@onready var _sprite: AnimatedSprite2D = $%AnimatedSprite2D

var _direction: float
var _has_just_turned := false

func _ready() -> void:
	_refresh_sprite()
	super._ready()

func _refresh_sprite():
	_sprite.animation = "walk_invuln" if is_invulnerable else "walk"

func _deferred_ready() -> void:
	super._deferred_ready()
	_set_initial_direction()
	
func _set_initial_direction() -> void:
	_direction = -1.0 if should_start_facing_left else 1.0
	if _sprite:
		_sprite.flip_h = _is_facing_left

func _process_input() -> void:
	_apply_move_input(_direction, speed)

func _apply_move_input(direction, p_speed) -> void:
	super._apply_move_input(direction, p_speed)
	_sprite.flip_h = _is_facing_left

func _process_tile_collision(tile_collision: TileCollision) -> bool:
	var result := super._process_tile_collision(tile_collision)
	if result:
		return true
	var surface_angle: float = tile_collision.collision.get_angle()
	if surface_angle > floor_max_angle:
		_turn()
	return false

func _turn() -> void:
	if _has_just_turned:
		# Don't turn twice in one frame
		return
	_direction = -_direction
	_apply_move_input(_direction, speed)
	_has_just_turned = true

func _move(delta: float) -> void:
	_has_just_turned = false
	if _would_fall_after_moving(delta):
		_turn()
	super._move(delta)

func _would_fall_after_moving(delta: float) -> bool:
	# Simulate 1 frame of movement
	var motion := velocity * delta
	var transform_after_moving := global_transform.translated(motion)
	# Now see if we would fall from this position
	var falling_motion := Vector2.DOWN
	var found_floor = test_move(transform_after_moving, falling_motion)
	return not found_floor

func _hit_by_projectile(_projectile: SpellProjectile):
	if is_invulnerable:
		return
	kill()
