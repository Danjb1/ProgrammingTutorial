extends CanvasLayer

@onready var _anim_player: AnimationPlayer = $%AnimationPlayer

func _process(_delta: float):
	if Input.is_action_just_pressed("jump"):
		_close_popup()

func _close_popup() -> void:
	if _anim_player.is_playing():
		return
	_anim_player.play_backwards("in")
	_anim_player.animation_finished.connect(_close_anim_finished)

func _close_anim_finished(_anim_name: StringName) -> void:
	get_tree().paused = false
	queue_free()
