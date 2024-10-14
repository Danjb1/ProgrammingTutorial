extends AnimatableBody2D

@export var target_position := Vector2(0.0, 128.0)
@export var movement_time := 1.6

var _tween: Tween

func _ready() -> void:
	tree_exiting.connect(_destroy)
	_start_movement()

func _destroy() -> void:
	_tween.stop()

func _start_movement() -> void:
	_tween = get_tree().create_tween()
	# First move to target_position
	_tween.tween_property(self, "position", target_position, movement_time) \
			.as_relative() \
			.set_ease(Tween.EASE_IN_OUT) \
			.set_trans(Tween.TRANS_SINE)
	# Then travel the same distance in reverse
	_tween.tween_property(self, "position", -target_position, movement_time) \
			.as_relative() \
			.set_ease(Tween.EASE_IN_OUT) \
			.set_trans(Tween.TRANS_SINE)
	# Loop forever
	_tween.set_loops(-1)
