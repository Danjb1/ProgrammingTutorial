extends Node

@export var is_lit := false
@export var is_lit_by_player := true

@onready var _particles: GPUParticles2D = $%GPUParticles2D
@onready var _area: Area2D = $%Area2D
@onready var _ignite_audio: AudioStreamPlayer2D = $%IgniteAudio

func _ready() -> void:
	if is_lit:
		_particles.emitting = true
	elif is_lit_by_player:
		_set_collision_enabled(true)
		_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	var player := body as PlayerCharacter
	if not player:
		return
	_ignite()
	_area.body_entered.disconnect(_on_body_entered)

func _ignite():
	_particles.emitting = true
	# Can't disable collision from a physics callback
	call_deferred("_set_collision_enabled", false)
	_ignite_audio.play()

func _set_collision_enabled(is_enabled: bool):
	_area.process_mode = Node.PROCESS_MODE_INHERIT if is_enabled else Node.PROCESS_MODE_DISABLED
