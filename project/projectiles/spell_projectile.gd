class_name SpellProjectile
extends CharacterBody2D

func _physics_process(delta: float) -> void:
	var collision := move_and_collide(velocity * delta)
	if collision:
		_destroy_projectile()

func _destroy_projectile() -> void:
	queue_free()
