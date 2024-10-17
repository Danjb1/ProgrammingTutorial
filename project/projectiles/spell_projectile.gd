class_name SpellProjectile
extends CharacterBody2D

const HitEffectScene := preload("res://effects/spell_hit.tscn")

@onready var _spell_hit_audio: DetachableSound = $%HitAudio

func _physics_process(delta: float) -> void:
	var collision := move_and_collide(velocity * delta)
	if collision:
		_destroy_projectile(collision)

func _destroy_projectile(collision: KinematicCollision2D) -> void:
	_spell_hit_audio.play()
	_spell_hit_audio.detach()
	# At this point our parent is the level root
	var effect := HitEffectScene.instantiate()
	effect.global_position = collision.get_position()
	get_parent().add_child(effect)
	queue_free()
