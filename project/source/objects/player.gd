extends CharacterBody2D

## Lateral movement speed when walking
const WALK_SPEED = 300.0

## Lateral movement speed when running
const RUN_SPEED = 400.0

## Backwards speed applied when no direction is held
const DECELERATION = 300.0

## Apex height when jumping
const JUMP_HEIGHT = 100.0

## Time to reach apex when jumping
const JUMP_TIME = 0.5

@onready var sprite: AnimatedSprite2D = $%AnimatedSprite2D

var _gravity_scale = 1.0

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_process_jump()
	_process_move_input()
	_move()

func _apply_gravity(delta):
	if not is_on_floor():
		velocity += _get_scaled_gravity() * delta

func _process_jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		_jump()

func _jump():
	# From equations of motion:
	#   s = ut + 0.5 * a * t^2
	# rearranged for a:
	#   a = 2 * s / t^2 - ut
	# where:
	#   s = apex height
	#   t = fall duration (same as time to reach apex)
	#   u = initial velocity (0)
	var desired_gravity = 2 * JUMP_HEIGHT / pow(JUMP_TIME, 2)
	
	# From equations of motion:
	#   v = u + at
	# where:
	#   u = 0 (initial speed)
	#   a = gravity
	#   t = time to reach apex
	var jump_speed = desired_gravity * JUMP_TIME

	_gravity_scale = desired_gravity / get_gravity().length()
	velocity.y = -jump_speed

func _process_move_input():
	var direction := Input.get_axis("left", "right")
	var speed = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION)

func _get_scaled_gravity():
	return get_gravity() * _gravity_scale

func _move():
	var prev_grounded = is_on_floor()
	move_and_slide()
	if not prev_grounded and is_on_floor():
		_landed()

func _landed():
	_gravity_scale = 1.0
