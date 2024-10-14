extends GPUParticles2D

func _ready() -> void:
	emitting = true
	finished.connect(_on_effect_finished)

func _on_effect_finished() -> void:
	queue_free()
