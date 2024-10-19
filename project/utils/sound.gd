class_name DetachableSound
extends AudioStreamPlayer2D

## Detaches this node from its parent and attaches it to the scene root instead.
## The sound will be automatically freed when it finishes playing.
func detach() -> void:
	var root := get_tree().root
	get_parent().remove_child(self)
	root.add_child(self)
	finished.connect(_on_finished_playing)

func _on_finished_playing() -> void:
	queue_free()
