class_name Orb
extends StaticBody2D

signal smashed

@onready var _smash_audio: AudioStreamPlayer2D = $%SmashAudio

func _hit_by_projectile(_projectile: SpellProjectile):
	smashed.emit()
	_smash_audio.play()
	queue_free()
