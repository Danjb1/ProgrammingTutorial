class_name PlayerSprite
extends AnimatedSprite2D

## Minimum lateral speed for the walk animation to play
const _MIN_MOVE_SPEED = 0.01

const _FOOTSTEP_FRAMES = [0, 2]

@onready var _footstep_sound: AudioStreamPlayer2D = $%FootstepAudio

var _player: PlayerCharacter

var _has_anim_override := false
var _anim_queue: Array[StringName]

func _on_ready() -> void:
	set_process(false)

func set_player(player: PlayerCharacter):
	_player = player
	_player.character_jumped.connect(_on_player_jumped)
	_player.character_landed.connect(_on_player_landed)
	_player.spell_cast.connect(_on_spell_cast)
	animation_finished.connect(_on_animation_finished)
	frame_changed.connect(_on_anim_frame_changed)
	set_process(true)

func _process(_delta: float) -> void:
	if _has_anim_override:
		# Wait for the current animation to finish
		return
	if _player.is_on_floor():
		_play_grounded_anim()
	else:
		_play_aerial_anim()

func _enqueue(anim: StringName) -> void:
	if is_playing():
		_anim_queue.push_back(anim)
	else:
		play(anim)

func _on_player_jumped(_character: CustomCharacter) -> void:
	_anim_queue.clear()
	play("jump_take_off")
	_enqueue("jump_loop")

func _on_player_landed(_character: CustomCharacter) -> void:
	_anim_queue.clear()
	play("land")
	_has_anim_override = true

func _play_grounded_anim() -> void:
	_anim_queue.clear()
	if abs(_player.velocity.x) < _MIN_MOVE_SPEED:
		play("idle")
	elif _player.is_running():
		play("run")
	else:
		play("walk")

func _play_aerial_anim() -> void:
	if _player.velocity.y > 0.0:
		_anim_queue.clear()
		play("fall")

func _on_animation_finished() -> void:
	_has_anim_override = false
	var next_anim = _anim_queue.pop_front()
	if next_anim:
		play(next_anim)

func _on_anim_frame_changed() -> void:
	if animation == "walk" or animation == "run":
		if frame in _FOOTSTEP_FRAMES:
			_footstep_sound.play()

func _on_spell_cast(_spell: SpellProjectile) -> void:
	_anim_queue.clear()
	play("spell")
	_has_anim_override = true
