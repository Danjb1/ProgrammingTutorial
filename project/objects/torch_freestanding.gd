extends Node

@export var is_lit := false
@export var is_lit_by_player := true

@onready var particles: GPUParticles2D = $%GPUParticles2D
@onready var area: Area2D = $%Area2D
@onready var audio_player: AudioStreamPlayer2D = $%AudioStreamPlayer2D

func _ready() -> void:
	if is_lit:
		particles.emitting = true
	elif is_lit_by_player:
		area.body_entered.connect(_on_body_entered)
		set_physics_process(true)

func _on_body_entered(body: Node2D):
	var player := body as PlayerCharacter
	if not player:
		return
	_light()

func _light():
	particles.emitting = true
	set_physics_process(false)
	audio_player.play()
